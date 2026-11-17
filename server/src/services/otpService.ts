import crypto from 'crypto';

interface OtpEntry {
  otp: string;
  expiresAt: number;
  attempts: number;
  verified: boolean;
}

const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const MAX_ATTEMPTS = 5;

// In-memory store for OTPs (keyed by lowercase normalized email)
const otpStore = new Map<string, OtpEntry>();

// Periodic cleanup every 2 minutes
setInterval(() => {
  const now = Date.now();
  for (const [email, entry] of otpStore.entries()) {
    if (now > entry.expiresAt) {
      otpStore.delete(email);
    }
  }
}, 2 * 60 * 1000).unref();

export class OtpService {
  /**
   * Tạo mã OTP 6 số ngẫu nhiên cho email và lưu vào store
   */
  static generateOtp(email: string): string {
    const normalizedEmail = email.trim().toLowerCase();
    
    // Sinh số ngẫu nhiên 6 chữ số an toàn từ crypto
    const randomInt = crypto.randomInt(100000, 1000000);
    const otp = randomInt.toString();

    otpStore.set(normalizedEmail, {
      otp,
      expiresAt: Date.now() + OTP_TTL_MS,
      attempts: 0,
      verified: false,
    });

    console.log(`🔑 [OTP] Đã tạo mã xác thực OTP cho tài khoản: ${normalizedEmail}`);

    return otp;
  }

  /**
   * Kiểm tra mã OTP do người dùng nhập
   */
  static verifyOtp(email: string, otp: string): { success: boolean; message?: string } {
    const normalizedEmail = email.trim().toLowerCase();
    const entry = otpStore.get(normalizedEmail);

    if (!entry) {
      return { success: false, message: 'Mã OTP không tồn tại hoặc đã hết hạn. Vui lòng yêu cầu mã mới.' };
    }

    if (Date.now() > entry.expiresAt) {
      otpStore.delete(normalizedEmail);
      return { success: false, message: 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.' };
    }

    entry.attempts += 1;
    if (entry.attempts > MAX_ATTEMPTS) {
      otpStore.delete(normalizedEmail);
      return { success: false, message: 'Bạn đã nhập sai OTP quá 5 lần. Mã đã bị hủy để bảo mật.' };
    }

    if (entry.otp !== otp.trim()) {
      const remaining = MAX_ATTEMPTS - entry.attempts;
      return {
        success: false,
        message: `Mã OTP không chính xác. Bạn còn ${remaining} lần thử.`,
      };
    }

    // Đánh dấu OTP này đã được xác thực thành công
    entry.verified = true;
    return { success: true };
  }

  /**
   * Sử dụng và hủy mã OTP đã xác thực khi đổi mật khẩu
   */
  static consumeVerifiedOtp(email: string, otp: string): boolean {
    const normalizedEmail = email.trim().toLowerCase();
    const entry = otpStore.get(normalizedEmail);

    if (!entry) return false;
    if (Date.now() > entry.expiresAt) {
      otpStore.delete(normalizedEmail);
      return false;
    }

    if (entry.verified && entry.otp === otp.trim()) {
      otpStore.delete(normalizedEmail);
      return true;
    }

    return false;
  }

  /**
   * Lấy entry hiện tại (chủ yếu phục vụ unit test)
   */
  static _getEntry(email: string): OtpEntry | undefined {
    return otpStore.get(email.trim().toLowerCase());
  }

  /**
   * Xóa sạch store (phục vụ unit test)
   */
  static _clearStore(): void {
    otpStore.clear();
  }
}

export default OtpService;
