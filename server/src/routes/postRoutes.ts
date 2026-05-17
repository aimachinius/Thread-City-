import { Router } from "express";
import { getFeed, createPost, toggleLike, getReplies, getPostsByUserUid } from "../controllers/postController.js";

const router = Router();

router.get("/", getFeed);
router.post("/", createPost);
router.get('/:id/replies', getReplies);
router.post('/:id/like', toggleLike);
router.get('/user/:firebase_uid', getPostsByUserUid);

export default router;
