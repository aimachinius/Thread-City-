# Thread City - Social Network App

Dự án mạng xã hội Threads-like được xây dựng bằng Flutter (Mobile) và Node.js + Prisma ORM + MySQL + Redis (Backend).

## 🚀 Hướng dẫn Setup từ A-Z (Cập nhật mới nhất)

Dành cho các thành viên mới tham gia dự án. Vui lòng thực hiện theo đúng trình tự sau:

### 1. Yêu cầu hệ thống (Prerequisites)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Đã bật và đang chạy - Đảm bảo icon cá voi màu xanh)
- [Node.js](https://nodejs.org/) (Phiên bản 18 trở lên)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)

---

### 2. Bước 1: Khởi động Hạ tầng (MySQL & Redis)
Di chuyển vào thư mục `server` để bật các dịch vụ bằng Docker:
```powershell
cd server
docker compose up -d
```
*Lưu ý: MySQL sẽ chạy tại cổng **3308** và Redis chạy tại **6379** để tránh xung đột với các ứng dụng cài sẵn trên máy của bạn.*

---

### 3. Bước 2: Thiết lập Backend Server
Đảm bảo bạn vẫn đang ở trong thư mục `server`:

1. **Cài đặt thư viện:**
   ```powershell
   npm install
   ```

2. **Cấu hình Firebase (Bắt buộc - File này bị ẩn trên Git):**
   - Bạn cần xin Admin hoặc tự tạo file `serviceAccountKey.json` (từ Firebase Console).
   - Copy file này vào thư mục `server/` (Nằm ngang hàng với `package.json`).

3. **Cấu hình biến môi trường (Bắt buộc - Bị ẩn trên Git):**
   - Tạo một file tên là `.env` trong thư mục `server/`.
   - Copy nội dung sau dán vào file `.env` (lưu ý cổng 3308):
   ```env
   DATABASE_URL="mysql://thread_user:thread_password@localhost:3308/thread_city"
   PORT=3000
   JWT_SECRET="your_secret_key"
   REDIS_HOST="localhost"
   REDIS_PORT=6379
   ```

4. **Đồng bộ Database & Khởi tạo ORM:**
   *Sử dụng thêm `cmd /c` hoặc gõ `npx.cmd` để tránh lỗi Security của PowerShell trên Windows:*
   ```powershell
   cmd /c npx prisma generate
   cmd /c npx prisma db push
   ```

5. **Chạy Server:**
   ```powershell
   cmd /c npm run dev
   ```
   *Khi thấy dòng `🚀 Server is running on http://localhost:3000` là thành công.*

---

### 4. Bước 3: Chạy App Flutter
Mở một terminal mới tại thư mục gốc của dự án:
```powershell
flutter pub get
flutter run
```

---

## 🛠 Kiến trúc dự án
- **Mobile (lib/)**: Sử dụng mô hình **Provider + Repository Pattern**.
- **Backend (server/)**: Sử dụng **Node.js + TypeScript**, **Prisma ORM** và **Redis**.
- **Database & Cache**: **MySQL 8** và **Redis** chạy trong Docker.

## ⚠️ Lưu ý quan trọng
- Nếu dùng máy ảo Android (Emulator), hãy đổi `localhost` trong file cấu hình mạng của Flutter thành `10.0.2.2`.
- Lỗi `UnauthorizedAccess` / `Execution Policies` trên Windows: Luôn thêm `cmd /c` vào đầu các lệnh `npm` hoặc `npx`.
- Các file nhạy cảm như `.env` và `serviceAccountKey.json` đã được đưa vào `.gitignore`. **Tuyệt đối không commit các file này lên GitHub.**
- Luôn giữ Docker Desktop chạy trong quá trình phát triển để duy trì kết nối tới MySQL và Redis.
