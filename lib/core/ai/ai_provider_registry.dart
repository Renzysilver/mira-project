import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'groq_ai_provider.dart';
import 'stub_providers.dart';
import 'ai_provider.dart';

/// Registry that picks the active AI provider based on the AI_PROVIDER
/// env var (defaults to 'groq').
///
/// Usage:
///   final provider = AiProviderRegistry.active;
///   final response = await provider.sendMessage(messages: [...], ...);
///
/// To switch providers, set AI_PROVIDER=openai in .env and add the
/// corresponding API key. The registry will pick the new provider on
/// next app start.
class AiProviderRegistry {
  AiProviderRegistry._();

  static final GroqAiProvider _groq = GroqAiProvider();
  static final OpenAiProvider _openai = OpenAiProvider();
  static final AnthropicProvider _anthropic = AnthropicProvider();
  static final GeminiProvider _gemini = GeminiProvider();

  /// All registered providers, keyed by id.
  static Map<String, AiProvider> get all => {
        'groq': _groq,
        'openai': _openai,
        'anthropic': _anthropic,
        'gemini': _gemini,
      };

  /// The provider id selected via the AI_PROVIDER env var.
  /// Falls back to 'groq' if unset or invalid.
  static String get activeId {
    final id = dotenv.env['AI_PROVIDER'] ?? 'groq';
    if (!all.containsKey(id)) {
      // Unknown provider id — fall back to groq rather than crash.
      return 'groq';
    }
    return id;
  }

  /// The currently active provider instance.
  static AiProvider get active => all[activeId]!;

  /// True if the active provider is configured and ready to use.
  static bool get isActiveAvailable => active.isAvailable;
}
