import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../models/persona_model.dart';
import '../models/relationship_model.dart';
import '../core/utils/logger.dart';
import '../providers/auth_provider.dart';
import '../providers/companions_provider.dart';

/// Persona + relationship stats for the currently-active companion.
///
/// Now loads from the companion doc directly (users/{uid}/companions/{id})
/// instead of the legacy /persona/current path. This fixes the bug where
/// Luna would say "I'm Mira" because the old code read the default
/// persona doc regardless of which companion was active.
final personaProvider =
    StateNotifierProvider<PersonaNotifier, PersonaState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final activeCompanion = ref.watch(activeCompanionProvider);
  if (storage == null) return PersonaNotifier(null, null);
  return PersonaNotifier(storage, activeCompanion?.id);
});

class PersonaState {
  final PersonaModel persona;
  final RelationshipModel relationship;
  final bool isLoading;
  final String? companionId;

  const PersonaState({
    this.persona = const PersonaModel(),
    this.relationship = const RelationshipModel(),
    this.isLoading = false,
    this.companionId,
  });

  PersonaState copyWith({
    PersonaModel? persona,
    RelationshipModel? relationship,
    bool? isLoading,
    String? companionId,
  }) {
    return PersonaState(
      persona: persona ?? this.persona,
      relationship: relationship ?? this.relationship,
      isLoading: isLoading ?? this.isLoading,
      companionId: companionId ?? this.companionId,
    );
  }
}

class PersonaNotifier extends StateNotifier<PersonaState> {
  final FirestoreStorage? _storage;
  final String? _companionId;
  StreamSubscription? _sub;

  PersonaNotifier(this._storage, this._companionId)
      : super(const PersonaState()) {
    if (_storage == null) return;
    if (_companionId == null) {
      // No active companion yet (e.g. fresh signup before default companion
      // finishes creating). Show defaults — the provider will rebuild when
      // activeCompanionProvider fires.
      return;
    }
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
        // Build PersonaModel from the companion doc.
        // The companion doc has snake_case fields (personality_type,
        // current_mood, flirt_enabled, etc.) — PersonaModel.fromJson
        // expects those keys.
        final persona = PersonaModel.fromJson(data);
        // Relationship stats: the companion doc may or may not have
        // relationship_stats embedded; for now use defaults. Phase D
        // will add a separate relationship_stats subcollection.
        final rawStats = data['relationship_stats'];
        final relationship = rawStats != null
            ? RelationshipModel.fromJson(
                Map<String, dynamic>.from(rawStats as Map))
            : const RelationshipModel();
        state = PersonaState(
          persona: persona,
          relationship: relationship,
          isLoading: false,
          companionId: _companionId,
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
    // Write back to the companion doc — only the persona fields.
    await _storage.saveCompanionFields(_companionId!, persona.toJson());
  }

  Future<void> updateName(String name) async =>
      updatePersona(state.persona.copyWith(name: name));

  Future<void> updatePersonalityType(PersonalityType type) async =>
      updatePersona(state.persona.copyWith(personalityType: type));

  Future<void> updateMood(AvatarMood mood) async =>
      updatePersona(state.persona.copyWith(currentMood: mood));

  Future<void> toggleFlirtMode() async =>
      updatePersona(state.persona.copyWith(flirtEnabled: !state.persona.flirtEnabled));

  Future<void> toggleFriendshipMode() async =>
      updatePersona(state.persona.copyWith(friendshipMode: !state.persona.friendshipMode));

  // ── Relationship stat writes ──────────────────────────────────────
  Future<void> _updateStats(RelationshipModel updated) async {
    if (_storage == null || !mounted || _companionId == null) return;
    state = state.copyWith(relationship: updated);
    // Write relationship_stats as a sub-map on the companion doc.
    await _storage.saveCompanionFields(
        _companionId!, {'relationship_stats': updated.toJson()});
  }

  Future<void> incrementMessageCount() async => _updateStats(
      state.relationship.copyWith(messagesSent: state.relationship.messagesSent + 1));

  Future<void> incrementCallCount() async => _updateStats(
      state.relationship.copyWith(callsMade: state.relationship.callsMade + 1));

  Future<void> updateAffection(int change) async => _updateStats(
      state.relationship.copyWith(
          affectionLevel: (state.relationship.affectionLevel + change).clamp(0, 100)));

  Future<void> setStartDate() async => _updateStats(
      state.relationship.copyWith(startDate: DateTime.now().toIso8601String()));
}
