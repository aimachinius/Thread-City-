import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Start seeding...');

  const user = await prisma.user.upsert({
    where: { email: 'hau@gmail.com' },
    update: {},
    create: {
      username: 'thanh_hau',
      email: 'hau@gmail.com',
      password_hash: 'hashed_password_here',
      bio: 'Senior Backend & Flutter Developer',
      avatar_url: 'https://i.pravatar.cc/150?u=1',
    },
  });

  await prisma.post.create({
    data: {
      user_id: user.id,
      content: 'Chào mừng các bạn đến với Thread City! Hệ thống đã ổn định với Prisma 6.',
      type: 'post',
      counts: {
        create: {
          like_count: 150,
          comment_count: 20,
        }
      }
    },
  });

  console.log('✅ Seeding finished successfully.');
}

main()
  .catch((e) => {
    console.error('❌ Seed Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
