import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export const getNotifications = async (req: Request, res: Response) => {
    const firebase_uid = req.query.firebase_uid as string;
    if (!firebase_uid) return res.status(400).json({ message: "Missing firebase_uid" });

    try {
        const user = await prisma.user.findUnique({ where: { firebase_uid } });
        if (!user) return res.status(404).json({ message: "User not found" });

        const notifications = await prisma.notification.findMany({
            where: { user_id: user.id },
            include: {
                actor: { select: { id: true, username: true, avatar_url: true, nickname: true, firebase_uid: true } },
                post: { select: { id: true, content: true, parent_id: true, deleted_at: true } }
            },
            orderBy: { created_at: "desc" }
        });

        const formattedNotifications = notifications.map((n: any) => ({
            ...n,
            post: n.post && n.post.deleted_at === null ? { id: n.post.id, content: n.post.content, parent_id: n.post.parent_id } : null
        }));

        return res.json(formattedNotifications);
    } catch (error) {
        console.error("Lỗi getNotifications:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

export const markNotificationAsRead = async (req: Request, res: Response) => {
    const id = parseInt(req.params.id as string, 10);
    if (isNaN(id)) return res.status(400).json({ message: "Invalid notification ID" });

    try {
        const updated = await prisma.notification.update({
            where: { id },
            data: { is_read: true }
        });
        return res.json({ success: true, notification: updated });
    } catch (error) {
        console.error("Lỗi markNotificationAsRead:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};
