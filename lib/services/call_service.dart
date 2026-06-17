import 'package:flutter_riverpod/flutter_riverpod.dart';
final callServiceProvider = Provider<CallService>((ref) => CallService());
class CallService {
  Future<void> initialize() async {}
  Future<void> joinChannel(String channelName) async {}
  Future<void> leaveChannel() async {}
  Future<void> toggleMute(bool muted) async {}
  Future<void> toggleSpeaker(bool enabled) async {}
  String generateChannelName() => 'mira_call_123';
  void dispose() {}
}
