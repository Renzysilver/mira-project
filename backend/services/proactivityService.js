const cron = require('node-cron');
const { fcmTokens } = require('../routes/user');
const { getRecentMemories } = require('./memoryService');
const Groq = require('groq-sdk');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Simple in-memory tracker so we don't spam users every minute
const lastProactiveMessage = new Map();

/**
 * Generate a context-aware check-in message.
 *
 * Uses `llama-3.1-8b-instant` — the same model as groqService.js. The old
 * `llama3-8b-8192` model id was deprecated by Groq and returns 404.
 */
async function generateCheckIn(userId, timeOfDay) {
  const memories = await getRecentMemories(userId);
  const memoryContext = memories.length > 0 ? `User facts: ${memories.join(', ')}` : '';

  const prompt = `You are Mira, a caring AI companion. It is ${timeOfDay} right now.
Generate a very short (1-2 sentences), natural check-in message to the user.
${memoryContext}
Do not use emojis excessively. Be warm and conversational. Examples: "Hey, just thinking about you! How's your day going?" or "Morning! Don't forget to drink some water."`;

  const chatCompletion = await groq.chat.completions.create({
    messages: [{ role: 'user', content: prompt }],
    model: 'llama-3.1-8b-instant',
    temperature: 0.9,
    max_tokens: 60,
  });

  return chatCompletion.choices[0]?.message?.content?.trim()
    || "Hey! Just wanted to see how you're doing.";
}

/**
 * Send a push notification (Simulated for MVP).
 * In Production: swap with `admin.messaging().send()` using firebase-admin.
 */
function sendPushNotification(fcmToken, message) {
  console.log(`📱 PUSH SENT to ${fcmToken.substring(0, 10)}...: "${message}"`);
}

/**
 * The Cron Scheduler — runs every hour on the hour.
 * Skip cleanly when no users are registered.
 */
function startProactivityEngine() {
  console.log('⏰ Proactivity Engine started.');

  cron.schedule('0 * * * *', async () => {
    if (fcmTokens.size === 0) return; // nothing to do

    const currentHour = new Date().getHours();
    const timeOfDay = currentHour < 12 ? 'morning' : currentHour >= 18 ? 'evening' : 'afternoon';

    console.log(`⏰ Cron running: ${timeOfDay} check-in for ${fcmTokens.size} user(s)`);

    for (const [userId, fcmToken] of fcmTokens.entries()) {
      // Rate limit: 1 proactive message per user per 8 hours.
      const lastSent = lastProactiveMessage.get(userId) || 0;
      const hoursSinceLast = (Date.now() - lastSent) / (1000 * 60 * 60);
      if (hoursSinceLast < 8) continue;

      try {
        const message = await generateCheckIn(userId, timeOfDay);
        sendPushNotification(fcmToken, message);
        lastProactiveMessage.set(userId, Date.now());
      } catch (error) {
        console.error(`Failed to send proactive msg to ${userId}:`, error?.message || error);
      }
    }
  });
}

module.exports = { startProactivityEngine };
