import nodemailer, { type Transporter } from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

class MailService {
  private transporter: Transporter | null = null;

  constructor() {
    this.initTransporter();
  }

  private initTransporter() {
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    if (!smtpUser || !smtpPass) {
      console.warn('⚠️ [MailService] Chưa cấu hình SMTP_USER và SMTP_PASS trong file server/.env.');
      console.warn('👉 Để gửi email thật tới Gmail, vui lòng thêm SMTP_USER và SMTP_PASS (App Password) vào server/.env');
      return;
    }

    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = Number(process.env.SMTP_PORT) || 465;
    const isGmail = host.toLowerCase().includes('gmail');

    this.transporter = isGmail
      ? nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: smtpUser,
            pass: smtpPass,
          },
        })
      : nodemailer.createTransport({
          host,
          port,
          secure: port === 465,
          auth: {
            user: smtpUser,
            pass: smtpPass,
          },
        });

    console.log(`📧 [MailService] Đã khởi tạo SMTP Transporter (${isGmail ? 'Gmail Service' : `${host}:${port}`}) với tài khoản: ${smtpUser}`);
  }

  /**
   * Gửi email chứa mã OTP 6 số đến người dùng
   */
  async sendOtpEmail(toEmail: string, otp: string): Promise<{ success: boolean; message?: string }> {
    dotenv.config();
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    // Nếu chưa khởi tạo transporter, thử init lại
    if (!this.transporter && smtpUser && smtpPass) {
      this.initTransporter();
    }

    const transporter = this.transporter;
    if (!transporter) {
      const err = 'Chưa cấu hình thông tin gửi mail (SMTP_USER/SMTP_PASS) trong server/.env!';
      console.error(`❌ [MailService] ${err}`);
      return { success: false, message: err };
    }

    const fromAddress = process.env.SMTP_FROM || `"Thread City" <${smtpUser}>`;

    const htmlContent = `
      <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 28px 24px; background-color: #FFF6EC; border-radius: 20px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #FF7A5C; font-size: 26px; margin: 0; font-weight: 800; letter-spacing: -0.5px;">Thread City</h1>
          <p style="color: #9B8981; font-size: 14px; margin-top: 6px;">Yêu cầu đặt lại mật khẩu</p>
        </div>

        <div style="background-color: #ffffff; border-radius: 18px; padding: 28px 24px; box-shadow: 0 4px 16px rgba(0,0,0,0.04); border: 1px solid #FCEEE0;">
          <p style="color: #3D2C28; font-size: 15px; line-height: 1.6; margin-top: 0;">
            Xin chào,
          </p>
          <p style="color: #3D2C28; font-size: 15px; line-height: 1.6;">
            Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong>${toEmail}</strong> trên ứng dụng <strong>Thread City</strong>.
          </p>

          <p style="color: #9B8981; font-size: 13.5px; margin-top: 20px; margin-bottom: 10px; text-align: center;">
            Mã xác thực OTP của bạn là:
          </p>

          <div style="text-align: center; margin: 16px 0 24px 0;">
            <div style="display: inline-block; background: linear-gradient(135deg, #FF7A5C 0%, #F0603F 100%); color: #ffffff; font-size: 32px; font-weight: 800; letter-spacing: 8px; padding: 14px 28px; border-radius: 14px; box-shadow: 0 6px 16px rgba(255, 122, 92, 0.35);">
              ${otp}
            </div>
          </div>

          <p style="color: #9B8981; font-size: 13px; text-align: center; margin-bottom: 0;">
            ⏳ Mã có hiệu lực trong <strong>5 phút</strong>. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.
          </p>
        </div>

        <div style="text-align: center; margin-top: 20px;">
          <p style="color: #B5A7A0; font-size: 12px; margin: 0;">
            Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
          </p>
        </div>
      </div>
    `;

    try {
      const info = await transporter.sendMail({
        from: fromAddress,
        to: toEmail,
        subject: `[Thread City] Mã xác thực OTP của bạn là ${otp}`,
        text: `Mã xác thực OTP đặt lại mật khẩu của bạn là: ${otp}. Mã có hiệu lực trong 5 phút.`,
        html: htmlContent,
      });

      console.log(`✅ [MailService] Đã gửi thành công email OTP tới: ${toEmail} (MessageId: ${info.messageId})`);
      return { success: true };
    } catch (error: any) {
      console.error(`❌ [MailService] Gửi email thất bại tới ${toEmail}:`, error.message);
      return { success: false, message: error.message };
    }
  }
}

export const mailService = new MailService();
export default mailService;
