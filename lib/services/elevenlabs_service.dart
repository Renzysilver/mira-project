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
/// Per-companion voice identity: the caller can pass a [voiceId]
/// override to speak(). If not provided, falls back to the provider's
/// default voice. The voice_call_service reads the active companion's
/// voiceId from personaProvider and passes it here.
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

  /// Synthesize and play [text] using the given [voiceId].
  ///
  /// If [voiceId] is null or empty, falls back to the provider's
  /// default voice. Callers that want per-companion voice identity
  /// should pass the companion's voiceId here.
  ///
  /// Returns true on success, false on any failure. Callers MUST
  /// check the return value.
  Future<bool> speak(String text, {String? voiceId}) {
    final id = (voiceId == null || voiceId.isEmpty)
        ? _defaultVoiceId
        : voiceId;
    return _provider.speak(text: text, voiceId: id);
  }

  Future<void> stop() => _provider.stop();

  void dispose() => _provider.dispose();
}
