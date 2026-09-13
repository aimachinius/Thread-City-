import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { getIO } from "../socket.js";
import { MessageAuthedRequest } from "../middlewares/messageAuth.js";
import { sendPushToUser } from "../services/pushService.js";

const prisma = new PrismaClient();

const getAuthUserId = (req: Request) =>
  (req as MessageAuthedRequest).messageAuth?.userId;

const formatConversationForUser = async (conversation: any, userId: number) => {
  const partner = conversation.user1_id === userId ? conversation.user2 : conversation.user1;
  let is_online = false;
  try {
    const io = getIO();
    const sockets = await io.in(`user_${partner.id}`).fetchSockets();
    is_online = sockets.length > 0;
  } catch (e) {
    // Ignore error if socket is not initialized
  }

  const unread_count = await prisma.message.count({
    where: {
      conversation_id: conversation.id,
      sender_id: { not: userId },
      status: { not: "READ" },
      is_deleted: false,
      hidden_by: {
        none: { user_id: userId },
      },
    },
  });

  return {
    id: conversation.id,
    status: conversation.status,
    last_activity_at: conversation.last_activity_at,
    is_muted: conversation.user1_id === userId
      ? conversation.is_muted_by_a
      : conversation.is_muted_by_b,
    partner: { ...partner, is_online },
    last_message: conversation.messages_dm_conversations_last_message_idTomessages,
    unread_count,
  };
};

const findConversationWithGuard = async (conversationId: number, userId: number) => {
  const conversation = await prisma.conversation.findUnique({
    where: { id: conversationId },
  });

  if (!conversation) return { error: "Không tìm thấy cuộc trò chuyện" as const };
  if (conversation.user1_id !== userId && conversation.user2_id !== userId) {
    return { error: "Bạn không có quyền truy cập cuộc trò chuyện này" as const };
  }
  return { conversation };
};

