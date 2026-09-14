import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { getIO } from "../socket.js";
import { MessageAuthedRequest } from "../middlewares/messageAuth.js";
import { sendPushToUser } from "../services/pushService.js";

const prisma = new PrismaClient();

const getAuthUserId = (req: Request) =>
  (req as MessageAuthedRequest).messageAuth?.userId;

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

const findOrCreateConversationForSend = async (senderId: number, receiverId: number) => {
  const user1_id = Math.min(senderId, receiverId);
  const user2_id = Math.max(senderId, receiverId);

  let conversation = await prisma.conversation.findUnique({
    where: { user1_id_user2_id: { user1_id, user2_id } },
  });

  const [follows1, follows2] = await Promise.all([
    prisma.follow.findUnique({
      where: {
        follower_id_following_id: {
          follower_id: senderId,
          following_id: receiverId,
        },
      },
    }),
    prisma.follow.findUnique({
      where: {
        follower_id_following_id: {
          follower_id: receiverId,
          following_id: senderId,
        },
      },
    }),
  ]);
  const isMutualFollow = Boolean(follows1 && follows2);

  if (!conversation) {
    conversation = await prisma.conversation.create({
      data: {
        user1_id,
        user2_id,
        status: isMutualFollow ? "ACTIVE" : "PENDING",
        last_activity_at: new Date(),
      },
    });
  } else if (isMutualFollow && conversation.status === "PENDING") {
    conversation = await prisma.conversation.update({
      where: { id: conversation.id },
      data: { status: "ACTIVE" },
    });
  }

  return conversation;
};

const getConversationPartnerId = (
  conversation: { user1_id: number; user2_id: number },
  currentUserId: number
) => (conversation.user1_id === currentUserId ? conversation.user2_id : conversation.user1_id);

