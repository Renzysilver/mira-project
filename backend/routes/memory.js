const express = require('express');
const router = express.Router();
const { getRecentMemories, storeMemory } = require('../services/memoryService');

router.get('/', (req, res) => {
  const memories = getRecentMemories(req.userId);
  res.json({ memories });
});

router.post('/', (req, res) => {
  const { fact } = req.body;
  if (!fact) return res.status(400).json({ error: 'Fact required' });
  storeMemory(req.userId, fact);
  res.json({ status: 'ok' });
});
module.exports = router;
