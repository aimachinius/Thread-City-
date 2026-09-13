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
                actor: { select: { id: true, username: true, avatar_url: true } },
                post: { select: { id: true, content: true } }
            },
            orderBy: { created_at: "desc" }
        });

        return res.json(notifications);
    } catch (error) {
        console.error("Lỗi getNotifications:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};
