import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import '../models/persona_model.dart';
import '../providers/auth_provider.dart';
import '../providers/persona_provider.dart';
import '../app/routes.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return OnboardingNotifier(storage, ref);
});

class OnboardingState {
  final int currentStep;
  final String aiName;
  final PersonalityType personalityType;
  final bool isComplete;

  const OnboardingState({
    this.currentStep = 0,
    this.aiName = 'Mira',
    this.personalityType = PersonalityType.sweet,
    this.isComplete = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? aiName,
    PersonalityType? personalityType,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      aiName: aiName ?? this.aiName,
      personalityType: personalityType ?? this.personalityType,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FirestoreStorage? _storage;
  final Ref _ref;

  OnboardingNotifier(this._storage, this._ref) : super(const OnboardingState());

  void nextStep() {
    if (state.currentStep < 2) state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) state = state.copyWith(currentStep: state.currentStep - 1);
  }

  void setAiName(String name) => state = state.copyWith(aiName: name);
  void setPersonalityType(PersonalityType type) => state = state.copyWith(personalityType: type);

  Future<void> completeOnboarding() async {
    if (_storage == null) return;

    // Create the user's first companion — but ONLY if they don't
    // already have one. This prevents duplicate "Mira" entries when
    // onboarding runs multiple times (e.g. after clearing cache).
    try {
      final existing = await _storage.getCompanions();
      if (existing.isEmpty) {
        await _storage.createCompanion({
          'name': state.aiName,
          'personality_type': state.personalityType.name,
          'current_mood': 'happy',
          'temperature': 0.8,
          'flirt_enabled': false,
          'friendship_mode': false,
          'voice_provider': 'groq',
          'voice_id': 'hannah',
          'accent': 'Neutral International',
          'tone': 'Soft',
          'energy_level': 'Medium',
          'speaking_speed': 'Normal',
          'interests': ['Anime'],
          'relationship_stats': {
            'daysTogether': 0,
            'messagesSent': 0,
            'callsMade': 0,
            'affectionLevel': 30,
            'streakDays': 0,
            'lastCheckIn': '',
            'startDate': DateTime.now().toIso8601String(),
          },
        });
        AppLogger.info('Onboarding created first companion: ${state.aiName}');
      } else {
        AppLogger.info('Onboarding skipped companion creation — '
            '${existing.length} companion(s) already exist');
      }
    } catch (e, stack) {
      AppLogger.error('Failed during onboarding companion check/create', e, stack);
    }

    // Flip onboardingComplete on the anchor doc via authProvider
    await _ref.read(authProvider.notifier).completeOnboarding();

    if (!mounted) return;
    _ref.read(onboardingCompleteProvider.notifier).state = true;
    state = state.copyWith(isComplete: true);
  }
}