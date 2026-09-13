import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import * as dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';
import postRoutes from './routes/postRoutes.js';
import userRoutes from './routes/userRoutes.js';
import { getCorsOptions } from './config/cors.js';
import messageRoutes from './routes/messageRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';

import { createServer } from 'http'; // Hàm tạo server gốc của Node.js
import { initializeSocket } from './socket.js'; // Hàm ta vừa viết ở file socket.ts
import './services/firebaseService.js';

dotenv.config();

const app = express();

const httpServer = createServer(app); // Tạo HTTP server từ Express app
initializeSocket(httpServer); // Khởi tạo Socket.io với Redis

app.use(helmet());
app.use(cors(getCorsOptions()));
app.use(morgan('dev'));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/notifications', notificationRoutes);

// API kiểm tra trạng thái Server (Health check)
app.get('/', (req, res) => {
    res.send('Welcome to Thread City API! 🚀 Server is running.');
});

const PORT = process.env.PORT || 3000;
httpServer.listen(Number(PORT), '0.0.0.0', () => {
    console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
    console.log(`🔌 Socket.io is ready and connected to Redis`);
});
