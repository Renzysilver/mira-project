const express = require('express');
const router = express.Router();
const { streamChatResponse } = require('../services/groqService');
const { processUserMessage } = require('../services/memoryService');

router.post('/send', async (req, res) => {
  try {
    const { message, persona } = req.body;
    const userId = req.userId;
    processUserMessage(userId, message);
    const stream = await streamChatResponse([{ role: 'user', content: message }], persona || {}, userId);
    let fullResponse = '';
    for await (const chunk of stream) { fullResponse += chunk.choices[0]?.delta?.content || ''; }
    res.json({ response: fullResponse });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate response' });
  }
});
module.exports = router;
