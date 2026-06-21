/**
 * In-memory memory store.
 *
 * ⚠️  Dev-only: data is lost on every backend restart. For production, swap
 * the Maps below for Firestore / Postgres / Redis — the public API stays the
 * same.
 */
const memoryStore = new Map();
const conversationHistory = new Map();

function storeMemory(userId, fact) {
  if (!memoryStore.has(userId)) memoryStore.set(userId, []);
  const memories = memoryStore.get(userId);
  if (!memories.includes(fact)) {
    memories.push(fact);
    if (memories.length > 50) memories.shift();
  }
}

function getRecentMemories(userId) {
  return (memoryStore.get(userId) || []).slice(-15);
}

function processUserMessage(userId, content) {
  const fact = extractFact(content);
  if (fact) storeMemory(userId, fact);
  if (!conversationHistory.has(userId)) conversationHistory.set(userId, []);
  const history = conversationHistory.get(userId);
  history.push({ role: 'user', content, timestamp: Date.now() });
  if (history.length > 20) history.shift();
}

/**
 * Extract a memorable fact from a user message.
 *
 * Bug fix: the previous implementation matched against the lowercased message
 * and captured from that lowercased string, so "My name is Alice" was stored
 * as "User's name is alice". We now match case-insensitively but capture
 * from the ORIGINAL message so names and proper nouns keep their case.
 */
function extractFact(message) {
  const patterns = [
    { pattern: /my name is (\w+)/i, template: (m) => `User's name is ${m[1]}` },
    { pattern: /i (?:like|love) (.+?)(?:\.|!|$)/i, template: (m) => `User likes ${m[1]}` },
    { pattern: /i (?:hate|dislike) (.+?)(?:\.|!|$)/i, template: (m) => `User dislikes ${m[1]}` },
    { pattern: /my (?:favorite|fav) (.+?) is (.+?)(?:\.|!|$)/i, template: (m) => `User's favorite ${m[1]} is ${m[2]}` },
  ];
  for (const { pattern, template } of patterns) {
    const match = message.match(pattern); // match against ORIGINAL message
    if (match) return template(match);
  }
  return null;
}

module.exports = { storeMemory, getRecentMemories, processUserMessage, extractFact };
