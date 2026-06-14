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
    await _speech.stop();
      onPhaseChanged?.call(CallPhase.speaking);

    await _ttsService.speak(greeting);

    if (!_isCallActive) return;

    _startListening();
  }

    void _startListening() async {
    if (!_isCallActive || !_speech.isAvailable || _speech.isListening) return;

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(  // <-- REMOVED 'const'
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
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _processUserSpeech(text);
          } else {
            if (_isCallActive) _startListening();
          }
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _processUserSpeech(String text) async {
    if (!_isCallActive) return;

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
      await _speech.stop();
      onPhaseChanged?.call(CallPhase.speaking);

      await _ttsService.speak(aiResponse);

      if (!_isCallActive) return;

      await Future.delayed(const Duration(milliseconds: 1000));

      if (_isCallActive) _startListening();
    } catch (e) {
      AppLogger.error('Voice call AI error', e);
      onError?.call('Something went wrong. Ending call.');
      _isCallActive = false;
    }
  }

  void _onSpeechError(dynamic error) {
    AppLogger.error('STT Error: $error');
    if (_isCallActive) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_isCallActive) _startListening();
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && _isCallActive && !_speech.isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isCallActive) _startListening();
      });
    }
  }

  Future<void> endCall() async {
    _isCallActive = false;
    await _speech.stop();
    await _ttsService.stop();
    await _audioService.stopRinging();
  }

  void dispose() {
    endCall();
    _audioService.dispose();
    _ttsService.dispose();
  }
}