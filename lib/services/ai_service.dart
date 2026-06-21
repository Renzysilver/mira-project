import '../core/ai/ai_provider.dart';
import '../core/ai/ai_provider_registry.dart';
import '../core/utils/logger.dart';
import '../models/message_model.dart';
import '../models/persona_model.dart';

/// Thin facade over the active [AiProvider].
///
/// Existing callers (chat_provider, voice_call_service, etc.) keep using
/// AiService.sendMessage(...) — they don't need to know which provider
/// is active. The provider abstraction lives underneath.
///
/// If you need provider-specific features (e.g. Anthropic's system
/// prompt token, or Gemini's safety settings), call
/// AiProviderRegistry.active directly.
class AiService {
  AiProvider get _provider => AiProviderRegistry.active;

  String get activeProviderId => _provider.id;
  bool get isAvailable => _provider.isAvailable;

  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) async {
    if (!_provider.isAvailable) {
      AppLogger.error(
          'AI provider ${_provider.id} is not available (missing API key?)');
      throw StateError('AI provider not configured');
    }
    return _provider.sendMessage(
      messages: messages,
      persona: persona,
      memoryFacts: memoryFacts,
      userName: userName,
    );
  }

  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  }) {
    if (!_provider.isAvailable) {
      throw StateError('AI provider not configured');
    }
    return _provider.sendMessageStream(
      messages: messages,
      persona: persona,
      memoryFacts: memoryFacts,
      userName: userName,
    );
  }
}
