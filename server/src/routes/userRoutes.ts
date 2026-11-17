import { Router } from "express";
import { getUserProfile, updateProfile, followUser, unfollowUser, getUserFollowers, getUserFollowing } from "../controllers/userController.js";
import { requireAuth, optionalAuth } from "../middlewares/authMiddleware.js";

const router = Router();

router.get("/:firebase_uid", optionalAuth, getUserProfile);
router.patch("/:firebase_uid", requireAuth, updateProfile);
router.post("/follow", requireAuth, followUser);
router.post("/unfollow", requireAuth, unfollowUser);
router.get("/:userId/followers", getUserFollowers);
router.get("/:userId/following", getUserFollowing);

export default router;
