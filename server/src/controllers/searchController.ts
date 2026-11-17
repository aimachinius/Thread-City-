import { Request, Response } from "express";
import { PrismaClient, Prisma } from "@prisma/client";
import {
  scoreUser,
  computeEngagementRaw,
  scorePost,
  scoreHashtag,
} from "../utils/searchRanking.js";

const prisma = new PrismaClient();

// In-memory cache 5 phút cho Trending Hashtags
interface TrendingCache {
  data: Array<{ id: number; tagName: string; postCount: number }>;
  expiresAt: number;
}
let trendingCache: TrendingCache | null = null;

/**
 * GET /api/search?q=&type=all|users|posts|hashtags&viewer_uid=
 */
export const searchAll = async (req: Request, res: Response) => {
  try {
    const rawQuery = String(req.query.q ?? "");
    const trimmedQuery = rawQuery.trim();

    // 1. Validation tầng 1: raw query trimmed >= 2 ký tự
    if (trimmedQuery.length < 2) {
      return res.status(400).json({ error: "Query phải có ít nhất 2 ký tự" });
    }

    // 2. Canonicalize query intent
    let canonicalQuery = trimmedQuery;
    let intent: "general" | "hashtag" | "user" = "general";

    if (trimmedQuery.startsWith("#")) {
      intent = "hashtag";
      canonicalQuery = trimmedQuery.slice(1).trim();
    } else if (trimmedQuery.startsWith("@")) {
      intent = "user";
      canonicalQuery = trimmedQuery.slice(1).trim();
    }

    // Validation tầng 2: canonical query sau khi strip prefix >= 2 ký tự
    if (canonicalQuery.length < 2) {
      return res.status(400).json({ error: "Query sau khi bỏ tiền tố (#/@) phải có ít nhất 2 ký tự" });
    }

    // Validation type explicit
    const allowedTypes = ["all", "users", "posts", "hashtags"];
    const type = String(req.query.type ?? "all");
    if (!allowedTypes.includes(type)) {
      return res.status(400).json({ error: "type không hợp lệ. Cho phép: all, users, posts, hashtags" });
    }

    const viewerUid = req.query.viewer_uid ? String(req.query.viewer_uid) : null;
    const reqNow = new Date();

    let usersResult: any[] = [];
    let postsResult: any[] = [];
    let hashtagsResult: any[] = [];

    // ── USERS RETRIEVAL & RANKING ────────────────────────────
    if (type === "all" || type === "users") {
      const candidateUsers = await prisma.$queryRaw<Array<any>>`
        SELECT u.id, u.firebase_uid, u.username, u.nickname, u.bio, u.avatar_url,
          (SELECT COUNT(*) FROM follows WHERE following_id = u.id) AS follower_count,
          (SELECT COUNT(*) FROM posts WHERE user_id = u.id AND parent_id IS NULL AND deleted_at IS NULL) AS post_count,
          ${
            viewerUid
              ? Prisma.sql`EXISTS (
                  SELECT 1 FROM follows f
                  JOIN users viewer ON viewer.id = f.follower_id
                  WHERE f.following_id = u.id AND viewer.firebase_uid = ${viewerUid}
                )`
              : Prisma.sql`FALSE`
          } AS is_following
        FROM users u
        WHERE LOWER(u.username) LIKE ${"%" + canonicalQuery + "%"}
           OR LOWER(u.nickname) LIKE ${"%" + canonicalQuery + "%"}
           OR LOWER(u.bio) LIKE ${"%" + canonicalQuery + "%"}
        ORDER BY 
          CASE 
            WHEN LOWER(u.username) = ${canonicalQuery.toLowerCase()} THEN 7
            WHEN LOWER(u.username) LIKE ${canonicalQuery.toLowerCase() + "%"} THEN 6
            WHEN LOWER(u.username) LIKE ${"%" + canonicalQuery.toLowerCase() + "%"} THEN 5
            WHEN LOWER(u.nickname) = ${canonicalQuery.toLowerCase()} THEN 4
            WHEN LOWER(u.nickname) LIKE ${canonicalQuery.toLowerCase() + "%"} THEN 3
            WHEN LOWER(u.nickname) LIKE ${"%" + canonicalQuery.toLowerCase() + "%"} THEN 2
            WHEN LOWER(u.bio) LIKE ${"%" + canonicalQuery.toLowerCase() + "%"} THEN 1
            ELSE 0
          END DESC,
          u.id DESC
        LIMIT 100
      `;

      const usersWithMetrics = candidateUsers.map((u) => ({
        id: Number(u.id),
        firebase_uid: u.firebase_uid,
        username: u.username,
        nickname: u.nickname,
        bio: u.bio,
        avatar_url: u.avatar_url,
        followerCount: Number(u.follower_count || 0),
        postCount: Number(u.post_count || 0),
        isFollowing: Boolean(u.is_following === 1 || u.is_following === true || u.is_following === "1"),
      }));

      const maxFollowers = Math.max(0, ...usersWithMetrics.map((u) => u.followerCount));
      const maxPosts = Math.max(0, ...usersWithMetrics.map((u) => u.postCount));

      usersResult = usersWithMetrics
        .map((u) => ({
          ...u,
          score: scoreUser(u, canonicalQuery, maxFollowers, maxPosts),
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 10)
        .map(({ score, ...cleanUser }) => cleanUser);
    }

    // ── POSTS RETRIEVAL & RANKING ────────────────────────────
    if (type === "all" || type === "posts") {
      let viewerId: number | undefined = undefined;
      let followedUserIds: number[] = [];

      if (viewerUid) {
        const viewer = await prisma.user.findUnique({
          where: { firebase_uid: viewerUid },
          select: { id: true },
        });
        if (viewer) {
          viewerId = viewer.id;
          const follows = await prisma.follow.findMany({
            where: { follower_id: viewer.id },
            select: { following_id: true },
          });
          followedUserIds = follows.map((f) => f.following_id);
        }
      }

      const candidatePosts = await prisma.post.findMany({
        where: {
          content: { contains: canonicalQuery },
          parent_id: null,
          deleted_at: null,
        },
        orderBy: [{ created_at: "desc" }, { id: "desc" }],
        take: 200,
        include: {
          user: { select: { id: true, username: true, nickname: true, avatar_url: true } },
          counts: true,
          media: true,
          hashtags: { include: { hashtag: true } },
          likes: viewerUid
            ? {
                where: { user: { firebase_uid: viewerUid } },
                select: { user_id: true },
                take: 1,
              }
            : false,
          reposts: viewerUid
            ? {
                where: { user: { firebase_uid: viewerUid } },
                select: { user_id: true },
                take: 1,
              }
            : false,
        },
      });

      const postsWithRaw = candidatePosts.map((p) => {
        const likeCount = p.counts?.like_count || 0;
        const commentCount = p.counts?.comment_count || 0;
        const repostCount = p.counts?.repost_count || 0;
        return {
          post: p,
          rawEngagement: computeEngagementRaw(likeCount, commentCount, repostCount),
        };
      });

      const maxRawEngagement = Math.max(0, ...postsWithRaw.map((p) => p.rawEngagement));

      postsResult = postsWithRaw
        .map((item) => ({
          item,
          score: scorePost(
            { content: item.post.content, createdAt: item.post.created_at ?? reqNow, rawEngagement: item.rawEngagement },
            canonicalQuery,
            maxRawEngagement,
            reqNow
          ),
        }))
        .sort((a, b) => {
          if (b.score !== a.score) return b.score - a.score;
          const bTime = b.item.post.created_at ? new Date(b.item.post.created_at).getTime() : 0;
          const aTime = a.item.post.created_at ? new Date(a.item.post.created_at).getTime() : 0;
          const timeDiff = bTime - aTime;
          if (timeDiff !== 0) return timeDiff;
          return b.item.post.id - a.item.post.id;
        })
        .slice(0, 20)
        .map(({ item }) => {
          const p = item.post;
          return {
            ...p,
            isLiked: p.likes ? p.likes.length > 0 : false,
            isReposted: p.reposts ? p.reposts.length > 0 : false,
            likes: undefined,
            reposts: undefined,
            isFollowing: followedUserIds.includes(p.user_id),
          };
        });
    }

    // ── HASHTAGS RETRIEVAL & RANKING ────────────────────────
    if (type === "all" || type === "hashtags") {
      const candidateHashtags = await prisma.$queryRaw<Array<{ id: number; tag_name: string }>>`
        SELECT id, tag_name
        FROM hashtags
        WHERE LOWER(tag_name) LIKE ${"%" + canonicalQuery.toLowerCase() + "%"}
        ORDER BY 
          CASE 
            WHEN LOWER(tag_name) = ${canonicalQuery.toLowerCase()} THEN 3
            WHEN LOWER(tag_name) LIKE ${canonicalQuery.toLowerCase() + "%"} THEN 2
            ELSE 1
          END DESC,
          id DESC
        LIMIT 50
      `;

      if (candidateHashtags.length > 0) {
        const tagIds = candidateHashtags.map((h) => h.id);
        const sevenDaysAgo = new Date(reqNow.getTime() - 7 * 24 * 60 * 60 * 1000);

        const stats = await prisma.$queryRaw<Array<{
          hashtagId: number;
          totalPostCount: bigint;
          recentPostCount: bigint;
          engagementSum: bigint;
        }>>`
          SELECT 
            ph.hashtag_id AS hashtagId,
            COUNT(DISTINCT CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL THEN p.id END) AS totalPostCount,
            COUNT(DISTINCT CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL AND p.created_at >= ${sevenDaysAgo} THEN p.id END) AS recentPostCount,
            COALESCE(SUM(
              CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL AND p.created_at >= ${sevenDaysAgo} 
              THEN (
                COALESCE(pc.like_count, 0) + 
                2 * COALESCE(pc.comment_count, 0) + 
                3 * COALESCE(pc.repost_count, 0)
              ) ELSE 0 END
            ), 0) AS engagementSum
          FROM post_hashtags ph
          JOIN posts p ON ph.post_id = p.id
          LEFT JOIN post_counts pc ON p.id = pc.post_id
          WHERE ph.hashtag_id IN (${Prisma.join(tagIds)})
            AND p.parent_id IS NULL 
            AND p.deleted_at IS NULL
          GROUP BY ph.hashtag_id
        `;

        const statsByTagId = new Map(stats.map((s) => [Number(s.hashtagId), s]));
        const tagsWithStats = candidateHashtags.map((tag) => {
          const stat = statsByTagId.get(tag.id);
          return {
            id: tag.id,
            tagName: tag.tag_name,
            totalPostCount: stat ? Number(stat.totalPostCount) : 0,
            recentPostCount: stat ? Number(stat.recentPostCount) : 0,
            engagementSum: stat ? Number(stat.engagementSum) : 0,
          };
        });

        const maxRecentPosts = Math.max(0, ...tagsWithStats.map((t) => t.recentPostCount));
        const maxEngagement = Math.max(0, ...tagsWithStats.map((t) => t.engagementSum));

        hashtagsResult = tagsWithStats
          .map((t) => ({
            id: t.id,
            tagName: t.tagName,
            postCount: t.totalPostCount,
            score: scoreHashtag(t, canonicalQuery, maxRecentPosts, maxEngagement),
          }))
          .sort((a, b) => b.score - a.score)
          .slice(0, 10)
          .map(({ score, ...cleanTag }) => cleanTag);
      }
    }

    return res.json({
      users: usersResult,
      posts: postsResult,
      hashtags: hashtagsResult,
    });
  } catch (error) {
    console.error("Lỗi searchAll:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

/**
 * GET /api/search/trending-hashtags
 */
export const getTrendingHashtags = async (req: Request, res: Response) => {
  try {
    const now = Date.now();
    if (trendingCache && trendingCache.expiresAt > now) {
      return res.json({ trending: trendingCache.data });
    }

    const reqNow = new Date();
    const sevenDaysAgo = new Date(reqNow.getTime() - 7 * 24 * 60 * 60 * 1000);

    const rawTrending = await prisma.$queryRaw<Array<{
      id: number;
      tagName: string;
      totalPostCount: bigint;
      recentPostCount: bigint;
      engagementSum: bigint;
    }>>`
      SELECT 
        h.id,
        h.tag_name AS tagName,
        COUNT(DISTINCT CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL THEN p.id END) AS totalPostCount,
        COUNT(DISTINCT CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL AND p.created_at >= ${sevenDaysAgo} THEN p.id END) AS recentPostCount,
        COALESCE(SUM(
          CASE WHEN p.parent_id IS NULL AND p.deleted_at IS NULL AND p.created_at >= ${sevenDaysAgo} 
          THEN (
            COALESCE(pc.like_count, 0) + 
            2 * COALESCE(pc.comment_count, 0) + 
            3 * COALESCE(pc.repost_count, 0)
          ) ELSE 0 END
        ), 0) AS engagementSum
      FROM hashtags h
      JOIN post_hashtags ph ON h.id = ph.hashtag_id
      JOIN posts p ON ph.post_id = p.id
      LEFT JOIN post_counts pc ON p.id = pc.post_id
      WHERE p.parent_id IS NULL 
        AND p.deleted_at IS NULL
      GROUP BY h.id, h.tag_name
      HAVING recentPostCount > 0
    `;

    const candidates = rawTrending.map((t) => ({
      id: Number(t.id),
      tagName: t.tagName,
      totalPostCount: Number(t.totalPostCount),
      recentPostCount: Number(t.recentPostCount),
      engagementSum: Number(t.engagementSum),
    }));

    const maxRecentPosts = Math.max(0, ...candidates.map((c) => c.recentPostCount));
    const maxEngagement = Math.max(0, ...candidates.map((c) => c.engagementSum));

    const ranked = candidates
      .map((c) => ({
        id: c.id,
        tagName: c.tagName,
        postCount: c.totalPostCount,
        score: scoreHashtag(c, "", maxRecentPosts, maxEngagement),
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);

    const result = ranked.map(({ id, tagName, postCount }) => ({ id, tagName, postCount }));

    trendingCache = {
      data: result,
      expiresAt: now + 5 * 60 * 1000,
    };

    return res.json({ trending: result });
  } catch (error) {
    console.error("Lỗi getTrendingHashtags:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
