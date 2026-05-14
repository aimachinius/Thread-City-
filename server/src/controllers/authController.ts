import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma  = new PrismaClient();
export const register = async (req: Request, res: Response) => {
  try {
    const { firebase_uid, email, username } = req.body;

    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          {firebase_uid},
          {email},
          {username}
        ]
      }
    });
    if (existingUser){
      return res.status(400).json({
        message: 'User này đã tồn tại'
      });
    }
    const newUser = await prisma.user.create({
      data: {
        firebase_uid,
        email,
        username,
        status: 'active'
      }
    });
    return res.status(201).json({
      message: 'Đăng kí thành công',
      user: newUser,
    });
  } 
  
  catch(error) {
    console.error('Lỗi server: ', error);
    return res.status(500).json({
      message: "Internal server error"
    });
  }
};

export const login = async (req: Request, res: Response) => {
  // Logic login của server (nếu cần sinh JWT)
};

export const getUserByUid = async (req: Request, res: Response) => {
  try {
    const { uid } = req.params;

    if (!uid) {
      return res.status(400).json({ message: "UID is required" });
    }

    const user = await prisma.user.findFirst({
      where: { firebase_uid: uid as string }
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.json(user);
  } catch (error) {
    console.error("Lỗi getUserByUid:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};