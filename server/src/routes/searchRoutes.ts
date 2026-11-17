import { Router } from "express";
import { searchAll, getTrendingHashtags } from "../controllers/searchController.js";
import { searchLimiter } from "../middlewares/rateLimiter.js";

const router = Router();

router.get("/", searchLimiter, searchAll);
router.get("/trending-hashtags", getTrendingHashtags);

export default router;
