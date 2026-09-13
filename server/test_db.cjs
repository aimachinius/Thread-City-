const { PrismaClient } = require('@prisma/client'); 
const prisma = new PrismaClient(); 
async function main() { 
    const users = await prisma.user.findMany({where: {avatar_url: {not: null}}, take: 1}); 
    console.log('USER:', users[0]?.avatar_url); 
    const posts = await prisma.postMedia.findMany({take: 1}); 
    console.log('POST:', posts[0]?.media_url); 
} 
main().catch(console.error).finally(()=>prisma.$disconnect());
