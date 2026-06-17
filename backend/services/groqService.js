const Groq = require('groq-sdk');
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const { buildSystemPrompt } = require('./personalityService');
const { getRecentMemories } = require('./memoryService');

async function streamChatResponse(messages, persona, userId) {
  const recentMemories = await getRecentMemories(userId);
  const systemPrompt = buildSystemPrompt(persona, recentMemories);
  const groqMessages = [
    { role: 'system', content: systemPrompt },
    ...messages.map((m) => ({ role: m.role, content: m.content })),
  ];
  return await groq.chat.completions.create({
    model: 'llama-3.1-8b-instant',
    messages: groqMessages,
    temperature: persona.temperature || 0.8,
    max_tokens: 1024,
    top_p: 1,
    stream: true,
  });
}

function handleChatSocket(io, socket) {
  socket.on('chat:message', async (data) => {
    const { messages, persona, userId } = data;
    try {
      socket.emit('chat:typing', true);
      const stream = await streamChatResponse(messages, persona, userId || socket.userId);
      let fullResponse = '';
      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content || '';
        if (content) {
          fullResponse += content;
          socket.emit('chat:stream', { token: content, done: false });
        }
      }
      socket.emit('chat:stream', { token: '', done: true, fullResponse });
      socket.emit('chat:typing', false);
    } catch (error) {
      console.error('Groq stream error:', error);
      socket.emit('chat:error', { message: 'Failed to generate response' });
      socket.emit('chat:typing', false);
    }
  });
}
module.exports = { streamChatResponse, handleChatSocket };
