// ── Weights ──────────────────────────────────────────────
export const POST_SEARCH_WEIGHTS = {
  relevance: 0.5,
  engagement: 0.3,
  freshness: 0.2,
};

export const HASHTAG_SEARCH_WEIGHTS = {
  relevance: 0.4,
  recentUsage: 0.25,
  engagement: 0.35,
};

export const HASHTAG_TOP_POST_WEIGHTS = {
  engagement: 0.7,
  freshness: 0.3,
};

// Khoảng cách điểm số giữa các bậc Relevance Tier của User (bậc cao luôn thắng tuyệt đối bậc thấp)
export const USER_TIER_SCORE_GAP = 1000;

// Trọng số hòa giải trong cùng một Relevance Tier của User Search (tổng = 1.0)
export const USER_TIER_SECONDARY_WEIGHTS = {
  followers: 0.625, // 0.25 / (0.25 + 0.15)
  activity: 0.375,  // 0.15 / (0.25 + 0.15)
};

/**
 * 1. Phân loại bậc liên quan của User (7 cấp độ ưu tiên nghiêm ngặt)
 * Tier 7: Exact username
 * Tier 6: Username startsWith
 * Tier 5: Username contains
 * Tier 4: Exact nickname
 * Tier 3: Nickname startsWith
 * Tier 2: Nickname contains
 * Tier 1: Bio contains
 * Tier 0: Không khớp
 */
export function getUserRelevanceTier(
  user: { username: string; nickname?: string | null; bio?: string | null },
  canonicalQuery: string
): number {
  const q = canonicalQuery.toLowerCase().trim();
  const lowerU = user.username.toLowerCase();
  const lowerN = (user.nickname || '').toLowerCase();
  const lowerB = (user.bio || '').toLowerCase();

  if (lowerU === q) return 7;
  if (lowerU.startsWith(q)) return 6;
  if (lowerU.includes(q)) return 5;
  if (lowerN === q) return 4;
  if (lowerN.startsWith(q)) return 3;
  if (lowerN.includes(q)) return 2;
  if (lowerB.includes(q)) return 1;
  return 0;
}

/**
 * 2. Chấm điểm User (Lexicographic Score)
 * Điểm số = tier * 1000 + secondaryScore (followers + activity)
 */
export function scoreUser(
  user: { username: string; nickname?: string | null; bio?: string | null; followerCount: number; postCount: number },
  canonicalQuery: string,
  maxFollowers: number,
  maxPosts: number
): number {
  const tier = getUserRelevanceTier(user, canonicalQuery);
  if (tier === 0) return 0;

  const followerScore = maxFollowers > 0
    ? Math.log1p(Math.max(0, user.followerCount)) / Math.log1p(maxFollowers)
    : 0;

  const activityScore = maxPosts > 0
    ? Math.log1p(Math.max(0, user.postCount)) / Math.log1p(maxPosts)
    : 0;

  const secondaryScore =
    USER_TIER_SECONDARY_WEIGHTS.followers * followerScore +
    USER_TIER_SECONDARY_WEIGHTS.activity * activityScore;

  return tier * USER_TIER_SCORE_GAP + secondaryScore;
}

/**
 * 3. Tính điểm Raw Engagement từ like, comment, repost (không tính share)
 */
export function computeEngagementRaw(
  likeCount: number,
  commentCount: number,
  repostCount: number
): number {
  return (
    Math.log1p(Math.max(0, likeCount)) +
    2 * Math.log1p(Math.max(0, commentCount)) +
    3 * Math.log1p(Math.max(0, repostCount))
  );
}

/**
 * 4. Chuẩn hóa Engagement Score đảm bảo luôn thuộc [0, 1]
 */
export function computeEngagementScore(
  rawEngagement: number,
  maxRawEngagement: number
): number {
  if (maxRawEngagement <= 0) return 0;
  return Math.min(1.0, Math.max(0, rawEngagement) / maxRawEngagement);
}

/**
 * 5. Tính điểm tươi mới bài viết (bắt buộc nhận now: Date)
 */
export function computeFreshnessScore(createdAt: Date | string | null | undefined, now: Date): number {
  if (!createdAt) return 0.1;
  const createdTime = new Date(createdAt).getTime();
  if (isNaN(createdTime)) return 0.1;
  const diffHours = (now.getTime() - createdTime) / (1000 * 60 * 60);
  if (diffHours < 1) return 1.0;
  if (diffHours < 6) return 0.9;
  if (diffHours < 24) return 0.75;
  if (diffHours < 72) return 0.5;
  if (diffHours < 168) return 0.25;
  return 0.1;
}

/**
 * 6. Chấm điểm Post (Search results)
 */
export function scorePost(
  post: { content: string; createdAt?: Date | string | null; rawEngagement: number },
  canonicalQuery: string,
  maxRawEngagement: number,
  now: Date
): number {
  const q = canonicalQuery.toLowerCase().trim();
  const lowerContent = post.content.toLowerCase();

  let relevanceScore = 0.0;
  if (lowerContent.startsWith(q)) {
    relevanceScore = 1.0;
  } else if (lowerContent.includes(q)) {
    relevanceScore = 0.7;
  }

  const engagementScore = computeEngagementScore(post.rawEngagement, maxRawEngagement);
  const freshnessScore = computeFreshnessScore(post.createdAt, now);

  return (
    POST_SEARCH_WEIGHTS.relevance * relevanceScore +
    POST_SEARCH_WEIGHTS.engagement * engagementScore +
    POST_SEARCH_WEIGHTS.freshness * freshnessScore
  );
}

/**
 * 7. Chấm điểm Hashtag (Search & Trending)
 */
export function scoreHashtag(
  hashtag: { tagName: string; recentPostCount: number; engagementSum: number },
  canonicalQuery: string,
  maxRecentPosts: number,
  maxEngagement: number
): number {
  const q = canonicalQuery.toLowerCase().trim();
  const lowerTag = hashtag.tagName.toLowerCase();

  let relevanceScore = 1.0;
  if (q.length > 0) {
    if (lowerTag === q) relevanceScore = 1.0;
    else if (lowerTag.startsWith(q)) relevanceScore = 0.7;
    else if (lowerTag.includes(q)) relevanceScore = 0.4;
    else relevanceScore = 0.1;
  }

  const recentUsageScore = maxRecentPosts > 0
    ? Math.log1p(Math.max(0, hashtag.recentPostCount)) / Math.log1p(maxRecentPosts)
    : 0;

  const engagementScore = maxEngagement > 0
    ? Math.log1p(Math.max(0, hashtag.engagementSum)) / Math.log1p(maxEngagement)
    : 0;

  return (
    HASHTAG_SEARCH_WEIGHTS.relevance * relevanceScore +
    HASHTAG_SEARCH_WEIGHTS.recentUsage * recentUsageScore +
    HASHTAG_SEARCH_WEIGHTS.engagement * engagementScore
  );
}

/**
 * 8. Chấm điểm Post cho Top Feed của Hashtag
 */
export function scoreHashtagPost(
  post: { createdAt?: Date | string | null; rawEngagement: number },
  maxRawEngagement: number,
  now: Date
): number {
  const engagementScore = computeEngagementScore(post.rawEngagement, maxRawEngagement);
  const freshnessScore = computeFreshnessScore(post.createdAt, now);

  return (
    HASHTAG_TOP_POST_WEIGHTS.engagement * engagementScore +
    HASHTAG_TOP_POST_WEIGHTS.freshness * freshnessScore
  );
}
