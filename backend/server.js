const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
require('dotenv').config();

const chatRoutes = require('./routes/chat');
const authRoutes = require('./routes/auth');
const callRoutes = require('./routes/call');
const memoryRoutes = require('./routes/memory');
const { router: userRoutes } = require('./routes/user');
const { verifyFirebaseToken } = require('./middleware/authMiddleware');
const { handleChatSocket } = require('./services/groqService');
const { startProactivityEngine } = require('./services/proactivityService');

const app = express();
const server = http.createServer(app);

// ---------------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------------
// `credentials: true` is incompatible with `origin: '*'` — browsers reject the
// combination. Configure an explicit allow-list via env, falling back to a
// permissive dev setting only when NODE_ENV !== 'production'.
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:8080,http://10.0.2.2:8080')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const corsOptions = {
  origin(origin, cb) {
    // Allow same-origin / curl / mobile clients that don't send an Origin header.
    if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
    return cb(new Error(`CORS blocked origin: ${origin}`));
  },
  credentials: true,
};

const io = new Server(server, {
  cors: { origin: allowedOrigins, methods: ['GET', 'POST'], credentials: true },
});

app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use('/api/', limiter);

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/chat', verifyFirebaseToken, chatRoutes);
app.use('/api/call', verifyFirebaseToken, callRoutes);
app.use('/api/memory', verifyFirebaseToken, memoryRoutes);
app.use('/api/user', verifyFirebaseToken, userRoutes);

// ---------------------------------------------------------------------------
// Socket auth — verify the Firebase ID token, fall back to dev-user only in
// non-production environments. Never trust a raw token as a UID.
// ---------------------------------------------------------------------------
io.use(async (socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('Authentication error: missing token'));

  if (admin.apps.length > 0) {
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      socket.userId = decoded.uid;
      return next();
    } catch (err) {
      return next(new Error('Authentication error: invalid token'));
    }
  }

  // Dev fallback — only when Firebase Admin is not initialised.
  if (process.env.NODE_ENV === 'production') {
    return next(new Error('Authentication error: Firebase Admin not configured'));
  }
  socket.userId = socket.handshake.headers['x-user-id'] || 'dev-user';
  next();
});

io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id} (uid=${socket.userId})`);
  handleChatSocket(io, socket);
  socket.on('disconnect', () => console.log(`Client disconnected: ${socket.id}`));
});

// ---------------------------------------------------------------------------
// Graceful shutdown
// ---------------------------------------------------------------------------
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`✅ Mirabel backend running on port ${PORT}`);
  startProactivityEngine();
});

for (const sig of ['SIGINT', 'SIGTERM']) {
  process.on(sig, () => {
    console.log(`\n${sig} received — shutting down...`);
    server.close(() => {
      io.close(() => {
        console.log('Closed all connections. Bye.');
        process.exit(0);
      });
    });
    // Force-exit if something hangs.
    setTimeout(() => process.exit(1), 10_000).unref();
  });
}
