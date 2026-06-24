import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/wakeword_service.dart';
import '../core/constants/app_constants.dart';

final wakeWordProvider =
StateNotifierProvider<WakeWordNotifier, bool>((ref) => WakeWordNotifier());

class WakeWordNotifier extends StateNotifier<bool> {
  static const _key = 'wakeWordEnabled';

  WakeWordNotifier() : super(false) {
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    final box = Hive.box(AppConstants.settingsBox);
    final enabled = box.get(_key, defaultValue: false) as bool;
    state = enabled;
    if (enabled) {
      await Permission.notification.request();
      await WakeWordBridge.start();
    }
  }

  /// Toggle wake word on/off, persist to Hive, start/stop native service.
  Future<void> toggle() async {
    final next = !state;
    state = next;
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(_key, next);
    if (next) {
      // Notification permission (Android 13+) — needed for fallback
      // notification when app is fully closed.
      await Permission.notification.request();
      // Overlay permission — lets startActivity work from background,
      // enabling Hey Mira to pop the app from the recents screen.
      final canOverlay = await WakeWordBridge.canDrawOverlays();
      if (!canOverlay) {
        await WakeWordBridge.requestOverlayPermission();
      }
      await WakeWordBridge.start();
    } else {
      await WakeWordBridge.stop();
    }
  }

  /// Programmatically enable (e.g. to restore service after a call ends).
  Future<void> enable() async {
    if (state) return;
    state = true;
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(_key, true);
    await WakeWordBridge.start();
  }

  /// Programmatically disable (e.g. to avoid STT conflict during calls).
  Future<void> disable() async {
    if (!state) return;
    await WakeWordBridge.stop();
  }
}