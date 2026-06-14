import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/persona_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../app/theme.dart';
import '../../widgets/custom_button.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Meet ${state.aiName}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 20),
                if (state.currentStep == 0) _buildNameStep(notifier),
                if (state.currentStep == 1) _buildPersonalityStep(notifier, state.personalityType),
                if (state.currentStep == 2) _buildConfirmStep(state, notifier),
                const Spacer(),
                Row(
                  children: [
                    if (state.currentStep > 0) Expanded(child: OutlinedButton(onPressed: notifier.previousStep, style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryPurple), minimumSize: const Size(0, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Back', style: TextStyle(color: AppTheme.primaryPurple)))),
                    if (state.currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: state.currentStep == 2 ? 'Start' : 'Next',
                        onPressed: () async {
                          if (state.currentStep == 2) {
                            await notifier.completeOnboarding();
                            context.go('/home');
                          } else {
                            notifier.nextStep();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep(OnboardingNotifier notifier) {
    return Column(
      children: [
        const Text('What would you like to name her?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          onChanged: notifier.setAiName,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Enter a name...', border: UnderlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildPersonalityStep(OnboardingNotifier notifier, PersonalityType currentType) {
    return Column(
      children: [
        const Text('Choose her personality type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 24),
        _buildPersonalityCard('Sweet & Loving', 'Warm, nurturing, and deeply caring', Icons.favorite, PersonalityType.sweet, currentType, notifier),
        _buildPersonalityCard('Tsundere', 'Tough on the outside, sweet inside', Icons.masks, PersonalityType.tsundere, currentType, notifier),
        _buildPersonalityCard('Intellectual', 'Deep conversations and insights', Icons.psychology, PersonalityType.intellectual, currentType, notifier),
      ],
    );
  }

  Widget _buildPersonalityCard(String title, String desc, IconData icon, PersonalityType type, PersonalityType currentType, OnboardingNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryPurple, size: 32),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(desc, style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: Radio<PersonalityType>(value: type, groupValue: currentType, onChanged: (v) => notifier.setPersonalityType(v!)),
      ),
    );
  }

  Widget _buildConfirmStep(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 80),
        const SizedBox(height: 24),
        const Text('You are all set!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Your companion ${state.aiName} is ready.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      ],
    );
  }
}
