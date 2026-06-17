import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/firebase_storage.dart';
import '../../core/utils/logger.dart';
import '../../models/persona_model.dart';
import '../../providers/auth_provider.dart';
import 'companion_creator_state.dart';

final companionCreatorProvider =
    StateNotifierProvider<CompanionCreatorNotifier, CompanionCreatorState>(
        (ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return CompanionCreatorNotifier(storage);
});

class CompanionCreatorNotifier extends StateNotifier<CompanionCreatorState> {
  final FirestoreStorage? _storage;
  CompanionCreatorNotifier(this._storage) : super(const CompanionCreatorState());

  void nextStep() {
    if (state.currentStep < CompanionCreatorState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < CompanionCreatorState.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  // ── Identity setters ─────────────────────────────────────────────
  void setName(String v) => state = state.copyWith(name: v);
  void setAgeRange(String v) => state = state.copyWith(ageRange: v);
  void setBackgroundStory(String v) =>
      state = state.copyWith(backgroundStory: v);

  // ── Personality setters ──────────────────────────────────────────
  void setPersonalityType(PersonalityType t) =>
      state = state.copyWith(personalityType: t);

  void toggleTrait(String trait) {
    final traits = List<String>.from(state.personalityTraits);
    if (traits.contains(trait)) {
      traits.remove(trait);
    } else {
      traits.add(trait);
    }
    state = state.copyWith(personalityTraits: traits);
  }

  // ── Appearance setters ───────────────────────────────────────────
  void setHairStyle(String v) => state = state.copyWith(hairStyle: v);
  void setHairColor(String v) => state = state.copyWith(hairColor: v);
  void setEyeColor(String v) => state = state.copyWith(eyeColor: v);
  void setFaceStyle(String v) => state = state.copyWith(faceStyle: v);
  void setClothing(String v) => state = state.copyWith(clothing: v);

  void toggleAccessory(String a) {
    final list = List<String>.from(state.accessories);
    if (list.contains(a)) {
      list.remove(a);
    } else {
      if (a == 'None') {
        list.clear();
      } else {
        list.remove('None');
      }
      list.add(a);
    }
    state = state.copyWith(accessories: list);
  }

  // ── Voice setters ────────────────────────────────────────────────
  void setVoiceProvider(String v) => state = state.copyWith(voiceProvider: v);
  void setVoiceId(String v) => state = state.copyWith(voiceId: v);
  void setAccent(String v) => state = state.copyWith(accent: v);
  void setTone(String v) => state = state.copyWith(tone: v);
  void setEnergyLevel(String v) => state = state.copyWith(energyLevel: v);
  void setSpeakingSpeed(String v) => state = state.copyWith(speakingSpeed: v);

  // ── Interests setters ────────────────────────────────────────────
  void toggleInterest(String i) {
    final list = List<String>.from(state.interests);
    if (list.contains(i)) {
      list.remove(i);
    } else {
      list.add(i);
    }
    state = state.copyWith(interests: list);
  }

  // ── Save ─────────────────────────────────────────────────────────
  /// Persist the companion to Firestore. Returns the new companion ID
  /// on success, null on failure (state.error will be set).
  Future<String?> save() async {
    if (_storage == null) {
      state = state.copyWith(error: 'Not signed in');
      return null;
    }
    state = state.copyWith(isSaving: true, error: null);
    try {
      final id = await _storage.createCompanion(state.toFirestore());
      AppLogger.info('Companion created: $id');
      state = state.copyWith(isSaving: false);
      return id;
    } catch (e, stack) {
      AppLogger.error('Failed to create companion', e, stack);
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  /// Update an existing companion. Returns true on success.
  /// Requires [companionId] — the ID of the companion to update.
  Future<bool> update(String companionId) async {
    if (_storage == null) {
      state = state.copyWith(error: 'Not signed in');
      return false;
    }
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _storage.saveCompanionFields(companionId, state.toFirestore());
      AppLogger.info('Companion updated: $companionId');
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to update companion', e, stack);
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Load form state from an existing companion's Firestore data.
  /// Used by the edit screen to pre-fill the wizard.
  void loadFromCompanion(Map<String, dynamic> data) {
    state = CompanionCreatorState(
      name: data['name'] as String? ?? 'Mira',
      ageRange: data['age_range'] as String? ?? '18-22',
      backgroundStory: data['background_story'] as String? ?? '',
      personalityType: _parsePersonalityType(
          data['personality_type'] as String? ?? 'sweet'),
      personalityTraits: (data['personality_traits'] as List<dynamic>? ??
              const ['Caring'])
          .map((e) => e as String)
          .toList(),
      hairStyle: data['hair_style'] as String? ?? 'Long',
      hairColor: data['hair_color'] as String? ?? 'Pink',
      eyeColor: data['eye_color'] as String? ?? 'Blue',
      faceStyle: data['face_style'] as String? ?? 'Cute',
      clothing: data['clothing'] as String? ?? 'Casual',
      accessories: (data['accessories'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      voiceProvider: data['voice_provider'] as String? ?? 'groq',
      voiceId: data['voice_id'] as String? ?? 'hannah',
      accent: data['accent'] as String? ?? 'Neutral International',
      tone: data['tone'] as String? ?? 'Soft',
      energyLevel: data['energy_level'] as String? ?? 'Medium',
      speakingSpeed: data['speaking_speed'] as String? ?? 'Normal',
      interests: (data['interests'] as List<dynamic>? ?? const ['Anime'])
          .map((e) => e as String)
          .toList(),
    );
  }

  PersonalityType _parsePersonalityType(String s) {
    switch (s) {
      case 'tsundere':
        return PersonalityType.tsundere;
      case 'intellectual':
        return PersonalityType.intellectual;
      case 'sweet':
      default:
        return PersonalityType.sweet;
    }
  }

  /// Reset the form back to defaults (for re-use after a save).
  void reset() {
    state = const CompanionCreatorState();
  }
}
