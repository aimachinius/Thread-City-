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
                } : undefined,
                reposts: firebase_uid ? {
                    where: { user: { firebase_uid: firebase_uid } }
                } : undefined
            },
            orderBy: { created_at: 'desc' },
            take: 20,
        });

        // Lấy danh sách các bài reposts
        const reposts = await prisma.repost.findMany({
            where: { user_id: following ? { in: followedUserIds } : undefined },
            include: {
                user: { select: { id: true, username: true, avatar_url: true } }, // Người repost
                post: {
                    include: {
                        user: { select: { id: true, username: true, avatar_url: true } },
                        counts: true,
                        media: true,
                        hashtags: { include: { hashtag: true } },
                        likes: firebase_uid ? {
                            where: { user: { firebase_uid: firebase_uid } }
                        } : undefined,
                        reposts: firebase_uid ? {
                            where: { user: { firebase_uid: firebase_uid } }
                        } : undefined
                    }
                }
            },
            orderBy: { created_at: 'desc' },
            take: 20
        });

        const formattedPosts = posts.map((post: any) => ({
            ...post,
            isLiked: post.likes ? post.likes.length > 0 : false,
            isReposted: post.reposts ? post.reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined,
            isFollowing: followedUserIds.includes(post.user_id),
            feed_time: new Date(post.created_at).getTime()
        }));

        const formattedReposts = reposts.map((r: any) => ({
            ...r.post,
            isLiked: r.post.likes ? r.post.likes.length > 0 : false,
            isReposted: r.post.reposts ? r.post.reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined,
            isFollowing: followedUserIds.includes(r.post.user_id),
            repostedBy: r.user.username,
            feed_time: new Date(r.created_at).getTime() // Dùng thời gian repost để sort feed
        }));

        // Trộn và sắp xếp lại
        const mixedFeed = [...formattedPosts, ...formattedReposts]
            .sort((a, b) => b.feed_time - a.feed_time)
            .slice(0, 20);

        return res.json(mixedFeed);
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
                const pId = parseInt(parent_id.toString());
                await tx.postCount.upsert({
                    where: { post_id: pId },
                    update: { comment_count: { increment: 1 } },
                    create: { post_id: pId, comment_count: 1 }
                });

                const parentPost = await tx.post.findUnique({ where: { id: pId }, select: { user_id: true } });
                if (parentPost && parentPost.user_id !== user.id) {
                    await tx.notification.create({
                        data: {
                            user_id: parentPost.user_id,
                            actor_id: user.id,
                            post_id: post.id,
                            type: 'reply',
                            is_read: false
                        }
                    });
                }
            }

            // Lấy lại post đã có media và hashtags
            return await tx.post.findUnique({
                where: { id: post.id },
                include: {
                    user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
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
                user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
                counts: true,
                media: true,
                hashtags: { include: { hashtag: true } },
                likes: firebase_uid ? {
                    where: { user: { firebase_uid: firebase_uid } }
                } : undefined,
                reposts: firebase_uid ? {
                    where: { user: { firebase_uid: firebase_uid } }
                } : undefined,
                // Lấy tất cả phản hồi lồng của bình luận này
                replies: {
                    include: {
                        user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
                        counts: true,
                        media: true,
                        likes: firebase_uid ? {
                            where: { user: { firebase_uid: firebase_uid } }
                        } : undefined,
                        reposts: firebase_uid ? {
                            where: { user: { firebase_uid: firebase_uid } }
                        } : undefined
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
                    isReposted: nested.reposts ? nested.reposts.length > 0 : false,
                    likes: undefined,
                    reposts: undefined
                  }))
                : [];
            return {
                ...reply,
                isLiked: reply.likes ? reply.likes.length > 0 : false,
                isReposted: reply.reposts ? reply.reposts.length > 0 : false,
                likes: undefined,
                reposts: undefined,
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
        if (isNaN(postId) || postId <= 0) {
            return res.status(400).json({ message: 'Invalid post ID' });
        }

        const post = await prisma.post.findUnique({ where: { id: postId }, select: { id: true, user_id: true } });
        if (!post) {
            return res.status(404).json({ message: 'Post not found' });
        }

        const result = await prisma.$transaction(async (tx) => {
            const existingLike = await tx.like.findUnique({
                where: { user_id_post_id: { user_id: user.id, post_id: postId } }
            });

            if (existingLike) {
                try {
                    await tx.like.delete({
                        where: { id: existingLike.id }
                    });
                    await tx.postCount.upsert({
                        where: { post_id: postId },
                        update: { like_count: { decrement: 1 } },
                        create: { post_id: postId, like_count: 0 }
                    });
                } catch (delErr: any) {
                    if (delErr.code === 'P2025') return { liked: false };
                    throw delErr;
                }
                return { liked: false };
            } else {
                try {
                    await tx.like.create({
                        data: { user_id: user.id, post_id: postId }
                    });
                    await tx.postCount.upsert({
                        where: { post_id: postId },
                        update: { like_count: { increment: 1 } },
                        create: { post_id: postId, like_count: 1 }
                    });

                    if (post.user_id !== user.id) {
                        await tx.notification.create({
                            data: {
                                user_id: post.user_id,
                                actor_id: user.id,
                                post_id: postId,
                                type: 'like',
                                is_read: false
                            }
                        }).catch(() => {});
                    }
                } catch (createErr: any) {
                    if (createErr.code === 'P2002') {
                        return { liked: true };
                    }
                    throw createErr;
                }
                return { liked: true };
            }
        });

        return res.json(result);
    } catch (error: any) {
        if (error?.code === 'P2002') {
            return res.json({ liked: true });
        }
        console.error('Lỗi toggleLike:', error);
        return res.status(500).json({ message: "Internal server error", error: error?.message || String(error) });
    }
};

// Đăng lại / Hủy đăng lại (Toggle Repost)
export const toggleRepost = async (req: Request, res: Response) => {
    const id = req.params.id as string;
    const firebase_uid = req.body.firebase_uid as string;

    if (!firebase_uid) {
        return res.status(400).json({ message: 'Missing firebase_uid' });
    }

    try {
        const user = await prisma.user.findUnique({ where: { firebase_uid } });
        if (!user) return res.status(404).json({ message: 'User not found' });

        const postId = parseInt(id, 10);
        if (isNaN(postId) || postId <= 0) {
            return res.status(400).json({ message: 'Invalid post ID' });
        }

        // 🛡️ Không cho phép đăng lại bài viết của chính mình
        const post = await prisma.post.findUnique({ where: { id: postId }, select: { user_id: true } });
        if (!post) return res.status(404).json({ message: 'Post not found' });
        if (post.user_id === user.id) {
            return res.status(403).json({ message: 'Không thể đăng lại bài viết của chính bạn' });
        }

        const result = await prisma.$transaction(async (tx) => {
            const existingRepost = await tx.repost.findFirst({
                where: { user_id: user.id, post_id: postId }
            });

            if (existingRepost) {
                // Hủy đăng lại
                try {
                    await tx.repost.delete({
                        where: { id: existingRepost.id }
                    });
                    await tx.postCount.upsert({
                        where: { post_id: postId },
                        update: { repost_count: { decrement: 1 } },
                        create: { post_id: postId, repost_count: 0 }
                    });
                } catch (delErr: any) {
                    if (delErr.code === 'P2025') return { reposted: false };
                    throw delErr;
                }
                return { reposted: false };
            } else {
                // Đăng lại
                try {
                    await tx.repost.create({
                        data: { user_id: user.id, post_id: postId }
                    });
                    await tx.postCount.upsert({
                        where: { post_id: postId },
                        update: { repost_count: { increment: 1 } },
                        create: { post_id: postId, repost_count: 1 }
                    });

                    if (post && post.user_id !== user.id) {
                        await tx.notification.create({
                            data: {
                                user_id: post.user_id,
                                actor_id: user.id,
                                post_id: postId,
                                type: 'repost',
                                is_read: false
                            }
                        }).catch(() => {});
                    }
                } catch (createErr: any) {
                    if (createErr.code === 'P2002') {
                        return { reposted: true };
                    }
                    throw createErr;
                }
                return { reposted: true };
            }
        });

        return res.json(result);
    } catch (error: any) {
        if (error?.code === 'P2002') {
            return res.json({ reposted: true });
        }
        console.error('Lỗi toggleRepost:', error);
        return res.status(500).json({ message: "Internal server error", error: error?.message || String(error) });
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
                } : undefined,
                reposts: viewer_uid ? {
                    where: { user: { firebase_uid: viewer_uid } }
                } : undefined
            },
            orderBy: { created_at: 'desc' }
        });

        const formattedPosts = posts.map((post: any) => ({
            ...post,
            isLiked: post.likes ? post.likes.length > 0 : false,
            isReposted: post.reposts ? post.reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined
        }));

        return res.json(formattedPosts);
    } catch (error) {
        console.error('Lỗi getPostsByUserUid:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

// Lấy danh sách các bài đăng lại của user
export const getUserReposts = async (req: Request, res: Response) => {
    const firebase_uid = req.params.firebase_uid as string; // UID của người cần xem trang cá nhân
    const viewer_uid = req.query.viewer_uid as string | undefined;

    try {
        const isNumeric = /^\d+$/.test(firebase_uid);
        const user = await prisma.user.findUnique({
            where: isNumeric ? { id: parseInt(firebase_uid, 10) } : { firebase_uid }
        });

        if (!user) return res.status(404).json({ message: "User not found" });

        const reposts = await prisma.repost.findMany({
            where: { user_id: user.id },
            include: {
                user: { select: { id: true, username: true, avatar_url: true } },
                post: {
                    include: {
                        user: { select: { id: true, username: true, avatar_url: true } },
                        counts: true,
                        media: true,
                        hashtags: { include: { hashtag: true } },
                        likes: viewer_uid ? {
                            where: { user: { firebase_uid: viewer_uid } }
                        } : undefined,
                        reposts: viewer_uid ? {
                            where: { user: { firebase_uid: viewer_uid } }
                        } : undefined
                    }
                }
            },
            orderBy: { created_at: 'desc' }
        });

        const formattedReposts = reposts.map((r: any) => ({
            ...r.post,
            isLiked: r.post.likes ? r.post.likes.length > 0 : false,
            isReposted: r.post.reposts ? r.post.reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined,
            repostedBy: r.user.username,
            feed_time: new Date(r.created_at).getTime()
        }));

        return res.json(formattedReposts);
    } catch (error) {
        console.error('Lỗi getUserReposts:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

