import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'command_registry.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// A scheduled reminder.
class Reminder {
  final String id;
  final String text;
  final DateTime scheduledAt;
  final bool isFired;

  const Reminder({
    required this.id,
    required this.text,
    required this.scheduledAt,
    this.isFired = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'scheduledAt': scheduledAt.toIso8601String(),
        'isFired': isFired,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        text: json['text'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        isFired: json['isFired'] as bool? ?? false,
      );
}

/// Lightweight local reminder system.
///
/// Stores reminders in Hive and polls every 10 seconds to fire any due
/// reminders. The fired reminders are surfaced via [firedRemindersProvider]
/// — the chat screen shows them as system messages.
///
/// This is intentionally simple — no FCM, no background execution, no
/// OS-level notifications. When the app is closed, reminders don't fire.
/// For real push notifications, we'd need FCM wiring (Phase F).
class ReminderService {
  static const _boxName = 'reminders';
  static const _pollInterval = Duration(seconds: 10);

  Timer? _timer;
  final _firedController = StreamController<Reminder>.broadcast();
  Stream<Reminder> get firedReminders => _firedController.stream;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _checkDue());
    AppLogger.info('ReminderService started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<List<Reminder>> getAll() async {
    final box = Hive.box(_boxName);
    final list = box.get('all', defaultValue: []) as List<dynamic>;
    return list.map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Parse a duration string like '5m', '2h', '1d' and schedule a
  /// reminder. Returns the created reminder, or null on parse failure.
  Future<Reminder?> schedule(String durationStr, String text) async {
    final parsed = _parseDuration(durationStr);
    if (parsed == null) return null;

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      scheduledAt: DateTime.now().add(parsed),
    );

    final box = Hive.box(_boxName);
    final all = await getAll();
    all.add(reminder);
    await box.put('all', all.map((r) => r.toJson()).toList());

    AppLogger.info('Reminder scheduled: "${reminder.text}" at ${reminder.scheduledAt}');
    return reminder;
  }

  Future<void> _checkDue() async {
    final all = await getAll();
    final now = DateTime.now();
    var changed = false;
    for (final r in all) {
      if (!r.isFired && now.isAfter(r.scheduledAt)) {
        _firedController.add(r);
        // Mark as fired (we keep it in storage so the user can see history)
        final idx = all.indexOf(r);
        all[idx] = Reminder(
          id: r.id,
          text: r.text,
          scheduledAt: r.scheduledAt,
          isFired: true,
        );
        changed = true;
      }
    }
    if (changed) {
      final box = Hive.box(_boxName);
      await box.put('all', all.map((r) => r.toJson()).toList());
    }
  }

  /// Parse '5m', '2h', '1d', '30s' into a Duration. Returns null on failure.
  static Duration? _parseDuration(String s) {
    s = s.trim().toLowerCase();
    if (s.isEmpty) return null;
    final unit = s.substring(s.length - 1);
    final value = int.tryParse(s.substring(0, s.length - 1));
    if (value == null) return null;
    switch (unit) {
      case 's':
        return Duration(seconds: value);
      case 'm':
        return Duration(minutes: value);
      case 'h':
        return Duration(hours: value);
      case 'd':
        return Duration(days: value);
      default:
        return null;
    }
  }

  /// Format a Duration as a human-readable string.
  static String formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  void dispose() {
    _timer?.cancel();
    _firedController.close();
  }
}

class RemindCommand extends AssistantCommand {
  final ReminderService _service;
  RemindCommand(this._service);

  @override
  String get name => 'remind';
  @override
  String get description => 'Schedule a reminder. Examples: /remind 5m Call mom';
  @override
  String get usage => '/remind <5m|2h|1d> <text>';

  @override
  Future<CommandResult> execute(String args) async {
    final parts = args.split(' ');
    if (parts.length < 2) {
      return const CommandResult(
        displayText: 'Usage: /remind <duration> <text>\nExample: /remind 5m Call mom',
        isError: true,
      );
    }
    final durationStr = parts.first;
    final text = parts.skip(1).join(' ');
    final reminder = await _service.schedule(durationStr, text);
    if (reminder == null) {
      return const CommandResult(
        displayText: 'Invalid duration. Use 5m, 2h, 1d, 30s etc.',
        isError: true,
      );
    }
    final remaining = reminder.scheduledAt.difference(DateTime.now());
    return CommandResult(
      displayText:
          '✓ Reminder set: "$text" in ${ReminderService.formatDuration(remaining)}.',
    );
  }
}
