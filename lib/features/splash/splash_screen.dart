import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fade;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progress = CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic);

    Future.delayed(const Duration(milliseconds: 200), () {
      _progressController.forward();
    });

    // After the splash branding delay, navigate based on auth state.
    // FirebaseAuth.instance.currentUser is synchronous after the first
    // persistence restore, so this is safe to check here.
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go('/home');
      } else {
        context.go('/auth/login');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Centered logo + tagline + progress
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cherry blossom icon
                      const _CherryBlossom(),
                      const SizedBox(height: 32),

                      // MIRA wordmark
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.auroraGradient.createShader(b),
                        child: const Text(
                          'MIRA',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            letterSpacing: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tagline
                      const Text(
                        'Your AI Companion Beyond the Stars',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 64),

                      // Circular glowing progress indicator
                      // Glow intensity scales with progress: 0% = soft,
                      // 100% = max glow before transition.
                      // Size reduced to 48px (50% of original 96px) for
                      // a more refined, premium appearance.
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => _GlowingCircularProgress(
                          progress: _progress.value,
                          size: 48,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Percentage text
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => Text(
                          '${(_progress.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'MIRA  •  Built with Flutter  •  Crafted with Love',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple stylised cherry blossom icon — five petals around a center.
class _CherryBlossom extends StatelessWidget {
  const _CherryBlossom();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _BlossomPainter()),
    );
  }
}

class _BlossomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalRadius = size.width * 0.22;
    final distance = size.width * 0.22;

    final petalPaint = Paint()
      ..color = AppTheme.moonRose
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = AppTheme.magentaAccent
      ..style = PaintingStyle.fill;

    // 5 petals arranged in a circle
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi - pi / 2;
      final dx = center.dx + distance * cos(angle);
      final dy = center.dy + distance * sin(angle);
      canvas.drawCircle(Offset(dx, dy), petalRadius, petalPaint);
    }

    // Center
    canvas.drawCircle(center, size.width * 0.08, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular progress indicator with a pink aurora glow that intensifies
/// as progress increases. Uses CustomPainter for the ring + sweep, and
/// a layered radial gradient for the glow.
class _GlowingCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;

  const _GlowingCircularProgress({
    required this.progress,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Glow intensity scales strongly with progress for visual feedback:
    // 0% = faint (0.10), 25% = slight (0.25), 50% = moderate (0.45),
    // 75% = strong (0.65), 100% = max (0.85).
    final glowOpacity = 0.10 + (progress * 0.75);
    // Glow radius also grows: 0.7x to 1.1x of the circle size.
    final glowRadius = size * (0.7 + progress * 0.4);

    return SizedBox(
      width: glowRadius * 2 + 8, // room for the glow
      height: glowRadius * 2 + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer — radial gradient behind the ring
          Container(
            width: glowRadius * 2,
            height: glowRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.magentaAccent.withOpacity(glowOpacity),
                  AppTheme.moonRose.withOpacity(glowOpacity * 0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // The ring itself
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress,
              strokeWidth: strokeWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc — starts at top (-90°), sweeps clockwise
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Gradient sweep from magenta to moonRose
    progressPaint.shader = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + (2 * pi * progress.clamp(0.0, 1.0)),
      colors: [
        AppTheme.magentaAccent,
        AppTheme.moonRose,
      ],
      stops: const [0.0, 1.0],
      transform: GradientRotation(-pi / 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw the arc only if there's progress
    if (progress > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
