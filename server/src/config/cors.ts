const defaultAllowedOrigins = [
    "https://thread-b4d7b.web.app",
    "https://thread-b4d7b.firebaseapp.com",
];

export const getCorsOptions = () => {
    const customOrigins = process.env.CLIENT_URL
        ? process.env.CLIENT_URL.split(',').map((o) => o.trim())
        : [];
    const allowedOrigins = [...defaultAllowedOrigins, ...customOrigins];

    return {
        origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
            if (!origin) {
                return callback(null, true);
            }

            if (process.env.NODE_ENV !== "production") {
                if (
                    origin.startsWith("http://localhost:") ||
                    origin.startsWith("http://127.0.0.1:") ||
                    origin === "http://localhost" ||
                    origin === "http://127.0.0.1"
                ) {
                    return callback(null, true);
                }
            }

            if (allowedOrigins.includes(origin)) {
                return callback(null, true);
            }

            return callback(new Error(`CORS blocked: Origin ${origin} is not allowed`));
        },
        credentials: true,
        methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allowedHeaders: ["Content-Type", "Authorization", "ngrok-skip-browser-warning"],
    };
};
