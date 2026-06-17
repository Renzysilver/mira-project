import 'voice_provider.dart';

/// Stub implementations for voice providers we don't have API keys for yet.
///
/// Each one throws [UnimplementedError] with a helpful message. When you
/// get an API key for one of these, replace the stub with a real
/// implementation that follows the [GroqOrpheusVoiceProvider] pattern.

class ElevenLabsVoiceProvider implements VoiceProvider {
  @override
  String get id => 'elevenlabs';
  @override
  String get displayName => 'ElevenLabs';
  @override
  bool get isAvailable => false; // TODO: read ELEVENLABS_API_KEY from env

  @override
  List<VoiceOption> get availableVoices => const [
        VoiceOption(
            id: '21m00Tcm4TlvDq8ikWAM',
            name: 'Rachel',
            description: 'Warm, natural female voice'),
      ];

  @override
  Future<bool> speak({required String text, required String voiceId}) =>
      throw UnimplementedError(
          'ElevenLabs provider not implemented. Add ELEVENLABS_API_KEY to '
          '.env and implement lib/core/voice/elevenlabs_provider.dart');

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

class CartesiaVoiceProvider implements VoiceProvider {
  @override
  String get id => 'cartesia';
  @override
  String get displayName => 'Cartesia';
  @override
  bool get isAvailable => false;

  @override
  List<VoiceOption> get availableVoices => const [
        VoiceOption(id: 'fetched-on-demand', name: 'Cartesia Voices'),
      ];

  @override
  Future<bool> speak({required String text, required String voiceId}) =>
      throw UnimplementedError(
          'Cartesia provider not implemented. Add CARTESIA_API_KEY to .env '
          'and implement lib/core/voice/cartesia_provider.dart');

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

class AzureVoiceProvider implements VoiceProvider {
  @override
  String get id => 'azure';
  @override
  String get displayName => 'Azure Speech';
  @override
  bool get isAvailable => false;

  @override
  List<VoiceOption> get availableVoices => const [
        VoiceOption(
            id: 'en-US-JennyNeural',
            name: 'Jenny (en-US)',
            accent: 'American',
            style: 'Friendly'),
      ];

  @override
  Future<bool> speak({required String text, required String voiceId}) =>
      throw UnimplementedError(
          'Azure Speech provider not implemented. Add AZURE_SPEECH_KEY and '
          'AZURE_SPEECH_REGION to .env and implement '
          'lib/core/voice/azure_provider.dart');

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}
