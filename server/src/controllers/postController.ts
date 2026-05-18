import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { extractHashtags } from "../utils/hashtagUtils.js";

const prisma = new PrismaClient();

// Lấy danh sách bài viết (Feed)
export const getFeed = async (req: Request, res: Response) => {
    const firebase_uid = req.query.firebase_uid as string | undefined;
    const following = req.query.following === "true";

    try {
        let followedUserIds: number[] = [];
        let viewerId: number | undefined = undefined;

        if (firebase_uid) {
            const viewer = await prisma.user.findUnique({
                where: { firebase_uid }
            });
            if (viewer) {
                viewerId = viewer.id;
                const follows = await prisma.follow.findMany({
                    where: { follower_id: viewer.id },
                    select: { following_id: true }
                });
                followedUserIds = follows.map(f => f.following_id);
            }
        }

        if (following && firebase_uid) {
            // Nếu không follow ai, trả về danh sách trống ngay lập tức
            if (followedUserIds.length === 0) {
                return res.json([]);
            }
        }

        const posts = await prisma.post.findMany({
            where: { 
                parent_id: null,
                user_id: following ? { in: followedUserIds } : undefined
            },
            include: {
                user: { select: { id: true, username: true, avatar_url: true } },
                counts: true,
                media: true,
                hashtags: { include: { hashtag: true } },
                likes: firebase_uid ? {
                    where: { user: { firebase_uid: firebase_uid } }
                } : undefined
            },
            orderBy: { created_at: 'desc' },
            take: 20,
        });

        const formattedPosts = posts.map((post: any) => ({
            ...post,
            isLiked: post.likes ? post.likes.length > 0 : false,
            likes: undefined,
            isFollowing: followedUserIds.includes(post.user_id)
        }));

        return res.json(formattedPosts);
    } catch (error) {
        console.error('Lỗi getFeed:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Tạo bài viết mới hoặc Bình luận (Reply)
export const createPost = async (req: Request, res: Response) => {
    const { firebase_uid, content, parent_id, type, media } = req.body;

    if (!firebase_uid || !content) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    try {
        const user = await prisma.user.findUnique({ where: { firebase_uid: firebase_uid as string } });
        if (!user) return res.status(404).json({ message: 'User not found' });

        const newPost = await prisma.$transaction(async (tx) => {
            const post = await tx.post.create({
                data: {
                    user_id: user.id,
                    content: content,
                    parent_id: parent_id ? parseInt(parent_id.toString()) : null,
                    type: type || 'post',
                    counts: {
                        create: {}
                    }
                },
                include: {
                    user: {
                        select: { id: true, username: true, avatar_url: true }
                    },
                    counts: true,
                    media: true,
                    hashtags: {
                        include: { hashtag: true }
                    }
                }
            });

            // 1. Lưu Media nếu có
            if (media && Array.isArray(media) && media.length > 0) {
                const mediaData = media.map((m: any, index: number) => ({
                    post_id: post.id,
                    media_url: m.url,
                    media_type: m.type || 'image',
                    order_index: index,
                }));
                await tx.postMedia.createMany({ data: mediaData });
            }

            // 2. Phân tích và lưu Hashtag
            const tags = extractHashtags(content);
            for (const tag of tags) {
                // Upsert hashtag (tạo nếu chưa có)
                const hashtagRecord = await tx.hashtag.upsert({
                    where: { tag_name: tag },
                    update: {},
                    create: { tag_name: tag },
                });

                // Nối hashtag với post
                await tx.postHashtag.create({
                    data: {
                        post_id: post.id,
                        hashtag_id: hashtagRecord.id
                    }
                });
            }

            // 3. Tăng comment count của bài cha (nếu là reply)
            if (parent_id) {
                await tx.postCount.update({
                    where: { post_id: parseInt(parent_id.toString()) },
                    data: { comment_count: { increment: 1 } }
                });
            }

            // Lấy lại post đã có media và hashtags
            return await tx.post.findUnique({
                where: { id: post.id },
                include: {
                    user: { select: { id: true, username: true, avatar_url: true } },
                    counts: true,
                    media: true,
                    hashtags: { include: { hashtag: true } }
                }
            });
        });

        return res.status(201).json(newPost);
    } catch (error) {
        console.error('Lỗi createPost:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Lấy danh sách bình luận của một bài viết
export const getReplies = async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const firebase_uid = req.query.firebase_uid as string | undefined;

    try {
        const postId = parseInt(id);
        if (isNaN(postId)) {
            return res.status(400).json({ message: "Invalid post ID" });
        }

        // Tìm bài viết gốc để lấy ID của tác giả gốc (mainPost.user_id)
        const mainPost = await prisma.post.findUnique({
            where: { id: postId },
            select: { user_id: true }
        });

        if (!mainPost) {
            return res.status(404).json({ message: "Post not found" });
        }

        const replies = await prisma.post.findMany({
            where: { parent_id: postId },
            include: {
                user: { select: { id: true, username: true, avatar_url: true } },
                counts: true,
                media: true,
                hashtags: { include: { hashtag: true } },
                likes: firebase_uid ? {
                    where: { user: { firebase_uid: firebase_uid } }
                } : undefined,
                // Lấy tất cả phản hồi lồng của bình luận này
                replies: {
                    include: {
                        user: { select: { id: true, username: true, avatar_url: true } },
                        counts: true,
                        media: true,
                        likes: firebase_uid ? {
                            where: { user: { firebase_uid: firebase_uid } }
                        } : undefined,
                    },
                    orderBy: { created_at: 'asc' }
                }
            },
            orderBy: { created_at: 'asc' }
        });

        const formattedReplies = replies.map((reply: any) => {
            const formattedNested = reply.replies && reply.replies.length > 0 
                ? reply.replies.map((nested: any) => ({
                    ...nested,
                    isLiked: nested.likes ? nested.likes.length > 0 : false,
                    likes: undefined
                  }))
                : [];
            return {
                ...reply,
                isLiked: reply.likes ? reply.likes.length > 0 : false,
                likes: undefined,
                replies: formattedNested
            };
        });

        return res.json(formattedReplies);
    } catch (error) {
        console.error('Lỗi getReplies:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Thả tim / Bỏ thả tim bài viết (Toggle Like)
export const toggleLike = async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const firebase_uid = req.body.firebase_uid as string;

    if (!firebase_uid) {
        return res.status(400).json({ message: 'Missing firebase_uid' });
    }

    try {
        const user = await prisma.user.findUnique({ where: { firebase_uid } });
        if (!user) return res.status(404).json({ message: 'User not found' });

        const postId = parseInt(id, 10);
        if (isNaN(postId)) {
            return res.status(400).json({ message: 'Invalid post ID' });
        }

        const result = await prisma.$transaction(async (tx) => {
            const existingLike = await tx.like.findUnique({
                where: { user_id_post_id: { user_id: user.id, post_id: postId } }
            });

            if (existingLike) {
                await tx.like.delete({
                    where: { id: existingLike.id }
                });
                await tx.postCount.update({
                    where: { post_id: postId },
                    data: { like_count: { decrement: 1 } }
                });
                return { liked: false };
            } else {
                await tx.like.create({
                    data: { user_id: user.id, post_id: postId }
                });
                await tx.postCount.update({
                    where: { post_id: postId },
                    data: { like_count: { increment: 1 } }
                });
                return { liked: true };
            }
        });

        return res.json(result);
    } catch (error) {
        console.error('Lỗi toggleLike:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Lấy danh sách bài viết của một user cụ thể
export const getPostsByUserUid = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string;
    const viewer_uid = req.query.viewer_uid as string | undefined;

    try {
        const isNumeric = /^\d+$/.test(firebase_uid);
        const user = await prisma.user.findUnique({
            where: isNumeric ? { id: parseInt(firebase_uid, 10) } : { firebase_uid }
        });

        if (!user) return res.status(404).json({ message: "User not found" });

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

        return res.json(formattedPosts);
    } catch (error) {
        console.error('Lỗi getPostsByUserUid:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

