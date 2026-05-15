import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Lấy thông tin Profile và bài viết của User
export const getUserProfile = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string;
    const viewer_uid = req.query.viewer_uid as string | undefined;

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

        // Lấy danh sách bài viết của user này
        const posts = await prisma.post.findMany({
            where: { 
                user_id: user.id,
                parent_id: null
            },
            include: {
                user: { select: { id: true, username: true, avatar_url: true } },
                counts: true,
                media: true,
                hashtags: { include: { hashtag: true } },
                likes: viewer_uid ? {
                    where: { user: { firebase_uid: viewer_uid } }
                } : undefined
            },
            orderBy: { created_at: 'desc' }
        });

        const formattedPosts = posts.map((post: any) => ({
            ...post,
            isLiked: post.likes ? post.likes.length > 0 : false,
            likes: undefined
        }));

        return res.json({
            user: {
                ...user,
                password_hash: undefined,
                stats: user._count
            },
            posts: formattedPosts
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
