# 🧵 Thread City - Ứng dụng Mạng Xã Hội Đa Nền Tảng

> **Thread City** là ứng dụng mạng xã hội (tương tự Threads / X) được phát triển bằng **Flutter** (Frontend) và **Node.js / Express** (Backend), hỗ trợ hoạt động mượt mà trên cả **Mobile (Android/iOS)** và **Web**. Ứng dụng cung cấp trải nghiệm chia sẻ bài viết, tương tác cộng đồng và trò chuyện thời gian thực (Realtime Chat).

🌐 **Trải nghiệm trực tiếp bản Web**: [https://thread-b4d7b.web.app](https://thread-b4d7b.web.app)

---

## ✨ 1. Tính năng nổi bật

* 📝 **Bảng tin & Đăng bài (Feed & Posts)**:
  * Đăng bài viết chia sẻ suy nghĩ, hỗ trợ đính kèm hình ảnh hoặc video.
  * Tự động nhận diện và gắn thẻ `#hashtag` trong nội dung.
  * Tương tác xã hội: Thích (Like), bình luận (Reply), chia sẻ lại (Repost).
* 🔍 **Tìm kiếm & Khám phá (Search & Discovery)**:
  * Tìm kiếm người dùng và bài viết theo từ khóa nhanh chóng.
  * Khám phá bảng tin theo từng hashtag với 2 chế độ sắp xếp: **Nổi bật (Top)** và **Mới nhất (Recent)**.
* ⚡ **Trò chuyện thời gian thực (Realtime Chat)**:
  * Nhắn tin 1-1 tức thì qua Socket.io: Hiển thị trạng thái đang gõ (typing), trạng thái online/offline.
  * Gửi hình ảnh, video và chia sẻ trực tiếp liên kết bài viết vào phòng chat.
* 👤 **Hồ sơ cá nhân & Kết nối**:
  * Chỉnh sửa thông tin cá nhân, cập nhật ảnh đại diện (avatar) và tiểu sử (bio).
  * Theo dõi (Follow / Unfollow) người dùng khác.
  * Chia sẻ trang cá nhân hoặc bài viết thông qua liên kết (Deep link).
* 🔐 **Tài khoản & Bảo mật**:
  * Đăng nhập tiện lợi bằng tài khoản Google (Firebase Auth) hoặc tài khoản Email/Mật khẩu.
  * Quên mật khẩu: Nhận mã xác thực OTP qua Email để đặt lại mật khẩu an toàn.
  * Quy tắc bảo vệ mật khẩu và giới hạn tần suất yêu cầu (Rate Limiting).
* 🌐 **Đa ngôn ngữ (i18n)**:
  * Hỗ trợ chuyển đổi nhanh giữa 3 ngôn ngữ: **Tiếng Việt**, **Tiếng Anh (English)** và **Tiếng Nhật (日本語)**.

---

## 🏗️ 2. Kiến trúc cơ bản của ứng dụng (FE - BE)

Hệ thống được tổ chức phân tách rõ ràng giữa tầng Giao diện (Client) và tầng Máy chủ (Backend):

```mermaid
graph LR
    subgraph Client ["Frontend (Client)"]
        FlutterApp["Flutter App<br/>(Mobile & Web)"]
    end

    subgraph ServerSide ["Backend (Server)"]
        NodeServer["Node.js / Express Server<br/>(REST API & Socket.io)"]
        DB[("MySQL Database<br/>(Prisma ORM)")]
        RedisDB[("Redis<br/>(Socket.io Adapter)")]
        FirebaseServ["Firebase<br/>(Auth & Storage)"]
    end

    FlutterApp <-->|"HTTP REST API"| NodeServer
    FlutterApp <-->|"WebSocket"| NodeServer
    FlutterApp -.->|"Đăng nhập & Tải ảnh"| FirebaseServ
    NodeServer <--> DB
    NodeServer <--> RedisDB
    NodeServer -.->|"Xác thực Token"| FirebaseServ
```

---

## 💻 3. Chi tiết công nghệ sử dụng

### 📱 Frontend (Flutter)
* **Ngôn ngữ & Framework**: [Flutter](https://flutter.dev/) (Dart) - Viết một lần chạy trên cả Android, iOS và Web.
* **Quản lý trạng thái (State Management)**: `Provider` & `ChangeNotifier`.
* **Cấu trúc mã nguồn (`lib/`)**:
  * `screens/`: Các màn hình chính (Trang chủ, Tìm kiếm, Chi tiết bài viết, Chat, Hồ sơ cá nhân,...).
  * `widgets/`: Các thành phần giao diện tái sử dụng (PostCard, ReplySheet, AppTextField,...).
  * `providers/`: Xử lý trạng thái và logic hiển thị (HomeProvider, SearchProvider, MessageProvider,...).
  * `data/repositories/`: Tầng giao tiếp mạng, gọi API tới Backend.
  * `models/`: Định nghĩa các đối tượng dữ liệu (User, Post, Message, Hashtag,...).
* **Kết nối**: `http` cho các API dữ liệu và `socket_io_client` cho luồng chat thời gian thực.

### 🖥️ Backend (Node.js & TypeScript)
* **Nền tảng**: [Node.js](https://nodejs.org/) sử dụng **TypeScript** đảm bảo code an toàn và dễ bảo trì.
* **Web Framework**: [Express.js](https://expressjs.com/) xây dựng các RESTful API.
* **Realtime Engine**: [Socket.IO](https://socket.io/) quản lý phòng chat, gửi nhận tin nhắn thời gian thực.
* **Cơ sở dữ liệu**:
  * **MySQL**: Cơ sở dữ liệu chính lưu trữ tài khoản, bài viết, tin nhắn, tương tác.
  * **Prisma ORM**: Quản lý bảng dữ liệu (Schema) và thực hiện các câu truy vấn an toàn.
  * **Redis**: Hỗ trợ điều phối tin nhắn Socket.io giữa các client.
* **Cấu trúc mã nguồn (`server/src/`)**:
  * `controllers/`: Tiếp nhận và xử lý logic cho từng tính năng.
  * `routes/`: Khai báo các đường dẫn API (`/api/auth`, `/api/posts`, `/api/messages`, `/api/search`,...).
  * `middlewares/`: Xác thực danh tính người dùng và giới hạn số lần gọi API (Rate Limiter).
  * `services/`: Tích hợp Firebase Admin (xác thực token) và Nodemailer (gửi email OTP).
  * `socket.ts`: Thiết lập và quản lý các sự kiện Socket.io.

---

## 🚀 4. Hướng dẫn chạy thử dự án tại máy (Local Setup)

### Yêu cầu môi trường:
* Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản 3.x).
* Đã cài đặt [Node.js](https://nodejs.org/) (phiên bản 18+).
* MySQL và Redis đang hoạt động (trên máy hoặc qua Docker).

---

### Bước 1: Khởi động Backend (Server)
1. Mở terminal, điều hướng vào thư mục `server`:
   ```bash
   cd server
   npm install
   ```
2. Tạo file `.env` trong thư mục `server` (tham khảo từ `.env.example`):
   ```env
   PORT=3000
   DATABASE_URL="mysql://root:password@localhost:3306/thread_city"
   REDIS_URL="redis://localhost:6379"
   SMTP_USER="email_cua_ban@gmail.com"
   SMTP_PASS="mat_khau_ung_dung_google"
   ```
3. Đồng bộ cơ sở dữ liệu và khởi chạy server:
   ```bash
   npx prisma db push
   npm run dev
   ```
   *Máy chủ sẽ chạy tại `http://localhost:3000`.*

---

### Bước 2: Khởi động Frontend (Flutter)
1. Mở một terminal mới tại thư mục gốc của dự án:
   ```bash
   flutter pub get
   ```
2. Chạy ứng dụng trên trình duyệt Web:
   ```bash
   flutter run -d chrome
   ```
   *(Hoặc chọn máy ảo Android / thiết bị iOS để chạy phiên bản Mobile).*
