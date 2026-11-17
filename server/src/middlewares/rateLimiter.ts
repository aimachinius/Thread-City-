import { rateLimit } from 'express-rate-limit';

/**
 * 1. Global Rate Limiter: Bảo vệ toàn bộ server khỏi tấn công DoS/Flood
 * - Giới hạn: 300 requests / 15 phút trên mỗi địa chỉ IP
 */
export const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 phút
    limit: 300,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: {
        error: 'Bạn đã gửi quá nhiều yêu cầu đến máy chủ. Vui lòng thử lại sau 15 phút.',
    },
});

/**
 * 2. Search Rate Limiter: Bảo vệ các truy vấn Search nặng tài nguyên (LIKE, $queryRaw, Ranking)
 * - Giới hạn: 30 requests / 1 phút trên mỗi địa chỉ IP
 */
export const searchLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 phút
    limit: 30,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: {
        error: 'Bạn đang tìm kiếm quá nhanh. Vui lòng thử lại sau giây lát.',
    },
});

/**
 * 3. Auth Rate Limiter: Chống spam đăng ký / brute-force tài khoản
 * - Giới hạn: 20 requests / 15 phút trên mỗi địa chỉ IP
 */
export const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 phút
    limit: 20,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: {
        error: 'Quá nhiều yêu cầu xác thực. Vui lòng thử lại sau 15 phút.',
    },
});

/**
 * 4. Write / Post Creation Limiter: Chống bot spam tạo bài viết rác vào DB
 * - Giới hạn: 10 bài viết / 1 phút trên mỗi địa chỉ IP
 */
export const createPostLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 phút
    limit: 10,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: {
        error: 'Bạn đang đăng bài quá nhanh. Vui lòng đợi 1 phút trước khi đăng tiếp.',
    },
});
