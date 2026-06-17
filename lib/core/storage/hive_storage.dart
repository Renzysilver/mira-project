import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

final hiveStorageProvider = Provider<HiveStorage>((ref) => HiveStorage());

class HiveStorage {
  // Messages
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final box = Hive.box(AppConstants.messagesBox);
    final List<dynamic> stored = box.get('conv_$conversationId', defaultValue: []);
    return stored.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(AppConstants.messagesBox);
    final toSave = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    await box.put('conv_$conversationId', toSave);
  }

  // Persona
  Future<Map<String, dynamic>?> getPersona() async {
    final box = Hive.box(AppConstants.personaBox);
    final data = box.get('current_persona');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> savePersona(Map<String, dynamic> persona) async {
    final box = Hive.box(AppConstants.personaBox);
    await box.put('current_persona', persona);
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final box = Hive.box(AppConstants.settingsBox);
    final data = box.get('settings', defaultValue: {'darkMode': true, 'notifications': true, 'soundEffects': true, 'flirtMode': false, 'friendshipMode': false, 'aiVoice': true});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put('settings', settings);
  }

  // Memories
  Future<List<String>> getMemoryFacts() async {
    final box = Hive.box(AppConstants.memoriesBox);
    final List<dynamic> stored = box.get('facts', defaultValue: []);
    return stored.cast<String>();
  }

  Future<void> saveMemoryFact(String fact) async {
    final facts = await getMemoryFacts();
    if (!facts.contains(fact)) {
      facts.add(fact);
      if (facts.length > AppConstants.maxMemoryFacts) facts.removeAt(0);
      final box = Hive.box(AppConstants.memoriesBox);
      await box.put('facts', facts);
    }
  }

  Future<void> clearMemoryFacts() async {
    final box = Hive.box(AppConstants.memoriesBox);
    await box.put('facts', []);
  }

  // Call logs
  Future<List<Map<String, dynamic>>> getCallLogs() async {
    final box = Hive.box(AppConstants.callLogsBox);
    final List<dynamic> stored = box.get('logs', defaultValue: []);
    return stored.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> addCallLog(Map<String, dynamic> log) async {
    final logs = await getCallLogs();
    logs.insert(0, log);
    if (logs.length > 100) logs.removeLast();
    final box = Hive.box(AppConstants.callLogsBox);
    await box.put('logs', logs);
  }

  // Onboarding
  Future<bool> isOnboardingComplete() async {
    final box = Hive.box(AppConstants.settingsBox);
    return box.get('onboarding_complete', defaultValue: false);
  }

  Future<void> setOnboardingComplete(bool value) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put('onboarding_complete', value);
  }

  // Relationship Stats
  Future<Map<String, dynamic>> getRelationshipStats() async {
    final box = Hive.box(AppConstants.personaBox);
    final data = box.get('relationship_stats', defaultValue: {
      'daysTogether': 0, 'messagesSent': 0, 'callsMade': 0, 'affectionLevel': 30, 'streakDays': 0, 'lastCheckIn': '', 'startDate': DateTime.now().toIso8601String(),
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveRelationshipStats(Map<String, dynamic> stats) async {
    final box = Hive.box(AppConstants.personaBox);
    await box.put('relationship_stats', stats);
  }

  // User cache
  Future<UserModel?> getUser() async {
    final box = Hive.box(AppConstants.userBox);
    final data = box.get('current_user');
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data as Map);
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    );
  }

  Future<void> saveUser(UserModel user) async {
    final box = Hive.box(AppConstants.userBox);
    await box.put('current_user', {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'createdAt': user.createdAt.toIso8601String(),
      'onboardingComplete': user.onboardingComplete,
    });
  }

  Future<void> clearUser() async {
    final box = Hive.box(AppConstants.userBox);
    await box.delete('current_user');
  }
}
