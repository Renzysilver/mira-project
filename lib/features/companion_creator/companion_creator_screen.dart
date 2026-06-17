import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/persona_model.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import 'companion_creator_provider.dart';
import 'companion_creator_state.dart';
import 'steps/identity_step.dart';
import 'steps/personality_step.dart';
import 'steps/appearance_step.dart';
import 'steps/voice_step.dart';
import 'steps/interests_step.dart';
import 'steps/review_step.dart';

class CompanionCreatorScreen extends ConsumerWidget {
  const CompanionCreatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    return Scaffold(
      body: AtmosphericBackground(
        showMist: false,
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (state.currentStep > 0) {
                          notifier.previousStep();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.moonWhite, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CREATE COMPANION',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary
                                    .withOpacity(0.7),
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            _stepTitle(state.currentStep),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Step counter
                    Text(
                      '${state.currentStep + 1}/${CompanionCreatorState.totalSteps}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Progress bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(
                    CompanionCreatorState.totalSteps,
                    (i) {
                      final isActive = i == state.currentStep;
                      final isDone = i < state.currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              right: i ==
                                      CompanionCreatorState.totalSteps - 1
                                  ? 0
                                  : 4),
                          height: 3,
                          decoration: BoxDecoration(
                            color: isActive || isDone
                                ? AppTheme.magentaAccent
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Step content ─────────────────────────────────────────
              Expanded(
                child: switch (state.currentStep) {
                  0 => const IdentityStep(),
                  1 => const PersonalityStep(),
                  2 => const AppearanceStep(),
                  3 => const VoiceStep(),
                  4 => const InterestsStep(),
                  _ => const ReviewStep(),
                },
              ),

              // ── Error ────────────────────────────────────────────────
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                        color: AppTheme.errorRed, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ── Nav buttons ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Row(
                  children: [
                    if (state.currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSaving
                              ? null
                              : notifier.previousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                            minimumSize: const Size(0, 54),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: const Text('Back',
                              style: TextStyle(letterSpacing: 1.5)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppTheme.pinkGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.magentaAccent
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                  if (state.currentStep ==
                                      CompanionCreatorState.totalSteps -
                                          1) {
                                    final id = await notifier.save();
                                    if (id != null && context.mounted) {
                                      notifier.reset();
                                      context.go('/home');
                                    }
                                  } else {
                                    notifier.nextStep();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  state.currentStep ==
                                          CompanionCreatorState.totalSteps -
                                              1
                                      ? 'Create'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
        0 => 'Identity',
        1 => 'Personality',
        2 => 'Appearance',
        3 => 'Voice',
        4 => 'Interests',
        _ => 'Review',
      };
}
