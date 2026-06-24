import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/persona_model.dart';
import '../../providers/onboarding_provider.dart';
import '../../app/theme.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      // resizeToAvoidBottomInset defaults to true — the Scaffold
      // automatically shrinks the body to exclude the keyboard area.
      // Combined with SingleChildScrollView below, this keeps the
      // focused TextField visible without manual viewInsets math.
      resizeToAvoidBottomInset: true,
      body: AtmosphericBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: SingleChildScrollView(
              // Ensures the input field scrolls into view when focused.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                // Step title (large sakura decoration removed per
                // user request — only small floating petals remain via
                // AtmosphericBackground)
                ShaderMask(
                  shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                  child: Text(
                    _stepTitle(state.currentStep),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: AppTheme.magentaAccent.withOpacity(0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stepSubtitle(state.currentStep),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final isActive = i == state.currentStep;
                    final isDone = i < state.currentStep;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive || isDone
                            ? AppTheme.magentaAccent
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Step content — no Expanded (we're inside a scroll view
                // which has unbounded height). Each step sizes itself.
                switch (state.currentStep) {
                  0 => _NameStep(notifier: notifier, aiName: state.aiName),
                  1 => _PersonalityStep(
                      notifier: notifier,
                      current: state.personalityType,
                    ),
                  _ => _ConfirmStep(state: state),
                },

                // Nav buttons
                Row(
                  children: [
                    if (state.currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: notifier.previousStep,
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
                              color: AppTheme.magentaAccent.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (state.currentStep == 2) {
                              await notifier.completeOnboarding();
                              if (context.mounted) context.go('/home');
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
                          child: Text(
                            state.currentStep == 2 ? 'Begin' : 'Next',
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
                const SizedBox(height: 24),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
        0 => 'Name her',
        1 => 'Her spirit',
        _ => 'All set',
      };

  String _stepSubtitle(int step) => switch (step) {
        0 => 'What shall she be called?',
        1 => 'Choose her personality',
        _ => 'Your companion awaits',
      };
}

// ── Step widgets ──────────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  final OnboardingNotifier notifier;
  final String aiName;
  const _NameStep({required this.notifier, required this.aiName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            children: [
              const Text('your companion\'s name',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2)),
              const SizedBox(height: 12),
              TextField(
                onChanged: notifier.setAiName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.moonWhite,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: 'Mira',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.4),
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          aiName.isEmpty
              ? 'she\'s waiting for a name ✦'
              : '$aiName — a beautiful name',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PersonalityStep extends StatelessWidget {
  final OnboardingNotifier notifier;
  final PersonalityType current;
  const _PersonalityStep({required this.notifier, required this.current});

  @override
  Widget build(BuildContext context) {
    final personalities = [
      _PersonalityOption(
        type: PersonalityType.sweet,
        name: 'Sweet & Caring',
        desc: 'Warm, nurturing, freely loving',
        icon: Icons.favorite_outline_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFE83E8C), Color(0xFFFFB7C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _PersonalityOption(
        type: PersonalityType.tsundere,
        name: 'Tsundere',
        desc: 'Sharp outside, soft inside',
        icon: Icons.masks_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF5A189A), Color(0xFF9B6DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _PersonalityOption(
        type: PersonalityType.intellectual,
        name: 'Intellectual',
        desc: 'Curious, thoughtful, deep',
        icon: Icons.psychology_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF204080), Color(0xFFA7C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    // Use Column instead of ListView.builder — we're now inside a
    // SingleChildScrollView, and nested scrollables cause unbounded
    // height errors.
    return Column(
      children: personalities.map((p) {
        final isSelected = p.type == current;
        return GestureDetector(
          onTap: () => notifier.setPersonalityType(p.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.glassWhite
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppTheme.magentaAccent
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.magentaAccent.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: p.gradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.moonWhite,
                          letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(p.desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        )),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                    color: AppTheme.magentaAccent, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PersonalityOption {
  final PersonalityType type;
  final String name;
  final String desc;
  final IconData icon;
  final Gradient gradient;
  const _PersonalityOption({
    required this.type,
    required this.name,
    required this.desc,
    required this.icon,
    required this.gradient,
  });
}

class _ConfirmStep extends StatelessWidget {
  final OnboardingState state;
  const _ConfirmStep({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.pinkGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.magentaAccent.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
              color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(state.aiName.isEmpty ? 'Mira' : state.aiName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              color: AppTheme.moonWhite,
              letterSpacing: 4)),
          const SizedBox(height: 6),
          const Text('is ready for you',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
              fontStyle: FontStyle.italic)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              children: [
                const Text('personality',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(_personalityName(state.personalityType),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.moonWhite,
                    letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _personalityName(PersonalityType t) => switch (t) {
        PersonalityType.sweet => 'Sweet & Caring',
        PersonalityType.tsundere => 'Tsundere',
        PersonalityType.intellectual => 'Intellectual',
      };
}
