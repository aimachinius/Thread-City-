# 🧵 Thread City - Cross-Platform Social Network App

> **Thread City** is a modern social network application (inspired by Threads / X) built with **Flutter** (Frontend) and **Node.js / Express** (Backend), running smoothly across **Mobile (Android/iOS)** and **Web**. The app delivers a rich experience with status sharing, community interactions, and realtime chat.

🌐 **Live Web Demo**: [https://thread-b4d7b.web.app](https://thread-b4d7b.web.app)

---

## ✨ 1. Key Features

* 📝 **Feed & Posts**:
  * Share thoughts, short notes, and upload with images or short videos.
  * Automatically recognizes and tags `#hashtag` inside posts.
  * Social interactions: Like, Reply (comment), and Repost.
* 🔍 **Search & Discovery**:
  * Fast search for users and posts by keywords.
  * Explore hashtag feeds sorted by **Top** or **Recent**.
* ⚡ **Realtime Chat**:
  * 1-on-1 instant messaging powered by Socket.io: Typing indicators, online/offline presence.
  * Send multimedia messages (photos, videos) and share post cards directly into conversations.
* 👤 **User Profiles & Social Graph**:
  * Customizable profile with avatar and bio.
  * Follow / Unfollow system.
  * Share profiles and posts via clean Deep Links.
* 🔐 **Authentication & Security**:
  * Sign in with Google (Firebase Auth) or standard Email/Password.
  * Forgot Password flow with 6-digit OTP verification via Email.
  * Robust password policy and API Rate Limiting protection.
* 🌐 **Internationalization (i18n)**:
  * Seamless language switching between **Vietnamese**, **English**, and **Japanese**.

---

## 🏗️ 2. Basic Architecture (FE - BE)

A clean, decoupled architecture between Client and Server:

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
    FlutterApp -.->|"Auth & Media Upload"| FirebaseServ
    NodeServer <--> DB
    NodeServer <--> RedisDB
    NodeServer -.->|"Token Verification"| FirebaseServ
```

---

## 💻 3. Tech Stack Overview

### 📱 Frontend (Flutter)
* **Framework**: [Flutter](https://flutter.dev/) (Dart) - Single codebase for Android, iOS, and Web.
* **State Management**: `Provider` & `ChangeNotifier`.
* **Folder Structure (`lib/`)**:
  * `screens/`: Main UI screens (Home, Search, PostDetail, Chat, Profile, Auth,...).
  * `widgets/`: Reusable widgets (PostCard, ReplySheet, AppTextField,...).
  * `providers/`: State management and UI logic.
  * `data/repositories/`: Network abstraction and API clients.
  * `models/`: Data models (User, Post, Message, Hashtag,...).

### 🖥️ Backend (Node.js & TypeScript)
* **Platform**: [Node.js](https://nodejs.org/) with **TypeScript** for type safety and maintainability.
* **Web Framework**: [Express.js](https://expressjs.com/) for RESTful APIs.
* **Realtime**: [Socket.IO](https://socket.io/) for chat rooms and event broadcasting.
* **Database & ORM**:
  * **MySQL**: Relational storage for users, posts, messages, and interactions.
  * **Prisma ORM**: Schema migrations and type-safe database queries.
  * **Redis**: Realtime message sync for Socket.io.
* **Folder Structure (`server/src/`)**:
  * `controllers/`: Request handling and business logic.
  * `routes/`: API endpoint definitions (`/api/auth`, `/api/posts`, `/api/messages`, `/api/search`,...).
  * `middlewares/`: JWT authentication and rate limiters.
  * `services/`: Firebase Admin SDK and Nodemailer email delivery.
  * `socket.ts`: Socket.IO connection and room event management.

---

## 🚀 4. Local Setup Guide

### Prerequisites:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x+).
* [Node.js](https://nodejs.org/) (v18+).
* MySQL & Redis instances running locally or via Docker.

---

### Step 1: Start Backend (Server)
1. Open terminal and enter `server`:
   ```bash
   cd server
   npm install
   ```
2. Create `.env` file inside `server`:
   ```env
   PORT=3000
   DATABASE_URL="mysql://root:password@localhost:3306/thread_city"
   REDIS_URL="redis://localhost:6379"
   SMTP_USER="your_email@gmail.com"
   SMTP_PASS="your_google_app_password"
   ```
3. Push database schema and launch server:
   ```bash
   npx prisma db push
   npm run dev
   ```
   *Server will run at `http://localhost:3000`.*

---

### Step 2: Start Frontend (Flutter)
1. Open a new terminal in the project root:
   ```bash
   flutter pub get
   ```
2. Run on Chrome Web:
   ```bash
   flutter run -d chrome
   ```
   *(Or select your Android / iOS emulator to run on Mobile).*
