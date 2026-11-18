import nodemailer, { type Transporter } from 'nodemailer';
import { Resend } from 'resend';
import dotenv from 'dotenv';

dotenv.config();

class MailService {
  private transporter: Transporter | null = null;
  private resendClient: Resend | null = null;

  constructor() {
    this.initProviders();
  }

  private initProviders() {
    // 1. Khởi tạo Resend (Gửi qua HTTPS Port 443 - không bao giờ bị Render chặn)
    const resendApiKey = process.env.RESEND_API_KEY;
    if (resendApiKey) {
      this.resendClient = new Resend(resendApiKey);
      console.log('🚀 [MailService] Đã kích hoạt Resend API (HTTPS Port 443 - Tối ưu cho Cloud/Render)');
    }

    // 2. Khởi tạo Nodemailer (Dự phòng cho Localhost hoặc môi trường hỗ trợ SMTP)
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    if (smtpUser && smtpPass) {
      const host = process.env.SMTP_HOST || 'smtp.gmail.com';
      const port = Number(process.env.SMTP_PORT) || 465;
      const isGmail = host.toLowerCase().includes('gmail');

      // Thêm connectionTimeout 5000ms để fail-fast, không bị treo 21s nếu port bị chặn
      const transportOptions: any = {
        connectionTimeout: 5000,
        greetingTimeout: 5000,
        socketTimeout: 5000,
      };

      this.transporter = isGmail
        ? nodemailer.createTransport({
            ...transportOptions,
            service: 'gmail',
            auth: {
              user: smtpUser,
              pass: smtpPass,
            },
          })
        : nodemailer.createTransport({
            ...transportOptions,
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
  }

  /**
   * Gửi email chứa mã OTP 6 số đến người dùng
   */
  async sendOtpEmail(toEmail: string, otp: string): Promise<{ success: boolean; message?: string }> {
    dotenv.config();

    // In mã OTP ra console để hỗ trợ dev/test ngay cả khi mạng email gặp sự cố
    console.log(`🔑 [OTP CONSOLE] Mã xác thực OTP cho tài khoản ${toEmail} là: [ ${otp} ]`);

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

    // ── ƯU TIÊN 1: Gửi qua Resend API (HTTPS Port 443 - Render không chặn) ────
    const resendApiKey = process.env.RESEND_API_KEY;
    if (resendApiKey) {
      try {
        if (!this.resendClient) {
          this.resendClient = new Resend(resendApiKey);
        }
        const fromAddress = process.env.RESEND_FROM || 'Thread City <onboarding@resend.dev>';
        const result = await this.resendClient.emails.send({
          from: fromAddress,
          to: [toEmail],
          subject: `[Thread City] Mã xác thực OTP của bạn là ${otp}`,
          html: htmlContent,
        });

        if (result.error) {
          console.error(`❌ [MailService] Resend gửi lỗi tới ${toEmail}:`, result.error.message);
        } else {
          console.log(`✅ [MailService] Đã gửi thành công email OTP qua Resend tới: ${toEmail} (Id: ${result.data?.id})`);
          return { success: true };
        }
      } catch (e: any) {
        console.error(`❌ [MailService] Ngoại lệ khi gọi Resend:`, e.message);
      }
    }

    // ── ƯU TIÊN 2: Gửi qua Brevo REST API (HTTPS Port 443) ───────────────────
    const brevoApiKey = process.env.BREVO_API_KEY;
    if (brevoApiKey) {
      try {
        const senderEmail = process.env.BREVO_SENDER || process.env.SMTP_USER || 'support@threadcity.com';
        const res = await fetch('https://api.brevo.com/v3/smtp/email', {
          method: 'POST',
          headers: {
            'accept': 'application/json',
            'api-key': brevoApiKey,
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            sender: { name: 'Thread City', email: senderEmail },
            to: [{ email: toEmail }],
            subject: `[Thread City] Mã xác thực OTP của bạn là ${otp}`,
            htmlContent,
          }),
        });

        if (res.ok) {
          console.log(`✅ [MailService] Đã gửi thành công email OTP qua Brevo REST API tới: ${toEmail}`);
          return { success: true };
        } else {
          const errData = await res.json().catch(() => ({}));
          console.error(`❌ [MailService] Brevo API lỗi:`, errData);
        }
      } catch (e: any) {
        console.error(`❌ [MailService] Ngoại lệ khi gọi Brevo:`, e.message);
      }
    }

    // ── ƯU TIÊN 3: Gửi qua Nodemailer SMTP (Localhost hoặc Paid Cloud) ───────
    if (!this.transporter && process.env.SMTP_USER && process.env.SMTP_PASS) {
      this.initProviders();
    }

    if (this.transporter) {
      const smtpUser = process.env.SMTP_USER;
      const fromAddress = process.env.SMTP_FROM || `"Thread City" <${smtpUser}>`;

      try {
        const info = await this.transporter.sendMail({
          from: fromAddress,
          to: toEmail,
          subject: `[Thread City] Mã xác thực OTP của bạn là ${otp}`,
          text: `Mã xác thực OTP đặt lại mật khẩu của bạn là: ${otp}. Mã có hiệu lực trong 5 phút.`,
          html: htmlContent,
        });

        console.log(`✅ [MailService] Đã gửi thành công email OTP qua SMTP tới: ${toEmail} (MessageId: ${info.messageId})`);
        return { success: true };
      } catch (error: any) {
        console.error(`❌ [MailService] Gửi email qua SMTP thất bại tới ${toEmail}:`, error.message);
        return { success: false, message: `SMTP error: ${error.message}` };
      }
    }

    const err = 'Chưa cấu hình dịch vụ email (RESEND_API_KEY, BREVO_API_KEY hoặc SMTP_USER/SMTP_PASS).';
    console.warn(`⚠️ [MailService] ${err}`);
    return { success: false, message: err };
  }
}

export const mailService = new MailService();
export default mailService;
