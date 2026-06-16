import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class FirestoreStorage {
  final String uid;
  final FirebaseFirestore _db;

  FirestoreStorage(this.uid) : _db = FirebaseFirestore.instance;

  DocumentReference get _userDoc => _db.collection('users').doc(uid);
  DocumentReference get _personaDoc => _userDoc.collection('persona').doc('current');
  DocumentReference get _settingsDoc => _userDoc.collection('settings').doc('prefs');
  DocumentReference get _memoriesDoc => _userDoc.collection('memories').doc('facts');
  CollectionReference get _messagesCol => _userDoc.collection('messages');
  CollectionReference get _callsCol => _userDoc.collection('calls');

  // ---------------------------------------------------------------------------
  // Persona
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> getPersona() async {
    final snap = await _personaDoc.get();
    if (!snap.exists || snap.data() == null) return null;
    return Map<String, dynamic>.from(snap.data() as Map);
  }

  Future<void> savePersona(Map<String, dynamic> persona) async {
    await _personaDoc.set(
      {...persona, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Stream<Map<String, dynamic>?> watchPersona() {
    return _personaDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Map<String, dynamic>.from(snap.data() as Map);
    });
  }

  // ---------------------------------------------------------------------------
  // Relationship stats
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getRelationshipStats() async {
    final snap = await _personaDoc.get();
    if (!snap.exists || snap.data() == null) return _defaultRelationshipStats();
    final data = Map<String, dynamic>.from(snap.data() as Map);
    final stats = data['relationship_stats'];
    if (stats == null) return _defaultRelationshipStats();
    return Map<String, dynamic>.from(stats as Map);
  }

  Future<void> saveRelationshipStats(Map<String, dynamic> stats) async {
    await _personaDoc.set(
      {'relationship_stats': stats, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _defaultRelationshipStats() => {
    'daysTogether': 0,
    'messagesSent': 0,
    'callsMade': 0,
    'affectionLevel': 30,
    'streakDays': 0,
    'lastCheckIn': '',
    'startDate': DateTime.now().toIso8601String(),
  };

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSettings() async {
    final snap = await _settingsDoc.get();
    if (!snap.exists || snap.data() == null) return _defaultSettings();
    return Map<String, dynamic>.from(snap.data() as Map);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsDoc.set(
      {...settings, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Stream<Map<String, dynamic>> watchSettings() {
    return _settingsDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return _defaultSettings();
      return Map<String, dynamic>.from(snap.data() as Map);
    });
  }

  Map<String, dynamic> _defaultSettings() => {
    'darkMode': true,
    'notifications': true,
    'soundEffects': true,
    'flirtMode': false,
    'friendshipMode': false,
    'aiVoice': true,
  };

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  Future<bool> isOnboardingComplete() async {
    final snap = await _userDoc.get();
    if (!snap.exists || snap.data() == null) return false;
    final data = Map<String, dynamic>.from(snap.data() as Map);
    return data['onboardingComplete'] as bool? ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _userDoc.update({'onboardingComplete': value});
  }

  // ---------------------------------------------------------------------------
  // Memories
  // ---------------------------------------------------------------------------

  Future<List<String>> getMemoryFacts() async {
    final snap = await _memoriesDoc.get();
    if (!snap.exists || snap.data() == null) return [];
    final data = Map<String, dynamic>.from(snap.data() as Map);
    return (data['facts'] as List<dynamic>? ?? []).cast<String>();
  }

  Future<void> saveMemoryFact(String fact) async {
    await _memoriesDoc.set(
      {'facts': FieldValue.arrayUnion([fact]), 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> clearMemoryFacts() async {
    await _memoriesDoc.set({'facts': [], 'updatedAt': FieldValue.serverTimestamp()});
  }

  Stream<List<String>> watchMemoryFacts() {
    return _memoriesDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return <String>[];
      final data = Map<String, dynamic>.from(snap.data() as Map);
      return (data['facts'] as List<dynamic>? ?? []).cast<String>();
    });
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final snap = await _messagesCol
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .limitToLast(AppConstants.maxCachedMessages)
        .get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  /// Writes a single message. [conversationId] is embedded in the document
  /// so it can be queried — callers do not need to pass it separately.
  Future<DocumentReference> addMessage(
      Map<String, dynamic> message,
      String conversationId,
      ) async {
    return _messagesCol.add({
      ...message,
      'conversationId': conversationId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes every message document for [conversationId].
  Future<void> clearMessages(String conversationId) async {
    final snap = await _messagesCol
        .where('conversationId', isEqualTo: conversationId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchMessages(
      String conversationId, {
        int limit = AppConstants.maxCachedMessages,
      }) {
    return _messagesCol
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList());
  }

  // ---------------------------------------------------------------------------
  // Call logs
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCallLogs() async {
    final snap = await _callsCol
        .orderBy('startedAt', descending: true)
        .limit(100)
        .get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  Future<DocumentReference> addCallLog(Map<String, dynamic> log) async {
    return _callsCol.add({
      ...log,
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchCallLogs() {
    return _callsCol
        .orderBy('startedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList());
  }
}