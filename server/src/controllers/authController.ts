import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import { validatePassword } from "../utils/passwordValidator.js";
import { auth } from "../services/firebaseService.js";
import OtpService from "../services/otpService.js";
import mailService from "../services/mailService.js";

const prisma = new PrismaClient();

/**
 * Safe User DTO: Whitelists only safe public/profile fields.
 * Prevents exposing password_hash, fcm_token, or internal fields.
 */
export const safeUserDTO = (user: any) => ({
  id: user.id,
  firebase_uid: user.firebase_uid,
  username: user.username,
  email: user.email,
  nickname: user.nickname,
  avatar_url: user.avatar_url,
  bio: user.bio,
  is_verified: user.is_verified,
  status: user.status,
  created_at: user.created_at,
  updated_at: user.updated_at,
});

/** Chuyển chuỗi có dấu tiếng Việt thành không dấu ASCII */
function removeVietnameseTones(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')  // Bỏ dấu
    .replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .replace(/[^a-zA-Z0-9]/g, '')    // Bỏ space và ký tự đặc biệt
    .toLowerCase()
    .slice(0, 25);                    // Tối đa 25 ký để còn chỗ suffix
}

/** Tạo username unique từ nickname, thêm suffix ngẫu nhiên nếu trùng */
async function generateUniqueUsername(base: string): Promise<string> {
  const cleaned = removeVietnameseTones(base) || 'user';
  let candidate = cleaned;

  const exists = await prisma.user.findFirst({ where: { username: candidate } });
  if (!exists) return candidate;

  // Thêm suffix 4 ký tự ngẫu nhiên
  const suffix = Math.random().toString(36).slice(2, 6);
  return `${cleaned}_${suffix}`;
}

export const register = async (req: Request, res: Response) => {
  try {
    const { firebase_uid, email, username: rawUsername, nickname, password } = req.body;

    if (!firebase_uid || !email) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin bắt buộc (firebase_uid, email)",
      });
    }

    // 1. Idempotency: Same firebase_uid -> treat as idempotent retry, return existing user
    const existingByUid = await prisma.user.findUnique({
      where: { firebase_uid },
    });

    if (existingByUid) {
      return res.status(200).json({
        message: 'User đã tồn tại',
        user: safeUserDTO(existingByUid),
      });
    }

    // 2. Conflict: Same email but DIFFERENT firebase_uid -> HTTP 409 Conflict, do NOT return existing user
    const existingByEmail = await prisma.user.findUnique({
      where: { email },
    });

    if (existingByEmail) {
      return res.status(409).json({
        success: false,
        message: 'Email này đã được sử dụng bởi một tài khoản khác',
      });
    }

    // 3. Mandatory Backend Password Validation if password is provided
    if (password !== undefined) {
      const passwordResult = validatePassword(password);
      if (!passwordResult.isValid) {
        return res.status(400).json({
          success: false,
          message: 'Mật khẩu không thỏa mãn chính sách bảo mật',
          errors: passwordResult.errors,
        });
      }
    }

    // Ưu tiên nickname để sinh username, fallback sang rawUsername cũ
    const displayName = nickname || rawUsername || email.split('@')[0] || 'user';
    const username = nickname
      ? await generateUniqueUsername(displayName)
      : (rawUsername || displayName);

    try {
      const newUser = await prisma.user.create({
        data: {
          firebase_uid,
          email,
          username,
          nickname: displayName,  // Lưu nickname hiển thị
          status: 'active',
        },
      });

      return res.status(201).json({
        message: 'Đăng kí thành công',
        user: safeUserDTO(newUser),
      });
    } catch (createError: any) {
      // Handle Prisma P2002 race condition on concurrent registration requests
      if (createError?.code === 'P2002') {
        const target = Array.isArray(createError?.meta?.target)
          ? createError.meta.target.join(',')
          : String(createError?.meta?.target || '');

        if (target.includes('email') || target.includes('unique_email')) {
          return res.status(409).json({
            success: false,
            message: 'Email này đã được sử dụng bởi một tài khoản khác',
          });
        }

        if (target.includes('firebase_uid') || target.includes('unique_firebase_uid')) {
          const raceUser = await prisma.user.findUnique({ where: { firebase_uid } });
          if (raceUser) {
            return res.status(200).json({
              message: 'User đã tồn tại',
              user: safeUserDTO(raceUser),
            });
          }
        }
      }
      throw createError;
    }
  } catch (error: any) {
    // Non-sensitive logging only: never log plaintext passwords
    console.error('Lỗi server register: ', error?.message || 'Unknown error');
    return res.status(500).json({
      message: "Internal server error",
    });
  }
};

