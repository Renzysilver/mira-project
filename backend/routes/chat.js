const express = require('express');
const router = express.Router();
const { streamChatResponse } = require('../services/groqService');
const { processUserMessage } = require('../services/memoryService');

const MAX_MESSAGE_LEN = 4000;

router.post('/send', async (req, res) => {
  try {
    const { message, persona } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message (string) is required' });
    }
    if (message.length > MAX_MESSAGE_LEN) {
      return res.status(413).json({
        error: `Message too long — max ${MAX_MESSAGE_LEN} characters`,
      });
    }

    const userId = req.userId;
    processUserMessage(userId, message);
    const stream = await streamChatResponse(
      [{ role: 'user', content: message }],
      persona || {},
      userId,
    );

    let fullResponse = '';
    for await (const chunk of stream) {
      fullResponse += chunk.choices[0]?.delta?.content || '';
    }
    res.json({ response: fullResponse });
  } catch (error) {
    console.error('Chat /send error:', error);
    res.status(500).json({ error: 'Failed to generate response' });
  }
});

module.exports = router;
