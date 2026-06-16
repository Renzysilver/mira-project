import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../providers/auth_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final FirestoreStorage? _storage;
  StreamSubscription? _sub;

  SettingsNotifier(this._storage) : super(_defaultSettings()) {
    if (_storage == null) return;
    _subscribe();
  }

  void _subscribe() {
    _sub = _storage!.watchSettings().listen(
          (data) => state = data,
      onError: (_) {}, // keep last good state on error
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (_storage == null) return;
    state = {...state, key: value};
    await _storage.saveSettings(state);
  }

  bool get darkMode => state['darkMode'] ?? true;
  bool get notifications => state['notifications'] ?? true;
  bool get soundEffects => state['soundEffects'] ?? true;
  bool get flirtMode => state['flirtMode'] ?? false;
  bool get friendshipMode => state['friendshipMode'] ?? false;
  bool get aiVoice => state['aiVoice'] ?? true;

  static Map<String, dynamic> _defaultSettings() => {
    'darkMode': true,
    'notifications': true,
    'soundEffects': true,
    'flirtMode': false,
    'friendshipMode': false,
    'aiVoice': true,
  };
}