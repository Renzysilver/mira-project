import 'dart:math';
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
      // Scaffold provides the Material ancestor required by TextField,
      // SwitchListTile, ListTile, etc. Without it, those widgets throw
      // 'No Material widget found' at runtime.
      body: AtmosphericBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Cherry blossom + brand mark
                const _BlossomIcon(size: 36),
                const SizedBox(height: 16),

                // Step title
                ShaderMask(
                  shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                  child: Text(
                    _stepTitle(state.currentStep),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 2,
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

                // Step content
                Expanded(
                  child: switch (state.currentStep) {
                    0 => _NameStep(notifier: notifier, aiName: state.aiName),
                    1 => _PersonalityStep(
                        notifier: notifier,
                        current: state.personalityType,
                      ),
                    _ => _ConfirmStep(state: state),
                  },
                ),

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
                              if (context.mounted) context.go('/chat');
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

    return ListView.builder(
      itemCount: personalities.length,
      itemBuilder: (_, i) {
        final p = personalities[i];
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
      },
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

// ── Cherry blossom icon (shared) ──────────────────────────────────────

class _BlossomIcon extends StatelessWidget {
  final double size;
  const _BlossomIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BlossomPainter()),
    );
  }
}

class _BlossomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final petalRadius = canvasSize.width * 0.22;
    final distance = canvasSize.width * 0.22;

    final petalPaint = Paint()
      ..color = AppTheme.moonRose
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = AppTheme.magentaAccent
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi - pi / 2;
      final dx = center.dx + distance * cos(angle);
      final dy = center.dy + distance * sin(angle);
      canvas.drawCircle(Offset(dx, dy), petalRadius, petalPaint);
    }
    canvas.drawCircle(center, canvasSize.width * 0.08, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
