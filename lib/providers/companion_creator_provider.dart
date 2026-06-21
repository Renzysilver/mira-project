import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import '../models/companion_creator_state.dart';
import '../models/persona_model.dart';
import 'auth_provider.dart';
import 'persona_provider.dart';

/// State + notifier for the companion creator wizard.
///
/// 5-step flow:
///   0. Identity (name, age, backstory)
///   1. Appearance (hair, eyes, clothing)
///   2. Voice (provider, voiceId, accent, tone)
///   3. Personality (personalityType + traits)
///   4. Interests (multi-select)
///
/// On [save], the state is converted to a companion document and written
/// to Firestore (or Supabase once migrated). The new companion becomes
/// the active companion.
final companionCreatorProvider =
    StateNotifierProvider<CompanionCreatorNotifier, CompanionCreatorState>(
        (ref) {
  return CompanionCreatorNotifier(ref);
});

class CompanionCreatorNotifier extends StateNotifier<CompanionCreatorState> {
  final Ref _ref;
  int _currentStep = 0;
  bool _isSaving = false;
  String? _error;

  CompanionCreatorNotifier(this._ref) : super(const CompanionCreatorState());

  int get currentStep => _currentStep;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get canProceed => _validateStep(_currentStep);

  void nextStep() {
    if (_currentStep < CompanionCreatorState.stepCount - 1) {
      _currentStep++;
      _error = null;
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _error = null;
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < CompanionCreatorState.stepCount) {
      _currentStep = step;
      _error = null;
    }
  }

  // ── Setters for each field ─────────────────────────────────────────────
  void setName(String v) => state = state.copyWith(name: v);
  void setAgeRange(String v) => state = state.copyWith(ageRange: v);
  void setBackgroundStory(String v) =>
      state = state.copyWith(backgroundStory: v);

  void setHairStyle(String v) => state = state.copyWith(hairStyle: v);
  void setHairColor(String v) => state = state.copyWith(hairColor: v);
  void setEyeColor(String v) => state = state.copyWith(eyeColor: v);
  void setFaceStyle(String v) => state = state.copyWith(faceStyle: v);
  void setClothing(String v) => state = state.copyWith(clothing: v);

  void toggleAccessory(String v) {
    final list = List<String>.from(state.accessories);
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(accessories: list);
  }

  void setVoiceProvider(String v) => state = state.copyWith(voiceProvider: v);
  void setVoiceId(String v) => state = state.copyWith(voiceId: v);
  void setAccent(String v) => state = state.copyWith(accent: v);
  void setTone(String v) => state = state.copyWith(tone: v);
  void setEnergyLevel(String v) => state = state.copyWith(energyLevel: v);
  void setSpeakingSpeed(String v) =>
      state = state.copyWith(speakingSpeed: v);
  void setSpeechPattern(String v) =>
      state = state.copyWith(speechPattern: v);

  void setPersonalityType(PersonalityType v) =>
      state = state.copyWith(personalityType: v);

  void toggleTrait(String v) {
    final list = List<String>.from(state.traits);
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(traits: list);
  }

  void toggleInterest(String v) {
    final list = List<String>.from(state.interests);
    if (list.contains(v)) {
      list.remove(v);
    } else {
      list.add(v);
    }
    state = state.copyWith(interests: list);
  }

  /// Validate the current step — returns true if the user can proceed.
  bool _validateStep(int step) {
    switch (step) {
      case 0: // Identity
        return state.name.trim().isNotEmpty;
      case 1: // Appearance — all have defaults
        return true;
      case 2: // Voice — all have defaults
        return true;
      case 3: // Personality
        return true;
      case 4: // Interests
        return true;
      default:
        return true;
    }
  }

  /// Save the new companion.
  ///
  /// Writes to Firestore via FirestoreStorage.savePersona. The companion
  /// becomes the active companion.
  ///
  /// TODO (multi-companion): when we add a companions collection, this
  /// should INSERT a new companion row and set is_active=true (and false
  /// on all others). For now it just overwrites the single persona doc
  /// at persona/current — preserving existing single-companion behaviour.
  Future<bool> save() async {
    if (state.name.trim().isEmpty) {
      _error = 'Please give her a name';
      return false;
    }

    _isSaving = true;
    _error = null;

    try {
      final user = _ref.read(authProvider).user;
      if (user == null) {
        _error = 'Not signed in';
        _isSaving = false;
        return false;
      }

      final storage = _ref.read(firestoreStorageProvider);
      if (storage == null) {
        _error = 'Storage not ready';
        _isSaving = false;
        return false;
      }

      // Build the persona + write to Firestore.
      final persona = PersonaModel(
        name: state.name.trim(),
        personalityType: state.personalityType,
        currentMood: AvatarMood.happy,
        temperature: 0.8,
        flirtEnabled: false,
        friendshipMode: false,
      );

      await _ref.read(personaProvider.notifier).updatePersona(persona);

      // Also save the creator-specific fields to the same doc.
      // Firestore is schemaless so this just adds keys.
      await storage.savePersona(state.toCompanionJson());

      _isSaving = false;
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to save companion', e, stack);
      _error = 'Failed to save: $e';
      _isSaving = false;
      return false;
    }
  }

  /// Reset to defaults — call when leaving the creator without saving.
  void reset() {
    _currentStep = 0;
    _error = null;
    _isSaving = false;
    state = const CompanionCreatorState();
  }
}
