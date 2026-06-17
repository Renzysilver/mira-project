import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/env.dart';
import '../../core/utils/logger.dart';
import 'voice_provider.dart';

/// Groq Orpheus TTS implementation of [VoiceProvider].
///
/// Uses Groq's /audio/speech endpoint with the canopylabs/orpheus-v1-english
/// model. The audio comes back as 24kHz mono WAV — just_audio handles
/// this natively (no resampling needed).
///
/// API docs: https://console.groq.com/docs/text-to-speech
class GroqOrpheusVoiceProvider implements VoiceProvider {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/audio/speech';
  static const String _model = 'canopylabs/orpheus-v1-english';
  static const Duration _timeout = Duration(seconds: 30);

  AudioPlayer? _currentPlayer;

  @override
  String get id => 'groq';

  @override
  String get displayName => 'Groq Orpheus TTS';

  @override
  bool get isAvailable => Env.groqApiKey.isNotEmpty;

  @override
  List<VoiceOption> get availableVoices => const [
        VoiceOption(
          id: 'hannah',
          name: 'Hannah',
          description: 'Warm, natural female voice',
          accent: 'Neutral International',
          style: 'Soft',
        ),
        VoiceOption(
          id: 'charon',
          name: 'Charon',
          description: 'Deep, mature male voice',
          accent: 'Neutral International',
          style: 'Mature',
        ),
        VoiceOption(
          id: 'atlas',
          name: 'Atlas',
          description: 'Confident, energetic male voice',
          accent: 'Neutral International',
          style: 'Energetic',
        ),
        VoiceOption(
          id: 'bria',
          name: 'Bria',
          description: 'Playful, youthful female voice',
          accent: 'Neutral International',
          style: 'Playful',
        ),
      ];

  @override
  Future<bool> speak({required String text, required String voiceId}) async {
    try {
      if (!isAvailable) {
        AppLogger.error('Groq TTS: GROQ_API_KEY not set');
        return false;
      }
      if (text.trim().isEmpty) return false;

      AppLogger.info(
          'TTS [$voiceId]: ${text.substring(0, text.length.clamp(0, 60))}');

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.groqApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'voice': voiceId,
          'input': text,
          'response_format': 'wav',
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.error(
          'TTS HTTP ${response.statusCode}: '
          '${utf8.decode(response.bodyBytes, allowMalformed: true).substring(0, 200)}',
        );
        return false;
      }
      if (response.bodyBytes.length <= 1000) {
        AppLogger.error('TTS returned suspiciously small payload '
            '(${response.bodyBytes.length} bytes)');
        return false;
      }

      final fixed = _patchWavHeader(response.bodyBytes);

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/mira_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(filePath).writeAsBytes(fixed);

      await _currentPlayer?.dispose();
      _currentPlayer = AudioPlayer();

      await _currentPlayer!.setFilePath(filePath);
      await _currentPlayer!.play();

      // Wait for playback to complete. Use a timeout instead of
      // orElse — orElse only fires when the stream CLOSES, which may
      // never happen (broadcast streams stay open). Without a timeout,
      // this await can hang forever if the player never emits
      // 'completed', leaving the call stuck in SPEAKING state.
      //
      // Also listen for 'completed' OR 'idle' — some just_audio
      // backends emit 'idle' instead of 'completed' on certain devices.
      try {
        await _currentPlayer!.playerStateStream
            .firstWhere((s) =>
                s.processingState == ProcessingState.completed ||
                s.processingState == ProcessingState.idle)
            .timeout(const Duration(seconds: 30));
      } on TimeoutException {
        AppLogger.warning(
            'TTS playback timed out after 30s — treating as complete');
      }

      await _currentPlayer?.dispose();
      _currentPlayer = null;
      try {
        await File(filePath).delete();
      } catch (_) {}

      AppLogger.info('TTS complete');
      return true;
    } catch (e, stack) {
      AppLogger.error('TTS exception: $e\n$stack');
      return false;
    }
  }

  /// Patch the WAV header so Android's player accepts it.
  ///
  /// Groq occasionally returns headers with stale chunk sizes. We rewrite
  /// the data chunk size and RIFF size to match the actual payload.
  /// Sample rate is left at 24kHz — just_audio handles it natively.
  Uint8List _patchWavHeader(Uint8List bytes) {
    final data = bytes.toList();

    int fmtOffset = -1;
    int dataChunkOffset = -1;
    for (int i = 12; i < data.length - 4; i++) {
      if (data[i] == 0x66 && data[i + 1] == 0x6D &&
          data[i + 2] == 0x74 && data[i + 3] == 0x20) {
        fmtOffset = i;
      }
      if (data[i] == 0x64 && data[i + 1] == 0x61 &&
          data[i + 2] == 0x74 && data[i + 3] == 0x61) {
        dataChunkOffset = i;
      }
      if (fmtOffset != -1 && dataChunkOffset != -1) break;
    }

    if (fmtOffset == -1 || dataChunkOffset == -1) {
      AppLogger.warning('Could not parse WAV chunks — returning raw bytes');
      return Uint8List.fromList(data);
    }

    final dataSize = data.length - dataChunkOffset - 8;
    final sizeOffset = dataChunkOffset + 4;
    data[sizeOffset] = dataSize & 0xFF;
    data[sizeOffset + 1] = (dataSize >> 8) & 0xFF;
    data[sizeOffset + 2] = (dataSize >> 16) & 0xFF;
    data[sizeOffset + 3] = (dataSize >> 24) & 0xFF;

    final riffSize = data.length - 8;
    data[4] = riffSize & 0xFF;
    data[5] = (riffSize >> 8) & 0xFF;
    data[6] = (riffSize >> 16) & 0xFF;
    data[7] = (riffSize >> 24) & 0xFF;

    return Uint8List.fromList(data);
  }

  @override
  Future<void> stop() async {
    await _currentPlayer?.stop();
    await _currentPlayer?.dispose();
    _currentPlayer = null;
  }

  @override
  void dispose() {
    _currentPlayer?.dispose();
    _currentPlayer = null;
  }
}
