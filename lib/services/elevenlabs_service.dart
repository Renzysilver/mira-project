import '../core/voice/voice_provider.dart';
import '../core/voice/voice_provider_registry.dart';

/// Thin facade over the active [VoiceProvider].
///
/// The class name is preserved for backwards compatibility —
/// voice_call_service.dart and other callers keep using
/// ElevenLabsService.speak(...) without modification. Under the hood,
/// the call is delegated to whatever VoiceProvider is active
/// (Groq Orpheus by default; could be ElevenLabs, Cartesia, or Azure
/// if you set VOICE_PROVIDER in .env).
///
/// When you're ready to support per-companion voice identity, replace
/// the hardcoded 'hannah' voiceId with a value read from the active
/// companion model (companion.voiceId).
class ElevenLabsService {
  VoiceProvider get _provider => VoiceProviderRegistry.active;

  String get activeProviderId => _provider.id;
  bool get isAvailable => _provider.isAvailable;
  List<VoiceOption> get availableVoices => _provider.availableVoices;

  /// Default voice ID for the active provider. Used when the caller
  /// doesn't specify one. For Groq Orpheus, this is 'hannah'.
  String get _defaultVoiceId {
    final voices = _provider.availableVoices;
    return voices.isNotEmpty ? voices.first.id : 'hannah';
  }

  /// Synthesize and play [text]. Returns true on success, false on any
  /// failure. Callers MUST check the return value.
  Future<bool> speak(String text) {
    return _provider.speak(text: text, voiceId: _defaultVoiceId);
  }

  Future<void> stop() => _provider.stop();

  void dispose() => _provider.dispose();
}
