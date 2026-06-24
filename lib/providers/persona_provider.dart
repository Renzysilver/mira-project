import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../core/relationship/milestones.dart';
import '../core/utils/logger.dart';
import '../models/persona_model.dart';
import '../models/relationship_model.dart';
import '../providers/auth_provider.dart';
import '../providers/companions_provider.dart';

/// Persona + relationship stats + milestones for the active companion.
///
/// Uses `.select((c) => c?.id)` so the provider only rebuilds when the
/// companion ID changes, not on every companion doc update. The companion
/// doc itself is streamed via `watchCompanionDoc` inside the notifier.
final personaProvider =
    StateNotifierProvider<PersonaNotifier, PersonaState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final activeCompanionId =
      ref.watch(activeCompanionProvider.select((c) => c?.id));
  if (storage == null) return PersonaNotifier(null, null);
  return PersonaNotifier(storage, activeCompanionId);
});

class PersonaState {
  final PersonaModel persona;
  final RelationshipModel relationship;
  final bool isLoading;
  final String? companionId;
  final List<String> milestones;

  const PersonaState({
    this.persona = const PersonaModel(),
    this.relationship = const RelationshipModel(),
    this.isLoading = false,
    this.companionId,
    this.milestones = const [],
  });

  PersonaState copyWith({
    PersonaModel? persona,
    RelationshipModel? relationship,
    bool? isLoading,
    String? companionId,
    List<String>? milestones,
  }) {
    return PersonaState(
      persona: persona ?? this.persona,
      relationship: relationship ?? this.relationship,
      isLoading: isLoading ?? this.isLoading,
      companionId: companionId ?? this.companionId,
      milestones: milestones ?? this.milestones,
    );
  }
}

/// Stream of milestones that were just unlocked — UI listens to this
/// to show a celebration SnackBar.
///
/// Implementation note: for now, the chat screen calls
/// personaProvider.notifier.checkMilestones(memoryCount: ...) after
/// each send, and shows a SnackBar for each newly-unlocked milestone.
/// This provider exists for future refactoring into a proper stream.
final newlyUnlockedMilestonesProvider =
    Provider<Stream<Milestone>>((ref) => const Stream.empty());

class PersonaNotifier extends StateNotifier<PersonaState> {
  final FirestoreStorage? _storage;
  final String? _companionId;
  StreamSubscription? _sub;
  List<String> _lastSeenMilestones = const [];

  PersonaNotifier(this._storage, this._companionId)
      : super(const PersonaState()) {
    if (_storage == null) return;
    if (_companionId == null) return;
    _subscribe();
  }

