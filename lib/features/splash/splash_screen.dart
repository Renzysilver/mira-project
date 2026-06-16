import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/dreamy_background.dart';

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

    // 0 -> 1 over 2.4s, then navigate
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progress = CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic);

    Future.delayed(const Duration(milliseconds: 200), () {
      _progressController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/auth/login');
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
      body: DreamyBackground(
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

                      // Progress bar
                      SizedBox(
                        width: 220,
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progress.value,
                                  minHeight: 3,
                                  backgroundColor: Colors.white.withOpacity(0.08),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.magentaAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${(_progress.value * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary.withOpacity(0.7),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
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
