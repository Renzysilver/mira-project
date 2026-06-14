const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const chatRoutes = require('./routes/chat');
const authRoutes = require('./routes/auth');
const callRoutes = require('./routes/call');
const voiceRoutes = require('./routes/voice');
const memoryRoutes = require('./routes/memory');
const { verifyFirebaseToken } = require('./middleware/authMiddleware');
const { handleChatSocket } = require('./services/groqService');
const { router: userRoutes } = require('./routes/user');
const { startProactivityEngine } = require('./services/proactivityService');

const app = express();
const server = http.createServer(app);

const io = new Server(server, { cors: { origin: '*', methods: ['GET', 'POST'] } });

app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(morgan('combined'));

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use('/api/', limiter);

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/chat', verifyFirebaseToken, chatRoutes);
app.use('/api/call', verifyFirebaseToken, callRoutes);
app.use('/api/voice', verifyFirebaseToken, voiceRoutes);
app.use('/api/memory', verifyFirebaseToken, memoryRoutes);
app.use('/api/user', verifyFirebaseToken, userRoutes); // New route

io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('Authentication error'));
  socket.userId = token;
  next();
});

io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);
  handleChatSocket(io, socket);
  socket.on('disconnect', () => console.log(`Client disconnected: ${socket.id}`));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`✅ Mira backend running on port ${PORT}`);
  startProactivityEngine(); // Start the cron job
});
