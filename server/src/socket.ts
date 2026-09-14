import { Server } from "socket.io";
// adapter de ket noi docket.io voi redis
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from "ioredis";
import { Server as HttpServer } from 'http';
import { PrismaClient } from "@prisma/client";
import admin from "./services/firebaseService.js";
import { getCorsOptions } from './config/cors.js';


let io: Server;
const prisma = new PrismaClient();

export const initializeSocket = (httpServer: HttpServer) => {
    io = new Server(httpServer, {
        cors: getCorsOptions(),
    });


    const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
    // publish & subcribe 
    const pubClient = new Redis(redisUrl, {
        maxRetriesPerRequest: null,
        retryStrategy: (times) => Math.min(times * 200, 5000), // Tăng dần, tối đa 5s
    });
    const subClient = pubClient.duplicate();

    pubClient.on('connect', () => console.log(`🔌 Redis pubClient connected to: ${redisUrl}`));
    subClient.on('connect', () => console.log('🔌 Redis subClient connected'));

    pubClient.on('error', (err) => console.error('❌ Redis pubClient error:', err.message));
    subClient.on('error', (err) => console.error('❌ Redis subClient error:', err.message));

    io.adapter(createAdapter(pubClient, subClient));//

    io.on('connection', async (socket) => {
        try {
            const idToken = socket.handshake.auth?.token as string | undefined;
            if (!idToken) {
                socket.emit("auth_error", { message: "Missing token for socket auth" });
                socket.disconnect();
                return;
            }

            const decoded = await admin.auth().verifyIdToken(idToken);
            const firebaseUid = decoded.uid;
            const user = await prisma.user.findUnique({
                where: { firebase_uid: firebaseUid },
                select: { id: true }
            });

            if (!user) {
                socket.emit("auth_error", { message: "Unauthorized socket user" });
                socket.disconnect();
                return;
            }

            console.log(`🔌 Client connected: ${socket.id}`);
            socket.join(`user_${user.id}`);
            io.emit('user_status', { userId: user.id, isOnline: true });
            socket.on('join_conversation', async (conversationId) => {
                const parsedConversationId = Number(conversationId);
                if (Number.isNaN(parsedConversationId)) return;

                const conversation = await prisma.conversation.findUnique({
                    where: { id: parsedConversationId },
                    select: { user1_id: true, user2_id: true }
                });
                if (!conversation) return;
                if (conversation.user1_id !== user.id && conversation.user2_id !== user.id) {
                    socket.emit("auth_error", { message: "Not allowed to join this room" });
                    return;
                }

                socket.join(`conversation_${parsedConversationId}`);
                console.log(`User ${socket.id} joined room: conversation_${parsedConversationId}`);
            });
            socket.on('typing', ({ conversationId }) => {
                socket.to(`conversation_${conversationId}`).emit('user_typing', { conversationId, userId: user.id });
            });
            socket.on('stop_typing', ({ conversationId }) => {
                socket.to(`conversation_${conversationId}`).emit('user_stop_typing', { conversationId, userId: user.id });
            });
            socket.on('disconnect', async () => {
                console.log(`🛑 Client disconnected: ${socket.id}`);
                const sockets = await io.in(`user_${user.id}`).fetchSockets();
                if (sockets.length === 0) {
                    io.emit('user_status', { userId: user.id, isOnline: false });
                }
            });
        } catch (error) {
            socket.emit("auth_error", { message: "Socket authentication failed" });
            socket.disconnect();
        }
    })
    return io;
};

export const getIO = () => {
    if (!io) {
        throw new Error('Socket.io is not initialized!');
    }
    return io;
};
