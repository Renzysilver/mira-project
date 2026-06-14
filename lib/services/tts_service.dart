import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);
    _isInitialized = true;
  }

  Future<void> speak(String text) async { if (!_isInitialized) await initialize(); await _tts.speak(text); }
  Future<void> stop() async { await _tts.stop(); _isSpeaking = false; }
  void dispose() { _tts.stop(); }
}
