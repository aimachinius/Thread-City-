import { Router } from 'express';
import {
  register,
  getUserByUid,
  sendForgotPasswordOtp,
  verifyForgotPasswordOtp,
  resetPasswordWithOtp,
} from '../controllers/authController.js';
import { authLimiter } from '../middlewares/rateLimiter.js';

const route = Router();

route.post('/register', authLimiter, register);
route.get('/by-uid/:uid', getUserByUid);

// Luồng Quên mật khẩu trong App qua mã xác thực OTP 6 số
route.post('/forgot-password/send-otp', authLimiter, sendForgotPasswordOtp);
route.post('/forgot-password/verify-otp', authLimiter, verifyForgotPasswordOtp);
route.post('/forgot-password/reset', authLimiter, resetPasswordWithOtp);

export default route;