import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/persona_model.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import '../app/routes.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.read(personaProvider.notifier), ref);
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
  final PersonaNotifier _personaNotifier;
  final Ref _ref;

  OnboardingNotifier(this._personaNotifier, this._ref) : super(const OnboardingState());

  void nextStep() {
    if (state.currentStep < 2) state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) state = state.copyWith(currentStep: state.currentStep - 1);
  }

  void setAiName(String name) => state = state.copyWith(aiName: name);
  void setPersonalityType(PersonalityType type) => state = state.copyWith(personalityType: type);

  Future<void> completeOnboarding() async {
    // Write persona to Firestore via personaProvider
    await _personaNotifier.updatePersona(PersonaModel(
      name: state.aiName,
      personalityType: state.personalityType,
      currentMood: AvatarMood.happy,
    ));
    await _personaNotifier.setStartDate();

    // Flip onboardingComplete on the anchor doc via authProvider
    await _ref.read(authProvider.notifier).completeOnboarding();

    _ref.read(onboardingCompleteProvider.notifier).state = true;
    state = state.copyWith(isComplete: true);
  }
}