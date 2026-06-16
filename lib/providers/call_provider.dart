import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../services/voice_call_service.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import '../models/call_model.dart';

// ── Provider ───────────────────────────────────────────────────────────────
final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final voiceService = ref.watch(voiceCallServiceProvider);
  return CallNotifier(ref, voiceService, storage);
});

// ── Notifier ───────────────────────────────────────────────────────────────
class CallNotifier extends StateNotifier<CallState> {
  final Ref _ref;
  final VoiceCallService _voiceCallService;
  final FirestoreStorage? _storage;
  Timer? _durationTimer;
  bool _callWasStarted = false;

  CallNotifier(this._ref, this._voiceCallService, this._storage)
      : super(CallState(
          id: '',
          status: CallStatus.ringing,
          phase: CallPhase.dialing,
          startedAt: DateTime.now(),
        )) {
    _voiceCallService.onPhaseChanged =
        (phase) => state = state.copyWith(phase: phase);
    _voiceCallService.onUserSpoke =
        (text) => state = state.copyWith(lastUserSpeech: text);
    _voiceCallService.onAiSpoke =
        (text) => state = state.copyWith(lastAiSpeech: text);
    _voiceCallService.onError =
        (_) => state = state.copyWith(status: CallStatus.ended);
  }

  Future<void> startCall() async {
    if (_callWasStarted) {
      // Prevent double-start if the screen rebuilds.
      return;
    }
    _callWasStarted = true;

    final persona = _ref.read(personaProvider).persona;
    final user = _ref.read(authProvider).user;

    await _voiceCallService.initialize(persona, user?.displayName);

    state = CallState(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: CallStatus.ringing,
      phase: CallPhase.dialing,
      startedAt: DateTime.now(),
    );

    await _voiceCallService.startCall();
    _startTimer();
  }

  void toggleMute() => state = state.copyWith(isMuted: !state.isMuted);

  void toggleSpeaker() =>
      state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);

  void updateSpeech({String? userSpeech, String? aiSpeech}) {
    state = state.copyWith(
      lastUserSpeech: userSpeech ?? state.lastUserSpeech,
      lastAiSpeech: aiSpeech ?? state.lastAiSpeech,
      phase: aiSpeech != null ? CallPhase.speaking : CallPhase.listening,
    );
  }

  void setThinking() => state = state.copyWith(phase: CallPhase.thinking);

  Future<void> endCall() async {
    _durationTimer?.cancel();
    await _voiceCallService.endCall();

    // Only persist a call log if the call actually started — otherwise we'd
    // spam the history with zero-duration entries from quick back-outs.
    if (_callWasStarted && state.id.isNotEmpty) {
      final personaName = _ref.read(personaProvider).persona.name;
      try {
        await _storage?.addCallLog({
          'personaName':
              personaName.isNotEmpty ? personaName : 'Unknown',
          'duration': state.durationSeconds,
          'endedAt': FieldValue.serverTimestamp(),
          'summary': state.lastAiSpeech,
        });
      } catch (e) {
        // Logging the call is best-effort — don't surface to the user.
        // ignore: avoid_print
        print('Failed to write call log: $e');
      }
    }

    _callWasStarted = false;
    state = state.copyWith(
      status: CallStatus.ended,
      endedAt: DateTime.now(),
    );
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}
