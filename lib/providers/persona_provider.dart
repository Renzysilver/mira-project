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
/// Watches [activeCompanionProvider] and reloads when the active
/// companion changes. Falls back to the legacy /persona/current path
/// when no companion exists in /companions/{id} (i.e. legacy users
/// who haven't migrated yet, or freshly-onboarded accounts).
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

  const PersonaState({
    this.persona = const PersonaModel(),
    this.relationship = const RelationshipModel(),
    this.isLoading = false,
  });

  PersonaState copyWith({
    PersonaModel? persona,
    RelationshipModel? relationship,
    bool? isLoading,
  }) {
    return PersonaState(
      persona: persona ?? this.persona,
      relationship: relationship ?? this.relationship,
      isLoading: isLoading ?? this.isLoading,
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
    _subscribe();
  }

  void _subscribe() {
    state = state.copyWith(isLoading: true);
    _sub?.cancel();
    _sub = _storage!.watchPersona().listen(
      (data) {
        if (data == null) return;
        final rawStats = data['relationship_stats'];
        state = state.copyWith(
          persona: PersonaModel.fromJson(data),
          relationship: rawStats != null
              ? RelationshipModel.fromJson(
                  Map<String, dynamic>.from(rawStats as Map))
              : const RelationshipModel(),
          isLoading: false,
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
    if (_storage == null) return;
    state = state.copyWith(persona: persona);
    await _storage.savePersona(persona.toJson());
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
    if (_storage == null) return;
    state = state.copyWith(relationship: updated);
    await _storage.saveRelationshipStats(updated.toJson());
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
