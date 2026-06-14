const cron = require('node-cron');
const { fcmTokens } = require('../routes/user');
const { getRecentMemories } = require('./memoryService');
const Groq = require('groq-sdk');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

// Simple in-memory tracker so we don't spam users every minute
const lastProactiveMessage = new Map();

/**
 * Generate a context-aware check-in message
 */
async function generateCheckIn(userId, timeOfDay) {
  const memories = await getRecentMemories(userId);
  const memoryContext = memories.length > 0 ? `User facts: ${memories.join(', ')}` : '';
  
  let prompt = `You are Mira, a caring AI companion. It is ${timeOfDay} right now. 
Generate a very short (1-2 sentences), natural check-in message to the user. 
 ${memoryContext}
Do not use emojis excessively. Be warm and conversational. Examples: "Hey, just thinking about you! How's your day going?" or "Morning! Don't forget to drink some water."`;

  const chatCompletion = await groq.chat.completions.create({
    messages: [{ role: 'user', content: prompt }],
    model: 'llama3-8b-8192',
    temperature: 0.9,
    max_tokens: 60,
  });

  return chatCompletion.choices[0]?.message?.content?.trim() || "Hey! Just wanted to see how you're doing.";
}

/**
 * Send a push notification (Simulated for MVP)
 * In Production: Swap this with admin.messaging().send() using firebase-admin
 */
function sendPushNotification(fcmToken, message) {
  // For MVP, we just log it. The Flutter app will also poll this via an API.
  // To send real push notifications, initialize firebase-admin on the server.
  console.log(`📱 PUSH SENT to ${fcmToken.substring(0, 10)}...: "${message}"`);
}

/**
 * The Cron Scheduler
 */
function startProactivityEngine() {
  console.log('⏰ Proactivity Engine started.');

  // Run every hour at minute 0
  cron.schedule('0 * * * *', async () => {
    const currentHour = new Date().getHours();
    let timeOfDay = 'afternoon';
    if (currentHour < 12) timeOfDay = 'morning';
    else if (currentHour >= 18) timeOfDay = 'evening';

    console.log(`⏰ Cron running: ${timeOfDay} check-in`);

    // Iterate through all registered users
    for (const [userId, fcmToken] of fcmTokens.entries()) {
      // Rate limit: Only send 1 proactive message every 8 hours
      const lastSent = lastProactiveMessage.get(userId) || 0;
      const hoursSinceLast = (Date.now() - lastSent) / (1000 * 60 * 60);
      
      if (hoursSinceLast < 8) continue; // Skip if we messaged them recently

      try {
        const message = await generateCheckIn(userId, timeOfDay);
        sendPushNotification(fcmToken, message);
        lastProactiveMessage.set(userId, Date.now());
      } catch (error) {
        console.error(`Failed to send proactive msg to ${userId}:`, error);
      }
    }
  });
}

module.exports = { startProactivityEngine };
