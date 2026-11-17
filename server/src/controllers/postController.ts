import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { extractHashtags } from "../utils/hashtagUtils.js";
import { computeEngagementRaw, scoreHashtagPost } from "../utils/searchRanking.js";
import { getIO } from "../socket.js";

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
                deleted_at: null,
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
            where: { 
                user_id: following ? { in: followedUserIds } : undefined,
                post: { deleted_at: null }
            },
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
    const callerUid = (req as any).user?.firebaseUid || req.body.firebase_uid;
    const { content, parent_id, type, media } = req.body;

    if (!callerUid || !content) {
        return res.status(400).json({ message: 'Missing required fields' });
    }

    try {
        const user = await prisma.user.findUnique({ where: { firebase_uid: callerUid as string } });
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

        if (parent_id) {
            const pId = parseInt(parent_id.toString(), 10);
            const parentPost = await prisma.post.findUnique({ where: { id: pId }, select: { user_id: true } });
            if (parentPost && parentPost.user_id !== user.id) {
                try {
                    getIO().to(`user_${parentPost.user_id}`).emit('new_notification', {
                        type: 'reply',
                        postId: pId,
                        actorId: user.id
                    });
                } catch (_) {}
            }
        }

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
            select: { user_id: true, deleted_at: true }
        });

        if (!mainPost || mainPost.deleted_at !== null) {
            return res.status(404).json({ message: "Post not found" });
        }

        const replies = await prisma.post.findMany({
            where: { parent_id: postId, deleted_at: null },
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
                    where: { deleted_at: null },
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
    const firebase_uid = (req as any).user?.firebaseUid || (req.body.firebase_uid as string);

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

        const post = await prisma.post.findUnique({ where: { id: postId }, select: { id: true, user_id: true, deleted_at: true } });
        if (!post || post.deleted_at !== null) {
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
                    await tx.notification.deleteMany({
                        where: {
                            user_id: post.user_id,
                            actor_id: user.id,
                            post_id: postId,
                            type: 'like'
                        }
                    }).catch(() => {});
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
                        await tx.notification.deleteMany({
                            where: {
                                user_id: post.user_id,
                                actor_id: user.id,
                                post_id: postId,
                                type: 'like'
                            }
                        }).catch(() => {});

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

        if (post.user_id !== user.id && result.liked) {
            try {
                getIO().to(`user_${post.user_id}`).emit('new_notification', {
                    type: 'like',
                    postId,
                    actorId: user.id
                });
            } catch (_) {}
        }

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
    const firebase_uid = (req as any).user?.firebaseUid || (req.body.firebase_uid as string);

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
        const post = await prisma.post.findUnique({ where: { id: postId }, select: { id: true, user_id: true, deleted_at: true } });
        if (!post || post.deleted_at !== null) return res.status(404).json({ message: 'Post not found' });
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
                    await tx.notification.deleteMany({
                        where: {
                            user_id: post.user_id,
                            actor_id: user.id,
                            post_id: postId,
                            type: 'repost'
                        }
                    }).catch(() => {});
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
                        await tx.notification.deleteMany({
                            where: {
                                user_id: post.user_id,
                                actor_id: user.id,
                                post_id: postId,
                                type: 'repost'
                            }
                        }).catch(() => {});

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

        if (post && post.user_id !== user.id && result.reposted) {
            try {
                getIO().to(`user_${post.user_id}`).emit('new_notification', {
                    type: 'repost',
                    postId,
                    actorId: user.id
                });
            } catch (_) {}
        }

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
                parent_id: null,
                deleted_at: null
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
            where: { 
                user_id: user.id,
                post: { deleted_at: null }
            },
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

// Lấy chi tiết một bài viết theo ID (cho Public URL & Post Detail Screen)
export const getPostById = async (req: Request, res: Response) => {
    const id = (Array.isArray(req.params.id) ? req.params.id[0] : req.params.id) as string | undefined;
    const viewer_uid = (req.query.viewer_uid || req.query.firebase_uid) as string | undefined;

    // 1. Input Validation: ID phải là số nguyên dương
    if (!id || !/^\d+$/.test(id)) {
        return res.status(400).json({ message: "Invalid post ID" });
    }

    const postId = parseInt(id, 10);
    if (isNaN(postId) || postId <= 0) {
        return res.status(400).json({ message: "Invalid post ID" });
    }

    try {
        // 2. Query Post
        const post = await prisma.post.findUnique({
            where: { id: postId },
            include: {
                user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
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
        });

        // 3. Check not found hoặc đã bị xóa
        if (!post || post.deleted_at !== null) {
            return res.status(404).json({ message: "Post not found" });
        }

        // 4. Xác định following state nếu có viewer
        let isFollowing = false;
        if (viewer_uid) {
            const viewer = await prisma.user.findUnique({
                where: { firebase_uid: viewer_uid },
                select: { id: true }
            });
            if (viewer && viewer.id !== post.user_id) {
                const follow = await prisma.follow.findFirst({
                    where: {
                        follower_id: viewer.id,
                        following_id: post.user_id
                    }
                });
                isFollowing = !!follow;
            }
        }

        // 5. Format response tương thích PostModel
        const formattedPost = {
            ...post,
            isLiked: (post as any).likes ? (post as any).likes.length > 0 : false,
            isReposted: (post as any).reposts ? (post as any).reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined,
            isFollowing
        };

        return res.json(formattedPost);
    } catch (error) {
        console.error('Lỗi getPostById:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

/**
 * GET /api/posts/hashtag/:tag?sort=top|latest&viewer_uid=
 */
export const getPostsByHashtag = async (req: Request, res: Response) => {
    try {
        const rawTag = String(req.params.tag ?? '').trim();
        const canonicalTag = rawTag.startsWith('#') ? rawTag.slice(1).toLowerCase().trim() : rawTag.toLowerCase().trim();

        if (!canonicalTag) {
            return res.status(400).json({ error: 'Hashtag không hợp lệ' });
        }

        const allowedSorts = ['latest', 'top'];
        const sort = String(req.query.sort ?? 'latest');
        if (!allowedSorts.includes(sort)) {
            return res.status(400).json({ error: 'sort không hợp lệ. Cho phép: latest, top' });
        }

        const viewerUid = req.query.viewer_uid ? String(req.query.viewer_uid) : null;
        const reqNow = new Date();

        let followedUserIds: number[] = [];
        if (viewerUid) {
            const viewer = await prisma.user.findUnique({
                where: { firebase_uid: viewerUid },
                select: { id: true }
            });
            if (viewer) {
                const follows = await prisma.follow.findMany({
                    where: { follower_id: viewer.id },
                    select: { following_id: true }
                });
                followedUserIds = follows.map(f => f.following_id);
            }
        }

        if (sort === 'latest') {
            const posts = await prisma.post.findMany({
                where: {
                    parent_id: null,
                    deleted_at: null,
                    hashtags: { some: { hashtag: { tag_name: canonicalTag } } }
                },
                orderBy: [{ created_at: 'desc' }, { id: 'desc' }],
                take: 30,
                include: {
                    user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
                    counts: true,
                    media: true,
                    hashtags: { include: { hashtag: true } },
                    likes: viewerUid ? {
                        where: { user: { firebase_uid: viewerUid } },
                        select: { user_id: true },
                        take: 1,
                    } : false,
                    reposts: viewerUid ? {
                        where: { user: { firebase_uid: viewerUid } },
                        select: { user_id: true },
                        take: 1,
                    } : false,
                }
            });

            const formatted = posts.map((p: any) => ({
                ...p,
                isLiked: p.likes ? p.likes.length > 0 : false,
                isReposted: p.reposts ? p.reposts.length > 0 : false,
                likes: undefined,
                reposts: undefined,
                isFollowing: followedUserIds.includes(p.user_id),
            }));

            return res.json({ posts: formatted });
        }

        // Chế độ Top: Candidate pool tối đa 500 root posts hợp lệ gần nhất
        const candidatePosts = await prisma.post.findMany({
            where: {
                parent_id: null,
                deleted_at: null,
                hashtags: { some: { hashtag: { tag_name: canonicalTag } } }
            },
            take: 500,
            orderBy: [{ created_at: 'desc' }, { id: 'desc' }],
            include: {
                user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
                counts: true,
                media: true,
                hashtags: { include: { hashtag: true } },
                likes: viewerUid ? {
                    where: { user: { firebase_uid: viewerUid } },
                    select: { user_id: true },
                    take: 1,
                } : false,
                reposts: viewerUid ? {
                    where: { user: { firebase_uid: viewerUid } },
                    select: { user_id: true },
                    take: 1,
                } : false,
            }
        });

        const withRaw = candidatePosts.map((p: any) => ({
            post: p,
            rawEngagement: computeEngagementRaw(
                p.counts?.like_count || 0,
                p.counts?.comment_count || 0,
                p.counts?.repost_count || 0,
            ),
        }));

        const maxRawEngagement = Math.max(0, ...withRaw.map(w => w.rawEngagement));

        // Tie-break 3 cấp: score DESC -> created_at DESC -> id DESC
        const ranked = withRaw.map(w => ({
            post: w.post,
            score: scoreHashtagPost({ createdAt: w.post.created_at, rawEngagement: w.rawEngagement }, maxRawEngagement, reqNow),
        })).sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            const bTime = b.post.created_at ? new Date(b.post.created_at).getTime() : 0;
            const aTime = a.post.created_at ? new Date(a.post.created_at).getTime() : 0;
            const timeDiff = bTime - aTime;
            if (timeDiff !== 0) return timeDiff;
            return b.post.id - a.post.id;
        }).slice(0, 30);

        const formatted = ranked.map(r => {
            const p = r.post;
            return {
                ...p,
                isLiked: p.likes ? p.likes.length > 0 : false,
                isReposted: p.reposts ? p.reposts.length > 0 : false,
                likes: undefined,
                reposts: undefined,
                isFollowing: followedUserIds.includes(p.user_id),
            };
        });

        return res.json({ posts: formatted });
    } catch (error) {
        console.error('Lỗi getPostsByHashtag:', error);
        return res.status(500).json({ message: "Internal server error" });
    }
};

/**
 * DELETE /api/posts/:id
 * Xóa mềm bài viết (Soft delete)
 */
export const deletePost = async (req: Request, res: Response) => {
    const id = (Array.isArray(req.params.id) ? req.params.id[0] : req.params.id) as string | undefined;
    const callerUid = (req as any).user?.firebaseUid ||
        (req.headers?.['x-firebase-uid'] as string) ||
        (req.body?.firebase_uid as string) ||
        (req.query?.firebase_uid as string);

    if (!callerUid) {
        return res.status(401).json({ message: "Unauthorized" });
    }

    if (!id || !/^\d+$/.test(id)) {
        return res.status(400).json({ message: "Invalid post ID" });
    }

    const postId = parseInt(id, 10);
    if (isNaN(postId) || postId <= 0) {
        return res.status(400).json({ message: "Invalid post ID" });
    }

    try {
        const user = await prisma.user.findUnique({
            where: { firebase_uid: callerUid },
            select: { id: true }
        });

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const post = await prisma.post.findUnique({
            where: { id: postId },
            select: { id: true, user_id: true, parent_id: true, deleted_at: true }
        });

        if (!post || post.deleted_at !== null) {
            return res.status(404).json({ message: "Post not found" });
        }

        // Kiểm tra quyền: Chỉ tác giả mới có quyền xóa bài viết của mình
        if (post.user_id !== user.id) {
            return res.status(403).json({ message: "Bạn không có quyền xóa bài viết này" });
        }

        await prisma.$transaction(async (tx) => {
            const now = new Date();

            // 1. Soft-delete bài viết mục tiêu
            await tx.post.update({
                where: { id: postId },
                data: { deleted_at: now }
            });

            // 2. Soft-delete các bình luận trực tiếp của bài viết này nếu có
            await tx.post.updateMany({
                where: { parent_id: postId, deleted_at: null },
                data: { deleted_at: now }
            });

            // 3. Nếu là bình luận (có parent_id), giảm comment_count của bài cha
            if (post.parent_id) {
                await tx.postCount.updateMany({
                    where: { post_id: post.parent_id, comment_count: { gt: 0 } },
                    data: { comment_count: { decrement: 1 } }
                });
            }

            // 4. Dọn dẹp notification liên quan đến bài viết này
            await tx.notification.deleteMany({
                where: { post_id: postId }
            });
        });

        return res.json({ success: true, message: "Đã xóa bài viết thành công" });
    } catch (error) {
        console.error("Lỗi deletePost:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
};


