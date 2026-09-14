import { Router } from "express";
import { getFeed, createPost, toggleLike, getReplies, getPostsByUserUid, toggleRepost, getUserReposts } from "../controllers/postController.js";

const router = Router();

router.get("/", getFeed);
router.post("/", createPost);
router.get('/:id/replies', getReplies);
router.post('/:id/like', toggleLike);
router.post('/:id/repost', toggleRepost);
router.get('/user/:firebase_uid', getPostsByUserUid);
router.get('/user/:firebase_uid/reposts', getUserReposts);

export default router;
