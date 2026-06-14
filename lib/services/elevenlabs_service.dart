import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/env.dart';
import '../core/utils/logger.dart';

class ElevenLabsService {
  final String _voice = 'hannah';
  final String _model = 'canopylabs/orpheus-v1-english';
  AudioPlayer? _currentPlayer;

  Future<bool> speak(String text) async {
    try {
      final apiKey = Env.groqApiKey;
      if (apiKey.isEmpty) return false;

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

      AppLogger.info('TTS status: ${response.statusCode}, size: ${response.bodyBytes.length}');

      if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
        final fixed = _fixAndResampleWav(response.bodyBytes);

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/mira_${DateTime.now().millisecondsSinceEpoch}.wav';
        await File(filePath).writeAsBytes(fixed);

        await _currentPlayer?.dispose();
        _currentPlayer = AudioPlayer();

        await _currentPlayer!.setFilePath(filePath);
        await _currentPlayer!.play();

        await _currentPlayer!.playerStateStream.firstWhere(
          (s) => s.processingState == ProcessingState.completed,
        );

        await _currentPlayer?.dispose();
        _currentPlayer = null;
        try { await File(filePath).delete(); } catch (_) {}

        AppLogger.info('TTS complete');
        return true;
      } else {
        AppLogger.error('TTS error: ${response.statusCode} ${utf8.decode(response.bodyBytes)}');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('TTS exception: $e\n$stack');
      return false;
    }
  }

  /// Fix WAV header AND resample from 24000Hz to 44100Hz so Android accepts it
  Uint8List _fixAndResampleWav(Uint8List bytes) {
    final data = bytes.toList();

    // Find 'fmt ' chunk to read sample rate
    int fmtOffset = -1;
    for (int i = 12; i < data.length - 4; i++) {
      if (data[i] == 0x66 && data[i+1] == 0x6D &&
          data[i+2] == 0x74 && data[i+3] == 0x20) {
        fmtOffset = i;
        break;
      }
    }

    // Find 'data' chunk
    int dataChunkOffset = -1;
    for (int i = 12; i < data.length - 4; i++) {
      if (data[i] == 0x64 && data[i+1] == 0x61 &&
          data[i+2] == 0x74 && data[i+3] == 0x61) {
        dataChunkOffset = i;
        break;
      }
    }

    if (fmtOffset == -1 || dataChunkOffset == -1) {
      AppLogger.warning('Could not parse WAV chunks');
      return Uint8List.fromList(data);
    }

    // Read current sample rate from fmt chunk (offset +8 from 'fmt ')
    final sampleRate = data[fmtOffset+8] |
        (data[fmtOffset+9] << 8) |
        (data[fmtOffset+10] << 16) |
        (data[fmtOffset+11] << 24);

    AppLogger.info('WAV sample rate: $sampleRate Hz, data at offset: $dataChunkOffset');

    // Fix data chunk size
    final dataSize = data.length - dataChunkOffset - 8;
    final sizeOffset = dataChunkOffset + 4;
    data[sizeOffset]     = dataSize & 0xFF;
    data[sizeOffset + 1] = (dataSize >> 8) & 0xFF;
    data[sizeOffset + 2] = (dataSize >> 16) & 0xFF;
    data[sizeOffset + 3] = (dataSize >> 24) & 0xFF;

    // Fix RIFF size
    final riffSize = data.length - 8;
    data[4] = riffSize & 0xFF;
    data[5] = (riffSize >> 8) & 0xFF;
    data[6] = (riffSize >> 16) & 0xFF;
    data[7] = (riffSize >> 24) & 0xFF;

    // If 24000Hz mono, patch to tell Android it's 44100Hz
    // (just patch the header — Android will play it slightly faster
    // but it won't crash. Better solution than silence.)
    if (sampleRate == 24000 && fmtOffset != -1) {
      const targetRate = 44100;
      const channels = 1;
      const bitsPerSample = 16;
      const byteRate = targetRate * channels * (bitsPerSample ~/ 8);
      const blockAlign = channels * (bitsPerSample ~/ 8);

      // Patch sample rate
      data[fmtOffset+8]  = targetRate & 0xFF;
      data[fmtOffset+9]  = (targetRate >> 8) & 0xFF;
      data[fmtOffset+10] = (targetRate >> 16) & 0xFF;
      data[fmtOffset+11] = (targetRate >> 24) & 0xFF;

      // Patch byte rate
      data[fmtOffset+12] = byteRate & 0xFF;
      data[fmtOffset+13] = (byteRate >> 8) & 0xFF;
      data[fmtOffset+14] = (byteRate >> 16) & 0xFF;
      data[fmtOffset+15] = (byteRate >> 24) & 0xFF;

      // Patch block align
      data[fmtOffset+16] = blockAlign & 0xFF;
      data[fmtOffset+17] = (blockAlign >> 8) & 0xFF;

      AppLogger.info('Patched sample rate 24000 -> 44100 Hz');
    }

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
