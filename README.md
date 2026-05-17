# Thread City - Social Network App 🧵🏙 neighborhoods

Dự án mạng xã hội Threads-clone (Fullstack) được phát triển bằng **Flutter** (Mobile) và **Node.js** + **TypeScript** + **Prisma ORM** + **MySQL** + **Redis** (Backend).

---

## 🏗️ Kiến Trúc Hệ Thống (Architecture)

- **Mobile (lib/)**: Kiến trúc **Provider Pattern + Repository Pattern**. Tách biệt tầng hiển thị UI, tầng quản lý trạng thái (`Provider`) và tầng gọi API (`Repository`).
- **Backend (server/)**: Thiết kế mô hình RESTful API sử dụng Express, TypeScript, **Prisma ORM** kết nối MySQL, và **Redis** làm bộ nhớ đệm hỗ trợ tải Feed nhanh.
- **Database**: **MySQL 8** (chạy trên Docker container, cổng `3308`).
- **Bảo mật & Media**: Tích hợp **Firebase Auth** để xác thực người dùng và **Firebase Storage** để tải ảnh/video của bài đăng.

---

## 🚀 Hướng Dẫn Thiết Lập Backend (Server, MySQL & Redis)

Mở cửa sổ dòng lệnh tại thư mục **`server/`** và thực hiện lần lượt các bước sau:

### 1. Khởi động hạ tầng Docker
```powershell
docker compose up -d
```
*MySQL sẽ lắng nghe tại cổng `3308` và Redis lắng nghe tại cổng `6379`.*

### 2. Cài đặt các thư viện Node.js
```powershell
npm install
```

### 3. Cấu hình tệp môi trường `.env`
Tạo một tệp tin mới tên là **`.env`** tại thư mục `server/` với nội dung sau:
```env
DATABASE_URL="mysql://thread_user:thread_password@localhost:3308/thread_city"
PORT=3000
JWT_SECRET="your_secret_key_here"
REDIS_HOST="localhost"
REDIS_PORT=6379
```

### 4. Đồng bộ Database & Sinh cấu trúc Prisma ORM
*Trên hệ điều hành Windows, nếu sử dụng PowerShell, hãy thêm `cmd /c` phía trước lệnh npx để tránh các lỗi bảo mật chính sách (Policy restriction):*
```powershell
cmd /c npx prisma generate
cmd /c npx prisma db push
```

### 5. Nạp dữ liệu mẫu (Database Seeding)
Dự án đã tích hợp sẵn tập tin tạo dữ liệu mẫu (`server/prisma/seed.ts`). Chạy lệnh sau để tự động tạo tài khoản và các bài viết mẫu đầu tiên:
```powershell
cmd /c npx prisma db seed
```

### 6. Khởi chạy Server
```powershell
cmd /c npm run dev
```
*Server sẽ bắt đầu lắng nghe tại địa chỉ `http://localhost:3000`.*

---

## 🔥 Cấu Hình Firebase (Bắt buộc)

Dự án này sử dụng Firebase song song cả hai phía: Mobile App (Firebase SDK) và Backend Server (Firebase Admin SDK).

### 1. Cấu hình phía Backend Server (Firebase Admin SDK)
1. Truy cập [Firebase Console](https://console.firebase.google.com/), chọn dự án của bạn.
2. Đi tới **Project Settings** -> **Service Accounts**.
3. Bấm **Generate New Private Key**, một file dạng `.json` sẽ được tải về.
4. Đổi tên file đó thành **`serviceAccountKey.json`**.
5. Di chuyển tệp tin này vào thư mục **`server/`** (ngang hàng với tệp `package.json`).

### 2. Cấu hình phía Mobile App (Flutter Firebase SDK)
Bạn có thể cấu hình nhanh bằng 2 cách:

#### Cách 1: Sử dụng FlutterFire CLI (Khuyên dùng)
Yêu cầu máy bạn đã cài [Firebase CLI](https://firebase.google.com/docs/cli). Chạy lệnh sau tại thư mục gốc dự án:
```powershell
flutterfire configure
```
*Lệnh này sẽ tự động đăng ký App trên Firebase Console và tạo tệp tin `lib/firebase_options.dart` hoàn toàn tự động.*

#### Cách 2: Cài đặt thủ công theo từng nền tảng
- **Android**: 
  1. Tải tệp tin **`google-services.json`** từ trang cài đặt Android App của Firebase Console.
  2. Copy tệp tin vào thư mục: `android/app/google-services.json`.
- **iOS**:
  1. Tải tệp tin **`GoogleService-Info.plist`** từ trang cài đặt iOS App của Firebase Console.
  2. Kéo thả tệp tin vào thư mục: `ios/Runner/` thông qua Xcode.

### 3. Cấu hình dịch vụ trên Firebase Console
- **Authentication**: Đi tới mục *Authentication* -> *Sign-in method* -> Chọn kích hoạt (Enable) nhà cung cấp **Email/Password**.
- **Firebase Storage**: Bật dịch vụ *Storage* và định cấu hình Rule (quy tắc bảo mật) cho phép đọc và ghi (Read/Write) nếu người dùng đã đăng nhập:
  ```javascript
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /{allPaths=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
  ```

---

## 📱 Hướng Dẫn Thiết Lập Flutter Mobile App

Di chuyển ra thư mục gốc của dự án:

### 1. Tải toàn bộ các thư viện Flutter
```powershell
flutter pub get
```
*Lệnh này sẽ tự động tải các gói phụ thuộc từ `pubspec.yaml` bao gồm: provider, http, firebase_core, firebase_auth, firebase_storage, image_picker, video_player.*

### 2. Cấu hình đường dẫn kết nối API (Cực kỳ quan trọng)
Mở tệp tin [**`lib/core/config/app_config.dart`**](file:///e:/FlutterApp/Social_mobile_app_Thread/Thread-City-/lib/core/config/app_config.dart) và thiết lập thông số mạng:
```dart
class AppConfig {
  // - Nếu chạy máy ảo Android Emulator: Hãy điền '10.0.2.2'
  // - Nếu chạy máy ảo iOS Simulator: Hãy điền '127.0.0.1' hoặc 'localhost'
  // - Nếu test trên ĐIỆN THOẠI THẬT: Điền địa chỉ IPv4 cục bộ của máy tính của bạn (Ví dụ: '192.168.1.9')
  static const String ipAddress = '192.168.1.9'; 
  
  static const String baseUrl = 'http://$ipAddress:3000/api';
  static const String authUrl = '$baseUrl/auth';
  static const String postsUrl = '$baseUrl/posts';
}
```

### 3. Khởi chạy ứng dụng
```powershell
flutter run
```

---

