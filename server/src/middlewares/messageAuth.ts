import { NextFunction, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import admin from "../services/firebaseService.js";

const prisma = new PrismaClient();

export type MessageAuthedRequest = Request & {
  messageAuth?: {
    userId: number;
    firebaseUid: string;
  };
};

export const messageAuth = async (
  req: MessageAuthedRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.header("authorization");
  const token =
    authHeader && authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length).trim()
      : null;

  if (!token) {
    return res.status(401).json({
      message: "Unauthorized: missing bearer token",
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const firebaseUid = decoded.uid;

    const user = await prisma.user.findUnique({
      where: { firebase_uid: firebaseUid },
      select: { id: true, firebase_uid: true },
    });

    if (!user) {
      return res.status(401).json({ message: "Unauthorized user" });
    }

    req.messageAuth = {
      userId: user.id,
      firebaseUid: user.firebase_uid,
    };

    next();
  } catch (error) {
    console.error("messageAuth middleware error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};
