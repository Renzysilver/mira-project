import '../../models/message_model.dart';
import '../../models/persona_model.dart';
import 'ai_provider.dart';

/// Stub implementations for AI providers we don't have API keys for yet.
///
/// Each one throws [UnimplementedError] with a helpful message. When you
/// get an API key for one of these, replace the stub with a real
/// implementation that follows the [GroqAiProvider] pattern.
///
/// To activate: set AI_PROVIDER env var to the provider's id
/// (e.g. 'openai', 'anthropic', 'gemini') and add the corresponding
/// API key to .env.

class OpenAiProvider implements AiProvider {
  @override
  String get id => 'openai';
  @override
  String get displayName => 'OpenAI (GPT-4)';
  @override
  bool get isAvailable => false; // TODO: read OPENAI_API_KEY from env

  @override
  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError(
          'OpenAI provider not implemented. Add OPENAI_API_KEY to .env and '
          'implement lib/core/ai/openai_provider.dart');

  @override
  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError('OpenAI provider not implemented');
}

class AnthropicProvider implements AiProvider {
  @override
  String get id => 'anthropic';
  @override
  String get displayName => 'Anthropic (Claude)';
  @override
  bool get isAvailable => false;

  @override
  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError(
          'Anthropic provider not implemented. Add ANTHROPIC_API_KEY to .env '
          'and implement lib/core/ai/anthropic_provider.dart');

  @override
  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError('Anthropic provider not implemented');
}

class GeminiProvider implements AiProvider {
  @override
  String get id => 'gemini';
  @override
  String get displayName => 'Google Gemini';
  @override
  bool get isAvailable => false;

  @override
  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError(
          'Gemini provider not implemented. Add GEMINI_API_KEY to .env and '
          'implement lib/core/ai/gemini_provider.dart');

  @override
  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) =>
      throw UnimplementedError('Gemini provider not implemented');
}
