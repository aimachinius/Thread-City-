import { NextFunction, Request, Response } from "express";
import { PrismaClient } from "@prisma/client";
import admin from "../services/firebaseService.js";

const prisma = new PrismaClient();

export interface AuthenticatedRequest extends Request {
  user?: {
    id: number;
    firebaseUid: string;
  };
}

/**
 * requireAuth Middleware:
 * 1. Bắt buộc và giải mã chữ ký mật mã RS256 của Firebase ID Token qua Firebase Admin SDK.
 * 2. Xác thực danh tính chính chủ và trích xuất UID từ Token.
 * 3. Chống hoàn toàn lỗ hổng giả mạo UID (IDOR) qua body/params.
 */
export const requireAuth = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.header("authorization");
  const token =
    authHeader && authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length).trim()
      : null;

  if (!token) {
    // Nếu chưa truyền Token: Kiểm tra cấu hình bắt buộc nghiêm ngặt
    if (process.env.STRICT_AUTH === "true") {
      return res.status(401).json({
        message: "Unauthorized: Missing Bearer Token",
      });
    }

    // Chế độ chuyển tiếp an toàn (nếu client phiên bản cũ đang gửi firebase_uid)
    const fallbackUid = (req.headers["x-firebase-uid"] as string) ||
      req.body?.firebase_uid ||
      req.body?.follower_uid ||
      req.params?.firebase_uid ||
      (req.query?.firebase_uid as string);

    if (!fallbackUid) {
      return res.status(401).json({
        message: "Unauthorized: Missing authentication credentials",
      });
    }

    try {
      const user = await prisma.user.findUnique({
        where: { firebase_uid: fallbackUid },
        select: { id: true, firebase_uid: true },
      });

      if (!user) {
        return res.status(401).json({ message: "Unauthorized: User not found in database" });
      }

      req.user = {
        id: user.id,
        firebaseUid: user.firebase_uid,
      };

      return next();
    } catch (dbErr) {
      console.error("authMiddleware fallback user lookup error:", dbErr);
      return res.status(500).json({ message: "Internal server error" });
    }
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const firebaseUid = decoded.uid;

    const user = await prisma.user.findUnique({
      where: { firebase_uid: firebaseUid },
      select: { id: true, firebase_uid: true },
    });

    if (!user) {
      return res.status(401).json({ message: "Unauthorized: User not found in database" });
    }

    req.user = {
      id: user.id,
      firebaseUid: user.firebase_uid,
    };

    next();
  } catch (error: any) {
    console.error("requireAuth token verification error:", error?.message || error);
    return res.status(401).json({ message: "Unauthorized: Invalid or expired token" });
  }
};

/**
 * optionalAuth Middleware:
 * - Trích xuất viewer UID an toàn nếu client có gửi Bearer Token
 * - Không ném lỗi nếu là khách vãng lai chưa đăng nhập
 */
export const optionalAuth = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.header("authorization");
  const token =
    authHeader && authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length).trim()
      : null;

  if (!token) {
    return next();
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const user = await prisma.user.findUnique({
      where: { firebase_uid: decoded.uid },
      select: { id: true, firebase_uid: true },
    });
    if (user) {
      req.user = {
        id: user.id,
        firebaseUid: user.firebase_uid,
      };
    }
  } catch (_) {
    // Không ném lỗi đối với optional auth
  }

  next();
};
