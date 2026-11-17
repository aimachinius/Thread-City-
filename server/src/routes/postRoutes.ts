import { Router } from "express";
import { getFeed, createPost, toggleLike, getReplies, getPostsByUserUid, toggleRepost, getUserReposts, getPostsByHashtag, getPostById, deletePost } from "../controllers/postController.js";
import { createPostLimiter } from "../middlewares/rateLimiter.js";
import { requireAuth, optionalAuth } from "../middlewares/authMiddleware.js";

const router = Router();

router.get("/", optionalAuth, getFeed);
router.post("/", createPostLimiter, requireAuth, createPost);
router.get('/:id/replies', optionalAuth, getReplies);
router.post('/:id/like', requireAuth, toggleLike);
router.post('/:id/repost', requireAuth, toggleRepost);
router.get('/user/:firebase_uid', optionalAuth, getPostsByUserUid);
router.get('/user/:firebase_uid/reposts', optionalAuth, getUserReposts);
router.get('/hashtag/:tag', optionalAuth, getPostsByHashtag);
router.get('/:id', optionalAuth, getPostById);
router.delete('/:id', requireAuth, deletePost);

export default router;


