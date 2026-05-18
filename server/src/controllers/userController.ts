import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

// Lấy thông tin Profile của User
export const getUserProfile = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string;
    const viewer_uid = req.query.viewer_uid as string | undefined;

    try {
        const isNumeric = /^\d+$/.test(firebase_uid);
        const user: any = await prisma.user.findUnique({
            where: isNumeric ? { id: parseInt(firebase_uid, 10) } : { firebase_uid },
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

        let is_following = false;
        if (viewer_uid) {
            const viewer = await prisma.user.findUnique({
                where: { firebase_uid: viewer_uid }
            });
            if (viewer) {
                const followRecord = await prisma.follow.findUnique({
                    where: {
                        follower_id_following_id: {
                            follower_id: viewer.id,
                            following_id: user.id
                        }
                    }
                });
                if (followRecord) {
                    is_following = true;
                }
            }
        }

        return res.json({
            user: {
                ...user,
                password_hash: undefined,
                stats: {
                    followers: user._count.following,
                    following: user._count.followers,
                    posts: user._count.posts
                },
                is_following
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

// Theo dõi người dùng
export const followUser = async (req: Request, res: Response) => {
    const { follower_uid, following_id } = req.body;

    if (!follower_uid || !following_id) {
        return res.status(400).json({ message: "follower_uid and following_id are required" });
    }

    try {
        const follower = await prisma.user.findUnique({
            where: { firebase_uid: follower_uid }
        });

        if (!follower) {
            return res.status(404).json({ message: "Follower user not found" });
        }

        const targetId = parseInt(following_id, 10);

        // Không cho tự follow chính mình
        if (follower.id === targetId) {
            return res.status(400).json({ message: "Cannot follow yourself" });
        }

        const existingFollow = await prisma.follow.findUnique({
            where: {
                follower_id_following_id: {
                    follower_id: follower.id,
                    following_id: targetId
                }
            }
        });

        if (existingFollow) {
            return res.status(200).json({ message: "Already following this user" });
        }

        await prisma.follow.create({
            data: {
                follower_id: follower.id,
                following_id: targetId
            }
        });

        // Tạo thông báo follow
        await prisma.notification.create({
            data: {
                user_id: targetId,
                actor_id: follower.id,
                type: "follow",
                is_read: false
            }
        });

        return res.json({ message: "Followed successfully" });
    } catch (error) {
        console.error("Lỗi followUser:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Bỏ theo dõi người dùng
export const unfollowUser = async (req: Request, res: Response) => {
    const { follower_uid, following_id } = req.body;

    if (!follower_uid || !following_id) {
        return res.status(400).json({ message: "follower_uid and following_id are required" });
    }

    try {
        const follower = await prisma.user.findUnique({
            where: { firebase_uid: follower_uid }
        });

        if (!follower) {
            return res.status(404).json({ message: "Follower user not found" });
        }

        const targetId = parseInt(following_id, 10);

        await prisma.follow.deleteMany({
            where: {
                follower_id: follower.id,
                following_id: targetId
            }
        });

        return res.json({ message: "Unfollowed successfully" });
    } catch (error) {
        console.error("Lỗi unfollowUser:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Lấy danh sách Followers (người theo dõi) của user
export const getUserFollowers = async (req: Request, res: Response) => {
    const userIdStr = req.params.userId as string;
    try {
        const isNumeric = /^\d+$/.test(userIdStr);
        let targetId: number;
        if (isNumeric) {
            targetId = parseInt(userIdStr, 10);
        } else {
            const user = await prisma.user.findUnique({
                where: { firebase_uid: userIdStr }
            });
            if (!user) return res.status(404).json({ message: "User not found" });
            targetId = user.id;
        }

        const follows = await prisma.follow.findMany({
            where: { following_id: targetId },
            include: {
                follower: {
                    select: {
                        id: true,
                        username: true,
                        avatar_url: true,
                        bio: true,
                        firebase_uid: true
                    }
                }
            }
        });

        const users = follows.map(f => f.follower);
        return res.json({ users });
    } catch (e: any) {
        return res.status(500).json({ error: e.message });
    }
};

// Lấy danh sách Following (đang theo dõi) của user
export const getUserFollowing = async (req: Request, res: Response) => {
    const userIdStr = req.params.userId as string;
    try {
        const isNumeric = /^\d+$/.test(userIdStr);
        let targetId: number;
        if (isNumeric) {
            targetId = parseInt(userIdStr, 10);
        } else {
            const user = await prisma.user.findUnique({
                where: { firebase_uid: userIdStr }
            });
            if (!user) return res.status(404).json({ message: "User not found" });
            targetId = user.id;
        }

        const follows = await prisma.follow.findMany({
            where: { follower_id: targetId },
            include: {
                following: {
                    select: {
                        id: true,
                        username: true,
                        avatar_url: true,
                        bio: true,
                        firebase_uid: true
                    }
                }
            }
        });

        const users = follows.map(f => f.following);
        return res.json({ users });
    } catch (e: any) {
        return res.status(500).json({ error: e.message });
    }
};
