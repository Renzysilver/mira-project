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

  // ---------------------------------------------------------------------------
  // Companions (multi-companion support — Phase C of master vision)
  // ---------------------------------------------------------------------------
  // Each user can have multiple companions stored at:
  //   users/{uid}/companions/{companionId}
  //
  // One companion per user has is_active = true — that's the one currently
  // selected for chat / call / persona display. The rest are stored for
  // later switching.
  //
  // Legacy single-companion data lives at users/{uid}/persona/current —
  // we keep that path working until the full migration to /companions.
  // ---------------------------------------------------------------------------

  CollectionReference get _companionsCol => _userDoc.collection('companions');

  /// Create a new companion. Returns the new companion's ID.
  ///
  /// The new companion is marked is_active = true, and all other
  /// companions for this user are set to is_active = false.
  Future<String> createCompanion(Map<String, dynamic> companion) async {
    final batch = _db.batch();
    // Deactivate existing companions
    final existing = await _companionsCol.get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {'is_active': false});
    }
    // Insert new companion as active
    final newRef = _companionsCol.doc();
    batch.set(newRef, {
      ...companion,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return newRef.id;
  }

  /// List all companions for the user, ordered by creation time.
  Future<List<Map<String, dynamic>>> getCompanions() async {
    final snap = await _companionsCol
        .orderBy('created_at', descending: false)
        .get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  /// Stream of companions (live updates when one is added/edited).
  Stream<List<Map<String, dynamic>>> watchCompanions() {
    return _companionsCol
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
            .toList());
  }

  /// Get the currently-active companion, or null if none exists.
  Future<Map<String, dynamic>?> getActiveCompanion() async {
    final snap = await _companionsCol.where('is_active', isEqualTo: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Map<String, dynamic>.from(doc.data() as Map)..['id'] = doc.id;
  }

  /// Set [companionId] as the active companion (deactivates all others).
  Future<void> setActiveCompanion(String companionId) async {
    final batch = _db.batch();
    final existing = await _companionsCol.get();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {
        'is_active': doc.id == companionId,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Delete a companion by ID.
  Future<void> deleteCompanion(String companionId) async {
    await _companionsCol.doc(companionId).delete();
  }

  // ---------------------------------------------------------------------------
  // Companion-scoped messages (Phase 3-C — per-companion chat history)
  // ---------------------------------------------------------------------------
  // Each companion has its own messages subcollection at:
  //   users/{uid}/companions/{companionId}/messages/{messageId}
  //
  // Switching companions automatically swaps the chat history because
  // chatProvider watches activeCompanionProvider and re-subscribes.
  // ---------------------------------------------------------------------------

  CollectionReference _companionMessagesCol(String companionId) =>
      _companionsCol.doc(companionId).collection('messages');

  Stream<List<Map<String, dynamic>>> watchCompanionMessages(
    String companionId, {
    String conversationId = 'main',
    int limit = AppConstants.maxCachedMessages,
  }) {
    return _companionMessagesCol(companionId)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
            .toList());
  }

  Future<void> addCompanionMessage(
    String companionId,
    Map<String, dynamic> message, {
    String conversationId = 'main',
  }) async {
    await _companionMessagesCol(companionId).add({
      ...message,
      'conversationId': conversationId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearCompanionMessages(
    String companionId, {
    String conversationId = 'main',
  }) async {
    final snap = await _companionMessagesCol(companionId)
        .where('conversationId', isEqualTo: conversationId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Companion-scoped memories (Phase 3-C — per-companion memory)
  // ---------------------------------------------------------------------------
  // Each companion has its own memory doc at:
  //   users/{uid}/companions/{companionId}/memories/facts
  //
  // Memories do NOT transfer between companions — Mira remembering
  // "User likes pizza" doesn't mean Aurora knows it too.
  // ---------------------------------------------------------------------------

  DocumentReference _companionMemoriesDocFor(String companionId) =>
      _companionsCol.doc(companionId).collection('memories').doc('facts');

  Future<List<String>> getCompanionMemoryFacts(String companionId) async {
    final snap = await _companionMemoriesDocFor(companionId).get();
    if (!snap.exists || snap.data() == null) return [];
    final data = Map<String, dynamic>.from(snap.data() as Map);
    return (data['facts'] as List<dynamic>? ?? []).cast<String>();
  }

  Future<void> saveCompanionMemoryFact(String companionId, String fact) async {
    await _companionMemoriesDocFor(companionId).set(
      {
        'facts': FieldValue.arrayUnion([fact]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearCompanionMemoryFacts(String companionId) async {
    await _companionMemoriesDocFor(companionId).set({
      'facts': [],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> watchCompanionMemoryFacts(String companionId) {
    return _companionMemoriesDocFor(companionId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return <String>[];
      final data = Map<String, dynamic>.from(snap.data() as Map);
      return (data['facts'] as List<dynamic>? ?? []).cast<String>();
    });
  }

  // ---------------------------------------------------------------------------
  // Companion doc streaming (Phase D — fix persona identity bug)
  // ---------------------------------------------------------------------------
  // Streams the full companion document so personaProvider can load the
  // active companion's name + personality instead of reading from the
  // legacy /persona/current path.
  // ---------------------------------------------------------------------------

  Stream<Map<String, dynamic>?> watchCompanionDoc(String companionId) {
    return _companionsCol.doc(companionId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Map<String, dynamic>.from(snap.data() as Map)..['id'] = snap.id;
    });
  }

  Future<Map<String, dynamic>?> getCompanionDoc(String companionId) async {
    final snap = await _companionsCol.doc(companionId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Map<String, dynamic>.from(snap.data() as Map)..['id'] = snap.id;
  }


  Future<void> saveCompanionFields(
      String companionId, Map<String, dynamic> fields) async {
    await _companionsCol.doc(companionId).set(
      {...fields, 'updated_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ── Companion-scoped call logs ──────────────────────────────────────
  // Each companion has its own call history at:
  //   users/{uid}/companions/{companionId}/calls/{callId}
  CollectionReference _companionCallsCol(String companionId) =>
      _companionsCol.doc(companionId).collection('calls');

  Future<List<Map<String, dynamic>>> getCompanionCallLogs(
      String companionId) async {
    final snap = await _companionCallsCol(companionId)
        .orderBy('endedAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchCompanionCallLogs(
      String companionId) {
    return _companionCallsCol(companionId)
        .orderBy('endedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
            .toList());
  }

  Future<void> addCompanionCallLog(
      String companionId, Map<String, dynamic> log) async {
    await _companionCallsCol(companionId).add({
      ...log,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Phase D — clear chat history (active companion or all companions)
  // ---------------------------------------------------------------------------

  /// Clear ALL messages for a single companion.
  Future<void> clearAllCompanionMessages(String companionId) async {
    final snap = await _companionMessagesCol(companionId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  /// Clear messages for every companion the user has.
  /// Used by the 'Clear all chats' option in settings.
  Future<void> clearAllChatsForAllCompanions() async {
    final companionsSnap = await _companionsCol.get();
    for (final companionDoc in companionsSnap.docs) {
      final msgSnap = await _companionMessagesCol(companionDoc.id).get();
      final batch = _db.batch();
      for (final doc in msgSnap.docs) batch.delete(doc.reference);
      await batch.commit();
    }
  
  }


// ---------------------------------------------------------------------------
  // Mira Assistant messages (separate from companion chats)
  // ---------------------------------------------------------------------------
  // Mira is the system AI assistant — NOT a companion. She has her own
  // chat history at users/{uid}/mira_messages/{messageId}, completely
  // separate from companion chats.
  // ---------------------------------------------------------------------------

  CollectionReference get _miraMessagesCol =>
      _userDoc.collection('mira_messages');

  Stream<List<Map<String, dynamic>>> watchMiraMessages({int limit = 50}) {
    return _miraMessagesCol
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Map<String, dynamic>.from(d.data() as Map)..['id'] = d.id)
            .toList());
  }

  Future<void> addMiraMessage(Map<String, dynamic> message) async {
    await _miraMessagesCol.add({
      ...message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearMiraMessages() async {
    final snap = await _miraMessagesCol.get();
    final batch = _db.batch();
    for (final doc in snap.docs) batch.delete(doc.reference);
    await batch.commit();
  }
}
