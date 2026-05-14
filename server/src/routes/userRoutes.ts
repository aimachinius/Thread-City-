import { Router } from "express";
import { getUserProfile, updateProfile } from "../controllers/userController.js";

const router = Router();

router.get("/:firebase_uid", getUserProfile);
router.patch("/:firebase_uid", updateProfile);

export default router;
