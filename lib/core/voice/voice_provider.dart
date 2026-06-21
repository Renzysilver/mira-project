/// Provider-agnostic voice (TTS) interface.
///
/// Implementations:
/// - [GroqOrpheusVoiceProvider] (real, uses Groq's Orpheus TTS)
/// - ElevenLabsVoiceProvider (stubbed)
/// - CartesiaVoiceProvider (stubbed)
/// - AzureVoiceProvider (stubbed)
///
/// The active provider is selected by [VoiceProviderRegistry.active]
/// based on the VOICE_PROVIDER env var (defaults to 'groq').
///
/// Per-companion voice identity: each companion stores its own
/// `voiceProvider` and `voiceId` (in the companions table). The caller
/// passes these to [synthesize] so each companion can sound different.
abstract class VoiceProvider {
  /// Provider identifier, e.g. 'groq', 'elevenlabs', 'cartesia'.
  String get id;

  /// Human-readable display name.
  String get displayName;

  /// Whether this provider is currently configured.
  bool get isAvailable;

  /// List of voice IDs this provider supports. Used by the companion
  /// creator UI to populate the voice picker.
  List<VoiceOption> get availableVoices;

  /// Synthesize [text] to audio and play it through the device speakers.
  ///
  /// [voiceId] — provider-specific voice identifier (e.g. 'hannah' for
  ///   Groq Orpheus, or an ElevenLabs voice UUID).
  ///
  /// Returns true on success, false on any failure (HTTP error, empty
  /// audio, playback failure). Callers MUST check the return value.
  Future<bool> speak({required String text, required String voiceId});

  /// Stop any currently-playing audio.
  Future<void> stop();

  /// Release resources.
  void dispose();
}

/// A voice option exposed by a [VoiceProvider].
class VoiceOption {
  /// Provider-specific voice identifier (passed back to [VoiceProvider.speak]).
  final String id;

  /// Human-readable name for the voice picker UI.
  final String name;

  /// Optional description (e.g. 'Warm, natural female voice').
  final String? description;

  /// Optional accent tag (e.g. 'American', 'British', 'Nigerian').
  final String? accent;

  /// Optional style tag (e.g. 'Soft', 'Energetic', 'Mature').
  final String? style;

  const VoiceOption({
    required this.id,
    required this.name,
    this.description,
    this.accent,
    this.style,
  });
}
