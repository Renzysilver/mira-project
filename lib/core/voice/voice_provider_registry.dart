import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'groq_orpheus_voice_provider.dart';
import 'stub_providers.dart';
import 'voice_provider.dart';

/// Registry that picks the active voice (TTS) provider based on the
/// VOICE_PROVIDER env var (defaults to 'groq').
///
/// Usage:
///   final provider = VoiceProviderRegistry.active;
///   await provider.speak(text: '...', voiceId: 'hannah');
///
/// Per-companion voice identity: each companion stores its own
/// `voiceProvider` and `voiceId` in the companions table. The caller
/// should read these from the companion model and pass them to the
/// appropriate provider. For now, all companions use the active
/// provider's default voice.
class VoiceProviderRegistry {
  VoiceProviderRegistry._();

  static final GroqOrpheusVoiceProvider _groq = GroqOrpheusVoiceProvider();
  static final ElevenLabsVoiceProvider _elevenlabs = ElevenLabsVoiceProvider();
  static final CartesiaVoiceProvider _cartesia = CartesiaVoiceProvider();
  static final AzureVoiceProvider _azure = AzureVoiceProvider();

  static Map<String, VoiceProvider> get all => {
        'groq': _groq,
        'elevenlabs': _elevenlabs,
        'cartesia': _cartesia,
        'azure': _azure,
      };

  static String get activeId {
    final id = dotenv.env['VOICE_PROVIDER'] ?? 'groq';
    if (!all.containsKey(id)) return 'groq';
    return id;
  }

  static VoiceProvider get active => all[activeId]!;

  static bool get isActiveAvailable => active.isAvailable;
}
