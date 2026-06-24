import 'package:flutter/services.dart';

/// Dart bridge to the native Android WakeWordService.
///
/// Call [WakeWordBridge.init] once (in app.dart) to register the
/// incoming-call handler. Then set [onWakeWordDetected] to a callback
/// that navigates to the call screen.
///
/// Platform support: Android only. All methods are no-ops on iOS.
class WakeWordBridge {
  static const _channel = MethodChannel('com.example.mira/wake_word');

  /// Called by app.dart when "Hey Mira" is detected while the app is
  /// already in the foreground. Also called after a cold-start check.
  static void Function()? onWakeWordDetected;

  /// Register the MethodChannel handler. Must be called before the
  /// app can receive wake-word events from the native side.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'wakeWordDetected') {
        onWakeWordDetected?.call();
      }
    });
  }

  /// Start the foreground listening service.
  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('startService');
    } catch (e) {
      // MissingPluginException on iOS or if Kotlin side not wired yet.
      // ignore: avoid_print
      print('[WakeWord] start error: $e');
    }
  }

  /// Stop the foreground listening service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopService');
    } catch (e) {
      // ignore: avoid_print
      print('[WakeWord] stop error: $e');
    }
  }

  /// Returns true if the native service is currently running.
  static Future<bool> isRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the app has been granted "Draw over other apps".
  /// When this is granted, startActivity from the background service works,
  /// enabling Hey Mira to open the call screen from the recents screen.
  static Future<bool> canDrawOverlays() async {
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Settings page where the user can grant
  /// "Draw over other apps" for this app.
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {}
  }
  /// Returns true once, then resets to false on the native side.
  /// Call this in app.dart after the Flutter engine is ready.
  static Future<bool> checkPendingWakeWord() async {
    try {
      return await _channel.invokeMethod<bool>('checkPendingWakeWord') ?? false;
    } catch (_) {
      return false;
    }
  }
}