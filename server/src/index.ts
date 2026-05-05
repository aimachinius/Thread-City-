import express from 'express';
import { PrismaClient } from '@prisma/client';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import * as dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();
const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// API kiểm tra trạng thái Server (Health check)
app.get('/', (req, res) => {
    res.send('Welcome to Thread City API! 🚀 Server is running.');
});

// API lấy danh sách bài viết (Feed) dùng ORM
app.get('/api/posts', async (req, res) => {
    try {
        const posts = await prisma.post.findMany({
            where: { parent_id: null },
            include: {
                user: {
                    select: {
                        id: true,
                        username: true,
                        avatar_url: true,
                    }
                },
                counts: true,
            },
            orderBy: { created_at: 'desc' },
            take: 20,
        });

        res.json(posts);
    } catch (error) {
        console.error('API Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server is running on http://localhost:${PORT}`);
});
