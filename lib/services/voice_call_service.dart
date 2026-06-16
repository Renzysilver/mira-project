import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import '../core/utils/logger.dart';
import '../models/call_model.dart';
import '../services/ai_service.dart';
import '../services/memory_service.dart';
import '../services/audio_service.dart';
import '../services/elevenlabs_service.dart';
import '../models/persona_model.dart';
import '../models/message_model.dart';
import 'package:uuid/uuid.dart';

final voiceCallServiceProvider = Provider<VoiceCallService>((ref) {
  return VoiceCallService(AiService(), ref.read(memoryServiceProvider));
});

class VoiceCallService {
  final AiService _aiService;
  final MemoryService _memoryService;
  final AudioService _audioService;
  final ElevenLabsService _ttsService;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _uuid = const Uuid();

  bool _isInitialized = false;
  bool _isCallActive = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  int _consecutiveSttErrors = 0;
  static const int _maxSttErrors = 5;

  List<Map<String, String>> _conversationHistory = [];
  PersonaModel? _persona;
  String? _userName;

  Function(CallPhase)? onPhaseChanged;
  Function(String)? onUserSpoke;
  Function(String)? onAiSpoke;
  Function(String)? onError;

  VoiceCallService(this._aiService, this._memoryService)
      : _audioService = AudioService(),
        _ttsService = ElevenLabsService();

  Future<void> initialize(PersonaModel persona, String? userName) async {
    if (_isInitialized) return;
    _persona = persona;
    _userName = userName;

    await _speech.initialize(
      onError: (error) => _onSpeechError(error),
      onStatus: (status) => _onSpeechStatus(status),
    );

    _isInitialized = true;
  }

  Future<void> startCall() async {
    _isCallActive = true;
    _isSpeaking = false;
    _isProcessing = false;
    _consecutiveSttErrors = 0;
    _conversationHistory = [];

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      onError?.call('Microphone permission needed.');
      if (status.isPermanentlyDenied) await openAppSettings();
      _isCallActive = false;
      return;
    }

    onPhaseChanged?.call(CallPhase.dialing);
    await _audioService.startRinging();
    await Future.delayed(const Duration(seconds: 4));
    if (!_isCallActive) return;

    await _audioService.stopRinging();
    await _audioService.playCallConnected();
    if (!_isCallActive) return;

    final greeting = _userName != null && _userName!.isNotEmpty
        ? 'Hey $_userName! I\'m so happy you called. How are you doing?'
        : 'Hey! I\'m so happy you called. How are you doing?';

    _conversationHistory.add({'role': 'assistant', 'content': greeting});
    onAiSpoke?.call(greeting);

    await _audioService.playPreSpeakChime();
    await _speakText(greeting);

    if (!_isCallActive) return;
    _startListening();
  }

  /// Centralized speak method — always sets _isSpeaking flag correctly
  /// so the mic never reactivates mid-sentence.
  ///
  /// If TTS fails, [onError] is invoked and the call is terminated —
  /// better to fail loudly than to leave the user in silence.
  Future<void> _speakText(String text) async {
    _isSpeaking = true;
    await _speech.stop(); // mic OFF before speaking
    onPhaseChanged?.call(CallPhase.speaking);
    final ok = await _ttsService.speak(text);
    _isSpeaking = false;
    if (!ok) {
      AppLogger.error('TTS failed for text: ${text.substring(0, text.length.clamp(0, 80))}');
      onError?.call('Voice synthesis failed.');
      _isCallActive = false;
      return;
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _startListening() async {
    if (!_isCallActive ||
        !_speech.isAvailable ||
        _speech.isListening ||
        _isSpeaking ||
        _isProcessing) return;

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker |
          AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
    await session.setActive(true);

    onPhaseChanged?.call(CallPhase.listening);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _consecutiveSttErrors = 0; // successful recognition resets the counter
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _processUserSpeech(text);
          } else {
            if (_isCallActive && !_isSpeaking && !_isProcessing) {
              _startListening();
            }
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> _processUserSpeech(String text) async {
    if (!_isCallActive || _isProcessing || _isSpeaking) return;
    _isProcessing = true;

    onUserSpoke?.call(text);
    onPhaseChanged?.call(CallPhase.thinking);
    await _speech.stop();
    await _memoryService.processMessage(text);

    _conversationHistory.add({'role': 'user', 'content': text});

    if (_conversationHistory.length > 10) {
      _conversationHistory = _conversationHistory.sublist(
        _conversationHistory.length - 10,
      );
    }

    try {
      final memoryFacts = await _memoryService.getMemoryFacts();
      final messages = _conversationHistory
          .map((m) => MessageModel(
                id: _uuid.v4(),
                role: m['role']!,
                content: m['content']!,
                timestamp: DateTime.now(),
              ))
          .toList();

      final aiResponse = await _aiService.sendMessage(
        messages: messages,
        persona: _persona!,
        memoryFacts: memoryFacts,
        userName: _userName,
      );

      _conversationHistory.add({'role': 'assistant', 'content': aiResponse});
      onAiSpoke?.call(aiResponse);

      await _audioService.playPreSpeakChime();
      await _speakText(aiResponse);

      if (_isCallActive) _startListening();
    } catch (e) {
      AppLogger.error('Voice call AI error', e);
      onError?.call('Something went wrong.');
      _isCallActive = false;
    } finally {
      // Always reset, even if _speakText bailed early via onError.
      _isProcessing = false;
      _isSpeaking = false;
    }
  }

  void _onSpeechError(dynamic error) {
    AppLogger.warning('STT Error: $error');
    _consecutiveSttErrors++;
    if (_consecutiveSttErrors >= _maxSttErrors) {
      AppLogger.error('STT error cap reached ($_consecutiveSttErrors) — ending call');
      onError?.call('Speech recognition is having trouble. Ending call.');
      _isCallActive = false;
      return;
    }
    if (_isCallActive && !_isSpeaking && !_isProcessing) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_isCallActive && !_isSpeaking && !_isProcessing) _startListening();
      });
    }
  }

  void _onSpeechStatus(String status) {
    AppLogger.info('STT status: $status');
    if (status == 'notListening' &&
        _isCallActive &&
        !_isSpeaking &&
        !_isProcessing &&
        !_speech.isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isCallActive && !_isSpeaking && !_isProcessing) _startListening();
      });
    }
  }

  Future<void> endCall() async {
    _isCallActive = false;
    _isSpeaking = false;
    _isProcessing = false;
    await _speech.stop();
    await _ttsService.stop();
    await _audioService.stopRinging();
  }

  void dispose() {
    // Fire-and-forget endCall — we cannot await in dispose.
    endCall();
    _audioService.dispose();
    _ttsService.dispose();
  }
}
