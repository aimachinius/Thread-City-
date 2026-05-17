import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Lấy thông tin Profile của User
export const getUserProfile = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string;

    try {
        const user: any = await prisma.user.findUnique({
            where: { firebase_uid },
            include: {
                _count: {
                    select: {
                        followers: true,
                        following: true,
                        posts: true
                    }
                }
            }
        });

        if (!user) return res.status(404).json({ message: "User not found" });

        return res.json({
            user: {
                ...user,
                password_hash: undefined,
                stats: user._count
            }
        });
    } catch (error) {
        console.error('Lỗi getUserProfile:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Cập nhật thông tin Profile
export const updateProfile = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string;
    const { bio, avatar_url, username } = req.body;

    try {
        const user = await prisma.user.update({
            where: { firebase_uid },
            data: {
                bio: bio !== undefined ? bio : undefined,
                avatar_url: avatar_url !== undefined ? avatar_url : undefined,
                username: username !== undefined ? username : undefined,
            }
        });

        return res.json({
            message: "Profile updated successfully",
            user: {
                ...user,
                password_hash: undefined
            }
        });
    } catch (error) {
        console.error('Lỗi updateProfile:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};
