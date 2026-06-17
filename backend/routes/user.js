const express = require('express');
const router = express.Router();

// In-memory store for FCM tokens. Production: Save to PostgreSQL/MongoDB
const fcmTokens = new Map();

// POST /api/user/fcm-token — Register a device token for push notifications
router.post('/fcm-token', (req, res) => {
  const { token } = req.body;
  const userId = req.userId;
  
  if (!token) return res.status(400).json({ error: 'Token required' });
  
  fcmTokens.set(userId, token);
  console.log(`✅ FCM Token registered for user: ${userId}`);
  res.json({ status: 'ok' });
});

module.exports = { router, fcmTokens };
