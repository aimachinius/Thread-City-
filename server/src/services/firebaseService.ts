import { initializeApp, cert, getApps, getApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getDatabase } from 'firebase-admin/database';
import { getAuth } from 'firebase-admin/auth';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const serviceAccountPath = path.join(__dirname, '../../serviceAccountKey.json');

let app;
try {
    if (getApps().length === 0) {
        const renderSecretPath = '/etc/secrets/serviceAccountKey.json';

        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            // Trường hợp 1: Truyền JSON qua biến môi trường trên Cloud
            const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
            app = initializeApp({
                credential: cert(serviceAccount),
                databaseURL: "https://thread-b4d7b-default-rtdb.firebaseio.com"
            });
            console.log('🔥 Firebase Admin initialized via FIREBASE_SERVICE_ACCOUNT env');
        } else if (fs.existsSync(serviceAccountPath)) {
            // Trường hợp 2: Chạy file local trên máy
            app = initializeApp({
                credential: cert(serviceAccountPath),
                databaseURL: "https://thread-b4d7b-default-rtdb.firebaseio.com"
            });
            console.log('🔥 Firebase Admin initialized via local file');
        } else if (fs.existsSync(renderSecretPath)) {
            // Trường hợp 3: Dùng Secret File của Render
            app = initializeApp({
                credential: cert(renderSecretPath),
                databaseURL: "https://thread-b4d7b-default-rtdb.firebaseio.com"
            });
            console.log('🔥 Firebase Admin initialized via Render secret file');
        } else {
            console.warn('⚠️ File serviceAccountKey.json không tồn tại!');
        }
    } else {
        app = getApp();
    }
} catch (error) {
    console.warn('⚠️ Firebase Admin chưa thể khởi tạo:', error);
}


export const messaging = app ? getMessaging(app) : null as any;
export const rtdb = app ? getDatabase(app) : null as any;
export const auth = app ? getAuth(app) : null as any;

export default {
    messaging: () => messaging,
    database: () => rtdb,
    auth: () => auth,
};
