const express = require('express');
const router = express.Router();
const { generateAgoraToken } = require('../services/tokenService');

router.post('/token', (req, res) => {
  try {
    const { channelName } = req.body;
    if (!channelName) return res.status(400).json({ error: 'Channel name required' });
    const uid = Math.floor(Math.random() * 100000);
    const token = generateAgoraToken(channelName, uid);
    res.json({ token, uid, channelName, appId: process.env.AGORA_APP_ID });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate call token' });
  }
});
module.exports = router;
