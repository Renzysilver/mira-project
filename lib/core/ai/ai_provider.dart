import '../../models/message_model.dart';
import '../../models/persona_model.dart';

/// A single chunk of a streamed AI response.
class AiStreamChunk {
  /// The text content delta. Empty string when the stream is done.
  final String delta;

  /// True when this is the final chunk (no more content will arrive).
  final bool done;

  /// Full accumulated response (only populated when [done] is true).
  final String? fullResponse;

  const AiStreamChunk({this.delta = '', this.done = false, this.fullResponse});
}

/// Provider-agnostic AI chat interface.
///
/// Implementations:
/// - [GroqAiProvider] (real, uses Groq's llama-3.1-8b-instant)
/// - OpenAiProvider (stubbed — implements when API key is available)
/// - AnthropicProvider (stubbed)
/// - GeminiProvider (stubbed)
///
/// The active provider is selected by [AiProviderRegistry.active] based
/// on the AI_PROVIDER env var (defaults to 'groq').
///
/// Per-companion scoping: the caller passes the [PersonaModel] which
/// includes name, personality, mood, etc. — the provider uses these
/// to build the system prompt. Memory facts are also passed in so each
/// companion can have its own memory.
abstract class AiProvider {
  /// Provider identifier, e.g. 'groq', 'openai', 'anthropic'.
  String get id;

  /// Human-readable display name.
  String get displayName;

  /// Whether this provider is currently configured (has API key, etc.).
  /// If false, callers should fall back to another provider.
  bool get isAvailable;

  /// Send a non-streaming chat completion request.
  ///
  /// [messages] — conversation history (oldest first).
  /// [persona] — companion persona for system prompt generation.
  /// [memoryFacts] — companion-specific memory facts.
  /// [userName] — optional user name for personalization.
  Future<String> sendMessage({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  });

  /// Send a streaming chat completion request.
  ///
  /// Yields [AiStreamChunk]s as they arrive from the provider. The final
  /// chunk has [AiStreamChunk.done] = true and includes the full response.
  Stream<AiStreamChunk> sendMessageStream({
    required List<MessageModel> messages,
    required PersonaModel persona,
    required List<String> memoryFacts,
    String? userName,
  });
}