export const sendMessage = async (req: Request, res: Response) => {
  const senderId = getAuthUserId(req);
  const receiverId = Number(req.body?.receiver_id);
  const conversationIdFromPath = Number(req.params?.conversationId);
  const { type = "TEXT", content, media_url, shared_post_id } = req.body;

  if (!senderId || (Number.isNaN(receiverId) && Number.isNaN(conversationIdFromPath))) {
    return res.status(400).json({ message: "Thiếu thông tin bắt buộc" });
  }
  if (!Number.isNaN(receiverId) && senderId === receiverId) {
    return res.status(400).json({ message: "Không thể gửi tin nhắn cho chính mình" });
  }

  try {
    let conversation;
    if (!Number.isNaN(conversationIdFromPath)) {
      const guarded = await findConversationWithGuard(conversationIdFromPath, senderId);
      if ("error" in guarded) return res.status(403).json({ message: guarded.error });
      conversation = guarded.conversation;
    } else {
      // Removed check for senderFollowsReceiver
      conversation = await findOrCreateConversationForSend(senderId, receiverId);
    }
    // POST_SHARE messages bypass conversation restrictions (sharing a post is non-intrusive)
    const isPostShare = type === "POST_SHARE";

    if (!isPostShare && (conversation.status === "BLOCKED" || conversation.status === "DECLINED")) {
      return res.status(403).json({ message: "Không thể gửi tin nhắn đến cuộc trò chuyện này" });
    }

    let shouldUnlockConversation = false;
    let initiatorId: number | null = null;

    if (!isPostShare && conversation.status === "PENDING") {
      const firstMessage = await prisma.message.findFirst({
        where: { conversation_id: conversation.id },
        orderBy: { created_at: "asc" },
        select: { sender_id: true },
      });

      if (firstMessage) {
        initiatorId = firstMessage.sender_id;
        if (firstMessage.sender_id === senderId) {
          // The initiator already sent 1 message, cannot send more until recipient replies
          return res.status(403).json({
            message: "Bạn chỉ có thể gửi 1 tin nhắn khi đối phương chưa phản hồi",
          });
        } else {
          // The recipient is replying! Automatically unlock conversation to ACTIVE!
          shouldUnlockConversation = true;
        }
      }
    }

    const newMessage = await prisma.message.create({
      data: {
        conversation_id: conversation.id,
        sender_id: senderId,
        type,
        content: content || null,
        media_url: media_url || null,
        shared_post_id: shared_post_id ? Number(shared_post_id) : null,
        status: "DELIVERED",
      },
      include: {
        sender: { select: { id: true, username: true, avatar_url: true } },
        posts: {
          include: {
            user: { select: { id: true, username: true, avatar_url: true, nickname: true } },
            media: true,
            counts: true,
          },
        },
      },
    });

    const finalStatus = shouldUnlockConversation ? "ACTIVE" : conversation.status;

    await prisma.conversation.update({
      where: { id: conversation.id },
      data: {
        last_message_id: newMessage.id,
        last_activity_at: new Date(),
        status: finalStatus,
      },
    });

    const recipientId = senderId === conversation.user1_id ? conversation.user2_id : conversation.user1_id;

    // Emit to both users' personal rooms
    getIO().to(`user_${recipientId}`).emit("new_message", newMessage);
    getIO().to(`user_${senderId}`).emit("new_message", newMessage);

    getIO().to(`user_${recipientId}`).emit("message_status", {
      messageId: newMessage.id,
      conversationId: conversation.id,
      status: newMessage.status,
    });
    getIO().to(`user_${senderId}`).emit("message_status", {
      messageId: newMessage.id,
      conversationId: conversation.id,
      status: newMessage.status,
    });

    if (shouldUnlockConversation) {
      // Recipient replied: notify both participants that conversation is unlocked and accepted!
      getIO().to(`conversation_${conversation.id}`).emit("request_accepted", {
        conversationId: conversation.id,
      });
      if (initiatorId) {
        getIO().to(`user_${initiatorId}`).emit("request_accepted", {
          conversationId: conversation.id,
        });
      }
    } else if (conversation.status === "PENDING") {
      const receiverRoomUserId =
        senderId === conversation.user1_id ? conversation.user2_id : conversation.user1_id;
      getIO().to(`user_${receiverRoomUserId}`).emit("message_request", {
        conversationId: conversation.id,
        message: "Bạn có một yêu cầu nhắn tin mới",
      });
      await sendPushToUser({
        userId: receiverRoomUserId,
        title: "Yêu cầu nhắn tin mới",
        body: "Bạn có một yêu cầu nhắn tin mới",
        data: {
          type: "message_request",
          conversationId: String(conversation.id),
        },
      });
    } else {
      const receiverIdForActive = getConversationPartnerId(conversation, senderId);
      const receiverIsMuted = conversation.user1_id === receiverIdForActive
        ? conversation.is_muted_by_a
        : conversation.is_muted_by_b;
      if (!receiverIsMuted) {
        await sendPushToUser({
          userId: receiverIdForActive,
          title: "Tin nhắn mới",
          body: content || "Bạn có tin nhắn mới",
          data: {
            type: "new_message",
            conversationId: String(conversation.id),
          },
        });
      }
    }

    return res.status(200).json({ newMessage });
  } catch (error) {
    console.error("Lỗi sendMessage:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const getMessages = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const conversationId = Number(req.params.conversationId);
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 30;
  const skip = (page - 1) * limit;

  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const guarded = await findConversationWithGuard(conversationId, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });

    const messages = await prisma.message.findMany({
      where: {
        conversation_id: conversationId,
        hidden_by: {
          none: { user_id: userId },
        },
      },
      include: {
        sender: { select: { id: true, username: true, avatar_url: true } },
        posts: {
          include: {
            user: { select: { id: true, username: true, avatar_url: true, nickname: true } },
            media: true,
            counts: true,
          },
        },
      },
      orderBy: { created_at: "desc" },
      skip,
      take: limit,
    });

    return res.status(200).json(messages);
  } catch (error) {
    console.error("Lỗi getMessages:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const markMessagesAsRead = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const conversationId = Number(req.params.conversationId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const guarded = await findConversationWithGuard(conversationId, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });

    const updateResult = await prisma.message.updateMany({
      where: {
        conversation_id: conversationId,
        sender_id: { not: userId },
        status: { not: "READ" },
        is_deleted: false,
      },
      data: { status: "READ" },
    });

    if (updateResult.count > 0) {
      const partnerId = guarded.conversation.user1_id === userId
        ? guarded.conversation.user2_id
        : guarded.conversation.user1_id;

      getIO().to(`user_${partnerId}`).emit("messages_read", {
        conversationId,
        readerId: userId,
      });
      getIO().to(`user_${userId}`).emit("messages_read", {
        conversationId,
        readerId: userId,
      });
    }

    return res.status(200).json({ message: "Đã đánh dấu đã đọc", updatedCount: updateResult.count });
  } catch (error) {
    console.error("Lỗi markMessagesAsRead:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const deleteMessage = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const messageId = Number(req.params.messageId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) return res.status(404).json({ message: "Không tìm thấy tin nhắn" });

    const guarded = await findConversationWithGuard(message.conversation_id, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });

    if (message.sender_id !== userId) {
      return res.status(403).json({ message: "Không thể xóa tin nhắn của người khác" });
    }

    const updatedMsg = await prisma.message.update({
      where: { id: messageId },
      data: { is_deleted: true, deleted_at: new Date() },
    });

    getIO().to(`conversation_${message.conversation_id}`).emit("message_deleted", { messageId });
    return res.status(200).json(updatedMsg);
  } catch (error) {
    console.error("Lỗi deleteMessage:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

export const hideMessageForMe = async (req: Request, res: Response) => {
  const userId = getAuthUserId(req);
  const messageId = Number(req.params.messageId);
  if (!userId) return res.status(401).json({ message: "Chưa được xác thực" });

  try {
    const message = await prisma.message.findUnique({ where: { id: messageId } });
    if (!message) return res.status(404).json({ message: "Không tìm thấy tin nhắn" });

    const guarded = await findConversationWithGuard(message.conversation_id, userId);
    if ("error" in guarded) return res.status(403).json({ message: guarded.error });

    await prisma.message_hidden.upsert({
      where: { message_id_user_id: { message_id: messageId, user_id: userId } },
      create: { message_id: messageId, user_id: userId },
      update: {},
    });

    return res.status(200).json({ message: "Đã ẩn tin nhắn phía bạn" });
  } catch (error) {
    console.error("Lỗi hideMessageForMe:", error);
    return res.status(500).json({ message: "Lỗi hệ thống máy chủ" });
  }
};

