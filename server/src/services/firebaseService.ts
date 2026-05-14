import * as admin from 'firebase-admin';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const serviceAccountPath = path.join(__dirname, '../../serviceAccountKey.json');

try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
        databaseURL: "https://thread-b4d7b-default-rtdb.firebaseio.com" // Thay bằng URL của bạn
    });
    console.log('🔥 Firebase Admin initialized');
} catch (error) {
    console.warn('⚠️ Firebase Admin chưa thể khởi tạo (Thiếu file serviceAccountKey.json)');
}

export const messaging = admin.messaging();
export const rtdb = admin.database();
export default admin;
