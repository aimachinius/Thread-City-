import { Request, Response } from "express";
import { PrismaClient } from "@prisma/client";

const prisma  = new PrismaClient();

/** Chuyển chuỗi có dấu tiếng Việt thành không dấu ASCII */
function removeVietnameseTones(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')  // Bỏ dấu
    .replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .replace(/[^a-zA-Z0-9]/g, '')    // Bỏ space và ký tự đặc biệt
    .toLowerCase()
    .slice(0, 25);                    // Tối đa 25 ký để còn chỗ suffix
}

/** Tạo username unique từ nickname, thêm suffix ngẫu nhiên nếu trùng */
async function generateUniqueUsername(base: string): Promise<string> {
  const cleaned = removeVietnameseTones(base) || 'user';
  let candidate = cleaned;

  const exists = await prisma.user.findFirst({ where: { username: candidate } });
  if (!exists) return candidate;

  // Thêm suffix 4 ký tự ngẫu nhiên
  const suffix = Math.random().toString(36).slice(2, 6);
  return `${cleaned}_${suffix}`;
}

export const register = async (req: Request, res: Response) => {
  try {
    const { firebase_uid, email, username: rawUsername, nickname } = req.body;

    // Ưu tiên nickname để sinh username, fallback sang rawUsername cũ
    const displayName = nickname || rawUsername || email?.split('@')[0] || 'user';
    const username = nickname
      ? await generateUniqueUsername(displayName)
      : rawUsername;

    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { firebase_uid },
          { email },
        ]
      }
    });

    if (existingUser) {
      // Nếu user đã tồn tại (ví dụ Google re-login), trả về user hiện tại thay vì lỗi
      return res.status(200).json({
        message: 'User đã tồn tại',
        user: { ...existingUser, password_hash: undefined },
      });
    }

    const newUser = await prisma.user.create({
      data: {
        firebase_uid,
        email,
        username,
        nickname: displayName,  // Lưu nickname hiển thị
        status: 'active'
      }
    });

    return res.status(201).json({
      message: 'Đăng kí thành công',
      user: { ...newUser, password_hash: undefined },
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