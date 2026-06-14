const express = require('express');
const router = express.Router();
const { ElevenLabsClient } = require('elevenlabs');

const client = new ElevenLabsClient({ apiKey: process.env.ELEVENLABS_API_KEY });

// Rachel voice ID (warm, natural female voice)
const VOICE_ID = '21m00Tcm4TlvDq8ikWAM'; 

router.post('/tts', async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: 'Text required' });

    const audioStream = await client.generate({
      voice: VOICE_ID,
      model_id: 'eleven_multilingual_v2',
      text: text,
      voice_settings: { stability: 0.5, similarity_boost: 0.8, style: 0.6, use_speaker_boost: true },
    });

    res.setHeader('Content-Type', 'audio/mpeg');
    audioStream.pipe(res);
  } catch (error) {
    console.error('ElevenLabs TTS error:', error);
    res.status(500).json({ error: 'Failed to generate speech' });
  }
});

module.exports = router;
