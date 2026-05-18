import { Router } from "express";
import { getUserProfile, updateProfile, followUser, unfollowUser, getUserFollowers, getUserFollowing } from "../controllers/userController.js";

const router = Router();

router.get("/:firebase_uid", getUserProfile);
router.patch("/:firebase_uid", updateProfile);
router.post("/follow", followUser);
router.post("/unfollow", unfollowUser);
router.get("/:userId/followers", getUserFollowers);
router.get("/:userId/following", getUserFollowing);

export default router;
