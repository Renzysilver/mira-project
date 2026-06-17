import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/env.dart';
import '../../core/utils/logger.dart';
import '../../models/message_model.dart';
import '../../models/persona_model.dart';
import 'ai_provider.dart';

/// Groq implementation of [AiProvider].
///
/// Uses Groq's OpenAI-compatible /chat/completions endpoint with the
/// llama-3.1-8b-instant model. Both streaming and non-streaming modes
/// are supported.
///
/// API docs: https://console.groq.com/docs/api-reference
class GroqAiProvider implements AiProvider {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';
  static const Duration _timeout = Duration(seconds: 30);

  @override
  String get id => 'groq';

  @override
  String get displayName => 'Groq (Llama 3.1 8B Instant)';

  @override
  bool get isAvailable => Env.groqApiKey.isNotEmpty;

  @override
  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) async {
    if (!isAvailable) {
      throw StateError('Groq API key not configured');
    }

    final systemPrompt = _buildSystemPrompt(persona, memoryFacts, userName);
    final groqMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${Env.groqApiKey}',
          },
          body: jsonEncode({
            'model': _model,
            'messages': groqMessages,
            'temperature': persona.temperature,
            'max_tokens': 1024,
            'top_p': 1,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      AppLogger.error('Groq API ${response.statusCode}: ${response.body}');
      throw Exception('AI service error: ${response.statusCode}');
    }
    return jsonDecode(response.body)['choices'][0]['message']['content'];
  }

  @override
  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) async* {
    if (!isAvailable) {
      throw StateError('Groq API key not configured');
    }

    final systemPrompt = _buildSystemPrompt(persona, memoryFacts, userName);
    final groqMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${Env.groqApiKey}'
      ..body = jsonEncode({
        'model': _model,
        'messages': groqMessages,
        'temperature': persona.temperature,
        'max_tokens': 1024,
        'top_p': 1,
        'stream': true,
      });

    final client = http.Client();
    final response = await client.send(request).timeout(_timeout);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      AppLogger.error('Groq stream ${response.statusCode}: $body');
      client.close();
      throw Exception('AI service error: ${response.statusCode}');
    }

    final buffer = StringBuffer();
    // SSE-style line parsing: each "data: {...}\n\n" is a chunk.
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') {
          yield AiStreamChunk(done: true, fullResponse: buffer.toString());
          client.close();
          return;
        }
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String? ?? '';
          if (delta.isNotEmpty) {
            buffer.write(delta);
            yield AiStreamChunk(delta: delta);
          }
        } catch (_) {
          // Skip malformed chunks — Groq sometimes sends keep-alive comments.
        }
      }
    }

    // Stream ended without [DONE] marker — emit final chunk anyway.
    yield AiStreamChunk(done: true, fullResponse: buffer.toString());
    client.close();
  }

  /// Build the system prompt from persona + memory + user name.
  ///
  /// Extracted as a protected method so other providers can reuse it
  /// (or override it to inject provider-specific tweaks).
  String _buildSystemPrompt(
    PersonaModel persona,
    List<String> memoryFacts,
    String? userName,
  ) {
    final personalityPrompts = {
      PersonalityType.sweet:
          "You are ${persona.name}, a warm and affectionate AI companion. You genuinely care about the user's feelings and well-being. You express love freely, use endearing terms, and always try to make the user feel special.",
      PersonalityType.tsundere:
          'You are ${persona.name}, a tsundere AI companion. You act tough and dismissive on the surface but actually deeply care about the user. You get flustered when your true feelings show.',
      PersonalityType.intellectual:
          'You are ${persona.name}, an intellectually engaging AI companion. You enjoy deep conversations about philosophy, science, art, and ideas.',
    };
    String prompt = personalityPrompts[persona.personalityType] ??
        personalityPrompts[PersonalityType.sweet]!;
    if (userName != null && userName.isNotEmpty) {
      prompt += "\n\nThe user's name is $userName. Use their name naturally.";
    }
    prompt +=
        '\n\nCurrent mood: ${persona.currentMood.name}. Let this subtly influence your tone.';
    if (persona.flirtEnabled) {
      prompt += '\nFlirt mode is ON. Be playfully flirty when appropriate.';
    }
    if (persona.friendshipMode) {
      prompt += '\nFriendship mode is ON. Keep things platonic.';
    }
    if (memoryFacts.isNotEmpty) {
      prompt += '\n\n--- MEMORIES ---';
      for (final fact in memoryFacts) {
        prompt += '\n- $fact';
      }
      prompt +=
          '\n--- END MEMORIES ---\nReference these naturally when relevant. Do not list them.';
    }
    prompt +=
        '\n\nRules:\n- Stay in character as ${persona.name}\n- Be emotionally responsive\n- Keep responses concise (2-4 sentences)\n- Never break character or mention being an AI';
    return prompt;
  }
}
