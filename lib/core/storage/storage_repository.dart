/// Provider-agnostic storage repository interface.
///
/// Both FirestoreStorage and SupabaseStorage implement this interface.
/// The factory [StorageRepositoryFactory.active] returns whichever one
/// is currently active (based on the USE_SUPABASE env flag).
///
/// Downstream providers (personaProvider, chatProvider, etc.) depend on
/// this interface, not on a concrete implementation — so switching
/// backends is a one-line change in env config.
///
/// NOTE: This is the forward-looking interface designed for multi-
/// companion support. Most methods take a [companionId] parameter so
/// each companion can have its own persona, memories, messages, etc.
/// During the gradual migration, the existing single-companion code
/// passes the active companion's ID (or 'default' if none).
abstract class StorageRepository {
  // ── Persona ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getPersona(String companionId);
  Future<void> savePersona(String companionId, Map<String, dynamic> persona);
  Stream<Map<String, dynamic>?> watchPersona(String companionId);

  // ── Relationship stats ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getRelationshipStats(String companionId);
  Future<void> saveRelationshipStats(
      String companionId, Map<String, dynamic> stats);

  // ── Settings ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSettings(String userId);
  Future<void> saveSettings(String userId, Map<String, dynamic> settings);
  Stream<Map<String, dynamic>> watchSettings(String userId);

  // ── Onboarding ───────────────────────────────────────────────────────
  Future<bool> isOnboardingComplete(String userId);
  Future<void> setOnboardingComplete(String userId, bool value);

  // ── Memories ─────────────────────────────────────────────────────────
  Future<List<String>> getMemoryFacts(String companionId);
  Future<void> saveMemoryFact(String companionId, String fact);
  Future<void> clearMemoryFacts(String companionId);
  Stream<List<String>> watchMemoryFacts(String companionId);

  // ── Messages ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMessages(
      String companionId, String conversationId);
  Future<void> addMessage(
      String companionId, String conversationId, Map<String, dynamic> message);
  Future<void> clearMessages(String companionId, String conversationId);
  Stream<List<Map<String, dynamic>>> watchMessages(
      String companionId, String conversationId, {int limit = 50});

  // ── Call logs ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCallLogs(String companionId);
  Future<void> addCallLog(String companionId, Map<String, dynamic> log);
  Stream<List<Map<String, dynamic>>> watchCallLogs(String companionId);
}

/// Factory that returns the active storage repository.
///
/// Returns SupabaseStorage if USE_SUPABASE=true and Supabase is
/// configured. Otherwise returns FirestoreStorage (the current default).
///
/// Usage in providers:
///   final storage = StorageRepositoryFactory.active;
///   if (storage == null) return; // not signed in yet
///   final persona = await storage.getPersona(companionId);
class StorageRepositoryFactory {
  StorageRepositoryFactory._();

  /// Returns the active StorageRepository, or null if neither backend
  /// is available (e.g. user not signed in).
  static StorageRepository? forUser(String userId) {
    // TODO: wire this up once SupabaseStorage is implemented.
    // For now, callers continue to use FirestoreStorage directly via
    // firestoreStorageProvider. This factory exists so the migration is
    // mechanical when the time comes.
    return null;
  }
}