export const createOrOpenConversation = async (req: Request, res: Response) => {
  const requesterId = getAuthUserId(req);
  const receiverId = Number(req.body?.receiver_id);

  if (!requesterId) return res.status(401).json({ message: "Chưa được xác thực" });
  if (!receiverId || Number.isNaN(receiverId)) {
    return res.status(400).json({ message: "Thiếu thông tin người nhận (receiver_id)" });
  }
  if (requesterId === receiverId) {
    return res.status(400).json({ message: "Không thể tạo cuộc trò chuyện với chính mình" });
  }

  try {
    const receiver = await prisma.user.findUnique({
      where: { id: receiverId },
      select: { id: true },
    });
    if (!receiver) return res.status(404).json({ message: "Không tìm thấy người nhận" });

    // Removed check for senderFollowsReceiver

    const [follows1, follows2] = await Promise.all([
      prisma.follow.findUnique({
        where: {
          follower_id_following_id: {
            follower_id: requesterId,
            following_id: receiverId,
          },
        },
      }),
      prisma.follow.findUnique({
        where: {
          follower_id_following_id: {
            follower_id: receiverId,
            following_id: requesterId,
          },
        },
      }),
    ]);
    const isMutualFollow = Boolean(follows1 && follows2);

    const user1_id = Math.min(requesterId, receiverId);
    const user2_id = Math.max(requesterId, receiverId);

    let conversation = await prisma.conversation.findUnique({
      where: { user1_id_user2_id: { user1_id, user2_id } },
      include: {
        user1: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        user2: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        messages_dm_conversations_last_message_idTomessages: true,
      },
    });

    if (conversation) {
      if (isMutualFollow && conversation.status === "PENDING") {
        conversation = await prisma.conversation.update({
          where: { id: conversation.id },
          data: { status: "ACTIVE" },
          include: {
            user1: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
            user2: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
            messages_dm_conversations_last_message_idTomessages: true,
          },
        });
      }
    } else {
      const newConv = await prisma.conversation.create({
        data: {
          user1_id,
          user2_id,
          status: isMutualFollow ? "ACTIVE" : "PENDING",
          last_activity_at: new Date(),
        },
      });

      conversation = await prisma.conversation.findUnique({
        where: { id: newConv.id },
        include: {
          user1: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
          user2: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
          messages_dm_conversations_last_message_idTomessages: true,
        },
      });
    }

    const formatted = await formatConversationForUser(conversation, requesterId);
    return res.status(200).json(formatted);
  } catch (error) {
    console.error("Lỗi createOrOpenConversation:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const getConversations = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const conversations = await prisma.conversation.findMany({
      where: {
        status: "ACTIVE",
        OR: [{ user1_id: userId }, { user2_id: userId }],
        last_message_id: { not: null },
      },
      include: {
        user1: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        user2: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        messages_dm_conversations_last_message_idTomessages: true,
      },
      orderBy: { last_activity_at: "desc" },
    });

    const formattedConvs = await Promise.all(
      conversations.map((c) => formatConversationForUser(c, userId))
    );
    return res.status(200).json(formattedConvs);
  } catch (error) {
    console.error("Lỗi getConversations:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const getMessageRequests = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const conversations = await prisma.conversation.findMany({
      where: {
        status: "PENDING",
        OR: [{ user1_id: userId }, { user2_id: userId }],
        last_message_id: { not: null },
      },
      include: {
        user1: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        user2: { select: { id: true, username: true, nickname: true, avatar_url: true, is_verified: true } },
        messages_dm_conversations_last_message_idTomessages: true,
      },
      orderBy: { last_activity_at: "desc" },
    });

    const formattedRequests = await Promise.all(
      conversations.map((c) => formatConversationForUser(c, userId))
    );
    return res.status(200).json(formattedRequests);
  } catch (error) {
    console.error("Lỗi getMessageRequests:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const acceptRequest = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const conversationId = Number(req.params.conversationId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const guarded = await findConversationWithGuard(conversationId, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });
    if (guarded.conversation.status !== "PENDING") {
      return res.status(400).json({ message: "Cuộc trò chuyện không ở trạng thái chờ" });
    }
    const firstMessage = await prisma.message.findFirst({
      where: { conversation_id: conversationId },
      orderBy: { created_at: "asc" },
      select: { sender_id: true },
    });
    if (!firstMessage) {
      return res.status(400).json({ message: "Không có yêu cầu cần chấp nhận" });
    }
    if (firstMessage.sender_id === userId) {
      return res.status(403).json({ message: "Bạn không thể tự chấp nhận yêu cầu của chính mình" });
    }

    const updatedConv = await prisma.conversation.update({
      where: { id: conversationId },
      data: { status: "ACTIVE" },
    });

    getIO().to(`conversation_${conversationId}`).emit("request_accepted", { conversationId });
    getIO().to(`user_${firstMessage.sender_id}`).emit("request_accepted", { conversationId });
    await sendPushToUser({
      userId: firstMessage.sender_id,
      title: "Yêu cầu đã được chấp nhận",
      body: "Đối phương đã chấp nhận yêu cầu nhắn tin của bạn",
      data: {
        type: "request_accepted",
        conversationId: String(conversationId),
      },
    });
    return res.status(200).json(updatedConv);
  } catch (error) {
    console.error("Lỗi acceptRequest:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const declineRequest = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const conversationId = Number(req.params.conversationId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const guarded = await findConversationWithGuard(conversationId, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });
    if (guarded.conversation.status !== "PENDING") {
      return res.status(400).json({ message: "Cuộc trò chuyện không ở trạng thái chờ" });
    }
    const firstMessage = await prisma.message.findFirst({
      where: { conversation_id: conversationId },
      orderBy: { created_at: "asc" },
      select: { sender_id: true },
    });
    if (!firstMessage) {
      return res.status(400).json({ message: "Không có yêu cầu cần từ chối" });
    }
    if (firstMessage.sender_id === userId) {
      return res.status(403).json({ message: "Bạn không thể tự từ chối yêu cầu của chính mình" });
    }

    const updatedConv = await prisma.conversation.update({
      where: { id: conversationId },
      data: { status: "DECLINED" },
    });

    return res.status(200).json(updatedConv);
  } catch (error) {
    console.error("Lỗi declineRequest:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const blockConversation = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const conversationId = Number(req.params.conversationId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const guarded = await findConversationWithGuard(conversationId, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });

    const updatedConv = await prisma.conversation.update({
      where: { id: conversationId },
      data: { status: "BLOCKED" },
    });

    return res.status(200).json(updatedConv);
  } catch (error) {
    console.error("Lỗi blockConversation:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};
