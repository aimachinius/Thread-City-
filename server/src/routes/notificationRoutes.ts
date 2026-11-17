import express from 'express';
import { getNotifications, markNotificationAsRead } from '../controllers/notificationController.js';

const router = express.Router();
router.get('/', getNotifications);
router.patch('/:id/read', markNotificationAsRead);

export default router;
