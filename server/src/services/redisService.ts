import { Redis } from 'ioredis';
import * as dotenv from 'dotenv';

dotenv.config();

const redis = new Redis({
    host: process.env.REDIS_HOST || 'localhost',
    port: Number(process.env.REDIS_PORT) || 6379,
});

redis.on('connect', () => {
    console.log('⚡ Redis connected successfully');
});

redis.on('error', (err: any) => {
    console.error('❌ Redis Error:', err);
});

export default redis;

/**
 * Helper để quản lý Like Buffer
 * Logic: Tăng count trong Redis, sau đó flush về DB sau mỗi 30s
 */
export const incrementLikeBuffer = async (postId: number) => {
    const key = `post:likes:buffer`;
    await redis.hincrby(key, postId.toString(), 1);
};
