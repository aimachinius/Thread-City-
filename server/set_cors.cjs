const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "thread-b4d7b.firebasestorage.app"
});

const bucket = admin.storage().bucket();
const corsConfiguration = [
  {
    origin: ["*"],
    method: ["GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS"],
    maxAgeSeconds: 3600,
    responseHeader: ["*"]
  }
];

bucket.setCorsConfiguration(corsConfiguration)
  .then(() => {
    console.log("CORS configuration successfully updated.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error setting CORS configuration:", error);
    process.exit(1);
  });