export const login = async (req: Request, res: Response) => {
  // Logic login của server (nếu cần sinh JWT)
};

export const getUserByUid = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    if (!uid) {
      return res.status(400).json({ message: "UID is required" });
    }

    const user = await prisma.user.findUnique({
      where: { firebase_uid: uid as string },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Return Safe User DTO: excludes password_hash, fcm_token, etc.
    return res.status(200).json(safeUserDTO(user));
  } catch (error: any) {
    console.error("Lỗi getUserByUid:", error?.message || 'Unknown error');
    return res.status(500).json({ message: "Internal server error" });
  }
};

/**
 * Gửi mã xác nhận OTP 6 số đến email để khôi phục mật khẩu
 */
export const sendForgotPasswordOtp = async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    if (!email || typeof email !== 'string') {
      return res.status(400).json({
        success: false,
        message: "Email là bắt buộc",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản với email này",
      });
    }

    const otp = OtpService.generateOtp(normalizedEmail);

    // Gửi email thật qua mailService (Nodemailer / SMTP)
    const mailResult = await mailService.sendOtpEmail(normalizedEmail, otp);

    return res.status(200).json({
      success: true,
      message: mailResult.success
        ? "Mã xác thực OTP đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư (hoặc mục Spam)."
        : "Đã tạo mã OTP xác thực (Lưu ý: kiểm tra cấu hình SMTP trong server/.env nếu chưa nhận được mail)",
      mailSent: mailResult.success,
    });
  } catch (error: any) {
    console.error("Lỗi sendForgotPasswordOtp:", error?.message || 'Unknown error');
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

/**
 * Xác thực mã OTP 6 số từ người dùng
 */
export const verifyForgotPasswordOtp = async (req: Request, res: Response) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Email và mã OTP là bắt buộc",
      });
    }

    const result = OtpService.verifyOtp(email, otp);
    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.message || "Mã OTP không hợp lệ",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Xác thực mã OTP thành công",
    });
  } catch (error: any) {
    console.error("Lỗi verifyForgotPasswordOtp:", error?.message || 'Unknown error');
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

/**
 * Đổi mật khẩu mới bằng OTP kèm kiểm tra nghiêm ngặt 7 quy tắc bảo mật
 */
export const resetPasswordWithOtp = async (req: Request, res: Response) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin bắt buộc (email, otp, newPassword)",
      });
    }

    // 1. Kiểm tra 7 quy tắc bảo mật mật khẩu
    const validation = validatePassword(newPassword);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: validation.errors[0] || "Mật khẩu không thỏa mãn chính sách bảo mật",
        errors: validation.errors,
      });
    }

    // 2. Xác thực và tiêu thụ mã OTP
    const isValidOtp = OtpService.consumeVerifiedOtp(email, otp);
    if (!isValidOtp) {
      return res.status(400).json({
        success: false,
        message: "Mã OTP không hợp lệ, đã hết hạn hoặc chưa được xác thực",
      });
    }

    // 3. Tìm user trong MySQL để lấy firebase_uid
    const normalizedEmail = email.trim().toLowerCase();
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy người dùng",
      });
    }

    // 4. Cập nhật mật khẩu trong Firebase Auth qua Admin SDK
    if (!auth) {
      throw new Error("Firebase Auth Admin chưa được khởi tạo");
    }

    await auth.updateUser(user.firebase_uid, {
      password: newPassword,
    });

    // 5. Cập nhật timestamp trong MySQL
    await prisma.user.update({
      where: { id: user.id },
      data: { updated_at: new Date() },
    });

    console.log(`✅ [Auth] Password reset successfully via in-app OTP for: ${normalizedEmail}`);

    return res.status(200).json({
      success: true,
      message: "Đổi mật khẩu thành công! Bạn có thể đăng nhập ngay bây giờ.",
    });
  } catch (error: any) {
    console.error("Lỗi resetPasswordWithOtp:", error?.message || 'Unknown error');
    return res.status(500).json({
      success: false,
      message: error?.message || "Internal server error",
    });
  }
};