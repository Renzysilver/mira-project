import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/env.dart';
import '../core/utils/logger.dart';

/// TTS service that uses Groq's Orpheus model (canopylabs/orpheus-v1-english).
///
/// Despite the class name, this no longer talks to ElevenLabs — the old
/// backend `/api/voice/tts` route was removed (see commit 64d9b66). The
/// name is retained for now because `voice_call_service.dart` and the
/// avatar controller both reference it.
class ElevenLabsService {
  final String _voice = 'hannah';
  final String _model = 'canopylabs/orpheus-v1-english';
  AudioPlayer? _currentPlayer;

  /// Synthesize and play [text]. Returns `true` on success, `false` on any
  /// failure (HTTP error, empty audio, playback failure). Callers MUST
  /// check the return value — see voice_call_service.dart.
  Future<bool> speak(String text) async {
    try {
      final apiKey = Env.groqApiKey;
      if (apiKey.isEmpty) {
        AppLogger.error('TTS: GROQ_API_KEY not set');
        return false;
      }
      if (text.trim().isEmpty) return false;

      AppLogger.info('TTS: ${text.substring(0, text.length.clamp(0, 60))}');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'voice': _voice,
          'input': text,
          'response_format': 'wav',
        }),
      ).timeout(const Duration(seconds: 30));

      AppLogger.info(
        'TTS status: ${response.statusCode}, size: ${response.bodyBytes.length}',
      );

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

      await _currentPlayer!.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
        orElse: () => throw TimeoutException('TTS playback did not complete'),
      );

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
  /// ⚠️  KNOWN LIMITATION: Groq Orpheus returns 24 kHz mono PCM. The previous
  /// implementation rewrote the header to claim 44.1 kHz WITHOUT actually
  /// resampling — the audio therefore played ~1.84× too fast on Android.
  /// We now leave the sample rate at 24 kHz; just_audio handles 24 kHz
  /// playback correctly on all supported platforms.
  ///
  /// The data-chunk size and RIFF size are still rewritten because Groq
  /// occasionally returns headers with stale chunk sizes.
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

    // Fix data chunk size
    final dataSize = data.length - dataChunkOffset - 8;
    final sizeOffset = dataChunkOffset + 4;
    data[sizeOffset] = dataSize & 0xFF;
    data[sizeOffset + 1] = (dataSize >> 8) & 0xFF;
    data[sizeOffset + 2] = (dataSize >> 16) & 0xFF;
    data[sizeOffset + 3] = (dataSize >> 24) & 0xFF;

    // Fix RIFF size
    final riffSize = data.length - 8;
    data[4] = riffSize & 0xFF;
    data[5] = (riffSize >> 8) & 0xFF;
    data[6] = (riffSize >> 16) & 0xFF;
    data[7] = (riffSize >> 24) & 0xFF;

    return Uint8List.fromList(data);
  }

  Future<void> stop() async {
    await _currentPlayer?.stop();
    await _currentPlayer?.dispose();
    _currentPlayer = null;
  }

  void dispose() {
    _currentPlayer?.dispose();
    _currentPlayer = null;
  }
}
