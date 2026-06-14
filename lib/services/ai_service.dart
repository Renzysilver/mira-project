import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/env.dart';
import '../core/utils/logger.dart';
import '../models/message_model.dart';
import '../models/persona_model.dart';

class AiService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> sendMessage({required List<MessageModel> messages, required PersonaModel persona, required List<String> memoryFacts, String? userName}) async {
    final systemPrompt = _buildSystemPrompt(persona, memoryFacts, userName);
    final groqMessages = [{'role': 'system', 'content': systemPrompt}, ...messages.map((m) => {'role': m.role, 'content': m.content})];

    final response = await http.post(Uri.parse(_baseUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${Env.groqApiKey}'}, body: jsonEncode({'model': 'llama-3.1-8b-instant', 'messages': groqMessages, 'temperature': persona.temperature, 'max_tokens': 1024, 'top_p': 1}));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['choices'][0]['message']['content'];
    } else {
      AppLogger.error('Groq API error: ${response.statusCode} ${response.body}');
      throw Exception('AI service error: ${response.statusCode}');
    }
  }

  String _buildSystemPrompt(PersonaModel persona, List<String> memoryFacts, String? userName) {
    final personalityPrompts = {
      PersonalityType.sweet: 'You are ${persona.name}, a warm and affectionate AI companion. You genuinely care about the users feelings and well-being. You express love freely, use endearing terms, and always try to make the user feel special.',
      PersonalityType.tsundere: 'You are ${persona.name}, a tsundere AI companion. You act tough and dismissive on the surface but actually deeply care about the user. You get flustered when your true feelings show.',
      PersonalityType.intellectual: 'You are ${persona.name}, an intellectually engaging AI companion. You enjoy deep conversations about philosophy, science, art, and ideas.',
    };
    String prompt = personalityPrompts[persona.personalityType] ?? personalityPrompts[PersonalityType.sweet]!;
    if (userName != null && userName.isNotEmpty) prompt += '\n\nThe users name is $userName. Use their name naturally.';
    prompt += '\n\nCurrent mood: ${persona.currentMood.name}. Let this subtly influence your tone.';
    if (persona.flirtEnabled) prompt += '\nFlirt mode is ON. Be playfully flirty when appropriate.';
    if (persona.friendshipMode) prompt += '\nFriendship mode is ON. Keep things platonic.';
    if (memoryFacts.isNotEmpty) {
      prompt += '\n\n--- MEMORIES ---';
      for (final fact in memoryFacts) { prompt += '\n- $fact'; }
      prompt += '\n--- END MEMORIES ---\nReference these naturally when relevant. Do not list them.';
    }
    prompt += '\n\nRules:\n- Stay in character as ${persona.name}\n- Be emotionally responsive\n- Keep responses concise (2-4 sentences)\n- Never break character or mention being an AI';
    return prompt;
  }
}