  void _subscribe() {
    state = state.copyWith(isLoading: true, companionId: _companionId);
    _sub?.cancel();
    _sub = _storage!.watchCompanionDoc(_companionId!).listen(
      (data) {
        if (data == null) {
          state = state.copyWith(isLoading: false);
          return;
        }
        final persona = PersonaModel.fromJson(data);
        final rawStats = data['relationship_stats'];
        final relationship = rawStats != null
            ? RelationshipModel.fromJson(
                Map<String, dynamic>.from(rawStats as Map))
            : const RelationshipModel();
        final milestones = (data['milestones'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList();

        _lastSeenMilestones = milestones;
        state = PersonaState(
          persona: persona,
          relationship: relationship,
          isLoading: false,
          companionId: _companionId,
          milestones: milestones,
        );
      },
      onError: (e) {
        AppLogger.error('personaProvider stream error', e);
        state = state.copyWith(isLoading: false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Persona writes ────────────────────────────────────────────────
  Future<void> updatePersona(PersonaModel persona) async {
    if (_storage == null || !mounted || _companionId == null) return;
    state = state.copyWith(persona: persona);
    await _storage.saveCompanionFields(_companionId!, persona.toJson());
  }

  Future<void> updateName(String name) async =>
      updatePersona(state.persona.copyWith(name: name));

  Future<void> updatePersonalityType(PersonalityType type) async =>
      updatePersona(state.persona.copyWith(personalityType: type));

  Future<void> updateMood(AvatarMood mood) async =>
      updatePersona(state.persona.copyWith(currentMood: mood));

  Future<void> toggleFlirtMode() async => updatePersona(state.persona
      .copyWith(flirtEnabled: !state.persona.flirtEnabled));

  Future<void> toggleFriendshipMode() async => updatePersona(state.persona
      .copyWith(friendshipMode: !state.persona.friendshipMode));

  // ── Relationship stat writes ──────────────────────────────────────
  Future<void> _updateStats(RelationshipModel updated) async {
    if (_storage == null || !mounted || _companionId == null) return;
    state = state.copyWith(relationship: updated);
    await _storage.saveCompanionFields(
        _companionId!, {'relationship_stats': updated.toJson()});
  }

  /// Increment message count by 1, bump affection by 1, and check
  /// milestones. Called by chatProvider on every user message.
  Future<void> incrementMessageCount() async {
    final newStats = state.relationship.copyWith(
        messagesSent: state.relationship.messagesSent + 1,
        affectionLevel:
            (state.relationship.affectionLevel + 1).clamp(0, 100));
    await _updateStats(newStats);
    await _checkMilestones(memoryCount: _lastSeenMilestones.length);
  }

  /// Increment call count, bump affection by 3, check milestones.
  /// Called by callProvider.endCall().
  Future<void> incrementCallCount() async {
    final newStats = state.relationship.copyWith(
        callsMade: state.relationship.callsMade + 1,
        affectionLevel:
            (state.relationship.affectionLevel + 3).clamp(0, 100));
    await _updateStats(newStats);
    await _checkMilestones(memoryCount: _lastSeenMilestones.length);
  }

  /// Manually adjust affection (e.g. for future 'gift' feature).
  Future<void> updateAffection(int change) async => _updateStats(
      state.relationship.copyWith(
          affectionLevel:
              (state.relationship.affectionLevel + change).clamp(0, 100)));

  Future<void> setStartDate() async => _updateStats(state.relationship
      .copyWith(startDate: DateTime.now().toIso8601String()));

  /// Re-check milestones with the current stats. Called after any
  /// stat change. [memoryCount] is passed in by the caller because
  /// memory facts live in a separate doc.
  Future<List<Milestone>> _checkMilestones({required int memoryCount}) async {
    if (_companionId == null) return [];
    final result = MilestoneChecker.check(
      messagesSent: state.relationship.messagesSent,
      callsMade: state.relationship.callsMade,
      affectionLevel: state.relationship.affectionLevel,
      streakDays: state.relationship.streakDays,
      memoryCount: memoryCount,
      alreadyUnlocked: state.milestones,
    );
    if (result.unlockedNow.isEmpty) return [];

    // Persist the new milestones list to Firestore.
    await _storage!.saveCompanionFields(
        _companionId!, {'milestones': result.allUnlocked});
    state = state.copyWith(milestones: result.allUnlocked);

    // Return the newly-unlocked Milestone objects so the UI can
    // celebrate them.
    return result.unlockedNow
        .map((id) => MilestoneDefinitions.byId(id))
        .whereType<Milestone>()
        .toList();
  }

  /// External entry point — chat screen calls this after sending a
  /// message so we can re-check milestones with the latest memory count.
  /// Returns the list of newly-unlocked milestones (if any).
  Future<List<Milestone>> checkMilestones({required int memoryCount}) async {
    return _checkMilestones(memoryCount: memoryCount);
  }

  /// List of currently-unlocked milestones as full Milestone objects
  /// (with icon, color, etc.) — used by the persona screen to render
  /// the badges section.
  List<Milestone> get unlockedMilestoneObjects => state.milestones
      .map((id) => MilestoneDefinitions.byId(id))
      .whereType<Milestone>()
      .toList();
}
