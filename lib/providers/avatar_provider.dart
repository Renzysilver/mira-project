import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar_state.dart';
import '../models/call_model.dart';
import 'call_provider.dart';
import 'chat_provider.dart';

final avatarStateProvider = Provider<MiraAvatarState>((ref) {
  final callState = ref.watch(callProvider);
  final chatState = ref.watch(chatProvider);

  // Call takes priority
  if (callState.status == CallStatus.connected) {
    switch (callState.phase) {
      case CallPhase.listening:  return MiraAvatarState.listening;
      case CallPhase.thinking:   return MiraAvatarState.thinking;
      case CallPhase.speaking:   return MiraAvatarState.speaking;
      case CallPhase.dialing:    return MiraAvatarState.idle;
    }
  }

  // Chat state
  if (chatState.isLoading) return MiraAvatarState.thinking;
  if (chatState.messages.isNotEmpty &&
      chatState.messages.last.role == 'assistant' &&
      chatState.lastResponseAge < const Duration(seconds: 4)) {
    return MiraAvatarState.happy;
  }

  return MiraAvatarState.idle;
});