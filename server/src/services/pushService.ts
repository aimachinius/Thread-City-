import { PrismaClient } from "@prisma/client";
import { messaging } from "./firebaseService.js";

const prisma = new PrismaClient();

export const sendPushToUser = async ({
  userId,
  title,
  body,
  data,
}: {
  userId: number;
  title: string;
  body: string;
  data?: Record<string, string>;
}) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcm_token: true },
  });

  if (!user?.fcm_token) return;

  try {
    await messaging.send({
      token: user.fcm_token,
      notification: { title, body },
      data,
    });
  } catch (error) {
    console.warn("FCM send failed:", error);
  }
};
