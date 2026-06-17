import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../core/utils/logger.dart';

class AudioService {
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _effectsPlayer;
  bool _isRinging = false;

  Future<void> startRinging() async {
    _isRinging = true;
    try {
      _ringtonePlayer = AudioPlayer();
      await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer!.play(AssetSource('audio/ringtone.mp3'));
    } catch (e) {
      AppLogger.warning('Ringtone failed: $e');
    }
    _ringVibrationLoop();
  }

  void _ringVibrationLoop() async {
    while (_isRinging) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!_isRinging) return;
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!_isRinging) return;
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }

  Future<void> stopRinging() async {
    _isRinging = false;
    try {
      await _ringtonePlayer?.stop();
      await _ringtonePlayer?.dispose();
      _ringtonePlayer = null;
    } catch (_) {}
    // Give Android time to release the audio track
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> playCallConnected() async {
    try {
      _effectsPlayer = AudioPlayer();
      await _effectsPlayer!.play(AssetSource('audio/call_connected.mp3'));
      await Future.delayed(const Duration(milliseconds: 900));
      await _effectsPlayer?.dispose();
      _effectsPlayer = null;
    } catch (e) {
      AppLogger.warning('Connect sound failed: $e');
    }
  }

  Future<void> playPreSpeakChime() async {
    try {
      _effectsPlayer = AudioPlayer();
      await _effectsPlayer!.play(AssetSource('audio/chime.mp3'));
      await Future.delayed(const Duration(milliseconds: 400));
      await _effectsPlayer?.dispose();
      _effectsPlayer = null;
    } catch (e) {
      AppLogger.warning('Chime failed: $e');
    }
  }

  void dispose() {
    _ringtonePlayer?.dispose();
    _effectsPlayer?.dispose();
  }
}
