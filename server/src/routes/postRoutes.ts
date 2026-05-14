import { Router } from "express";
import { getFeed, createPost, toggleLike, getReplies } from "../controllers/postController.js";

const router = Router();

router.get("/", getFeed);
router.post("/", createPost);
router.get('/:id/replies', getReplies);
router.post('/:id/like', toggleLike);

export default router;
