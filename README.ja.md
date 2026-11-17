# 🧵 Thread City - クロスプラットフォームSNSアプリ

> **Thread City** は、**Flutter**（フロントエンド）と **Node.js / Express**（バックエンド）で構築されたモダンなソーシャルネットワークアプリケーション（Threads / X 風）です。**モバイル（Android/iOS）** と **Web** の両方で快適に動作し、投稿共有、ソーシャルインタラクション、リアルタイムチャットを提供します。

🌐 **Web デモ**: [https://thread-b4d7b.web.app](https://thread-b4d7b.web.app)

---

## ✨ 1. 主な機能

* 📝 **タイムラインと投稿 (Feed & Posts)**:
  * テキスト、画像、ショート動画付きの投稿機能。
  * 投稿内の `#hashtag`（ハッシュタグ）自動認識。
  * いいね、返信（コメント）、リポスト機能。
* 🔍 **検索と発見 (Search & Discovery)**:
  * ユーザー名やキーワードによるリアルタイム検索。
  * ハッシュタグ別フィード（「人気」と「最新」の並び替え対応）。
* ⚡ **リアルタイムチャット (Realtime Chat)**:
  * Socket.io による 1対1 のリアルタイムメッセージング（タイピング表示、オンライン状態）。
  * 写真・動画の送信、投稿カードのダイレクト共有。
* 👤 **プロフィール & ソーシャル**:
  * アバター、自己紹介文の編集。
  * フォロー / アンフォロー機能。
  * ディープリンク（URL）によるプロフィールや投稿の直接共有。
* 🔐 **認証とセキュリティ**:
  * Google アカウント（Firebase Auth）またはメール/パスワードによるログイン。
  * メール OTP（6桁コード）による安全なパスワード再設定。
  * レート制限（Rate Limiting）とパスワードポリシー保護。
* 🌐 **多言語対応 (i18n)**:
  * **ベトナム語**、**英語**、**日本語** の3言語にシームレス対応。

---

## 🏗️ 2. 基本アーキテクチャ (FE - BE)

```mermaid
graph LR
    subgraph Client ["フロントエンド (Client)"]
        FlutterApp["Flutter App<br/>(Mobile & Web)"]
    end

    subgraph ServerSide ["バックエンド (Server)"]
        NodeServer["Node.js / Express Server<br/>(REST API & Socket.io)"]
        DB[("MySQL Database<br/>(Prisma ORM)")]
        RedisDB[("Redis<br/>(Socket.io Adapter)")]
        FirebaseServ["Firebase<br/>(Auth & Storage)"]
    end

    FlutterApp <-->|"HTTP REST API"| NodeServer
    FlutterApp <-->|"WebSocket"| NodeServer
    FlutterApp -.->|"認証 & メディア保存"| FirebaseServ
    NodeServer <--> DB
    NodeServer <--> RedisDB
    NodeServer -.->|"トークン検証"| FirebaseServ
```

---

## 💻 3. 技術スタック

### 📱 フロントエンド (Flutter)
* **フレームワーク**: [Flutter](https://flutter.dev/) (Dart) - 1つのコードベースで Web, iOS, Android に対応。
* **状態管理**: `Provider` & `ChangeNotifier`。
* **ディレクトリ構成 (`lib/`)**:
  * `screens/`: 主要画面（ホーム、検索、投稿詳細、チャット、プロフィール等）。
  * `widgets/`: 共通UIコンポーネント。
  * `providers/`: ビジネスロジックと状態管理。
  * `data/repositories/`: API 通信層。
  * `models/`: データモデル定義。

### 🖥️ バックエンド (Node.js & TypeScript)
* **実行環境**: [Node.js](https://nodejs.org/) + **TypeScript**。
* **Web フレームワーク**: [Express.js](https://expressjs.com/)。
* **リアルタイム通信**: [Socket.IO](https://socket.io/)。
* **データベース**:
  * **MySQL**: ユーザー、投稿、メッセージなどのメインデータ保存。
  * **Prisma ORM**: データベーススキーマとクエリ管理。
  * **Redis**: Socket.io のリアルタイム通信アダプター。

---

## 🚀 4. ローカル起動方法 (Local Setup)

### 前提条件:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x 以上)
* [Node.js](https://nodejs.org/) (v18 以上)
* ローカルで稼働している MySQL および Redis

---

### ステップ 1: バックエンドの起動
1. `server` ディレクトリに移動してパッケージをインストール:
   ```bash
   cd server
   npm install
   ```
2. `.env` ファイルを作成:
   ```env
   PORT=3000
   DATABASE_URL="mysql://root:password@localhost:3306/thread_city"
   REDIS_URL="redis://localhost:6379"
   SMTP_USER="your_email@gmail.com"
   SMTP_PASS="your_google_app_password"
   ```
3. スキーマの同期とサーバー起動:
   ```bash
   npx prisma db push
   npm run dev
   ```

---

### ステップ 2: フロントエンドの起動
1. プロジェクトルートで以下を実行:
   ```bash
   flutter pub get
   ```
2. Web ブラウザで起動:
   ```bash
   flutter run -d chrome
   ```
