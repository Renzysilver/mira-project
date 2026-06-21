import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Dark atmospheric background — subtle orbs + faint particles.
/// No bright purple, no saturated colors. Deep navy base with
/// very soft purple/pink glow accents.
class AtmosphericBackground extends StatefulWidget {
  final Widget child;
  final bool showMist;
  final bool showPetals;
  final bool showRadialGlow;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.showMist = false,
    this.showPetals = true,
    this.showRadialGlow = true,
  });

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final List<_Petal> _petals = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 40; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.6,
        radius: _rng.nextDouble() * 1.0 + 0.3,
        twinklePhase: _rng.nextDouble() * 2 * pi,
        twinkleSpeed: 0.5 + _rng.nextDouble() * 1.0,
        baseOpacity: 0.15 + _rng.nextDouble() * 0.25,
      ));
    }

    for (int i = 0; i < 12; i++) {
      _petals.add(_Petal(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 3 + _rng.nextDouble() * 5,
        speed: 0.03 + _rng.nextDouble() * 0.05,
        drift: (_rng.nextDouble() - 0.5) * 0.1,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
        wobblePhase: _rng.nextDouble() * 2 * pi,
        wobbleAmplitude: 0.015 + _rng.nextDouble() * 0.03,
        opacity: 0.15 + _rng.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.background,
                  AppTheme.surfaceDark,
                  AppTheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                // Stars
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StarFieldPainter(_stars, t),
                    size: Size.infinite,
                  ),
                ),

                // Aurora ribbon (very subtle)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AuroraPainter(t),
                    size: Size.infinite,
                  ),
                ),

                // Radial glow
                if (widget.showRadialGlow)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RadialGlowPainter(t),
                      size: Size.infinite,
                    ),
                  ),

                // Petals
                if (widget.showPetals)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PetalPainter(_petals, t),
                      size: Size.infinite,
                    ),
                  ),

                // Mist
                if (widget.showMist)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MistPainter(t),
                      size: Size.infinite,
                    ),
                  ),
              ],
            );
          },
        ),

        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Star {
  final double x, y, radius, twinklePhase, twinkleSpeed, baseOpacity;
  const _Star({
    required this.x, required this.y, required this.radius,
    required this.twinklePhase, required this.twinkleSpeed,
    required this.baseOpacity,
  });
}

class _Petal {
  final double x, y, size, speed, drift, rotation, rotationSpeed;
  final double wobblePhase, wobbleAmplitude, opacity;
  const _Petal({
    required this.x, required this.y, required this.size,
    required this.speed, required this.drift, required this.rotation,
    required this.rotationSpeed, required this.wobblePhase,
    required this.wobbleAmplitude, required this.opacity,
  });
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarFieldPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final twinkle = (sin(t * 2 * pi * s.twinkleSpeed + s.twinklePhase) * 0.5 + 0.5);
      final opacity = (s.baseOpacity * (0.4 + 0.6 * twinkle)).clamp(0.0, 0.4);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 2; i++) {
      final phase = t * 2 * pi + (i * pi);
      final x = (0.5 + 0.2 * sin(phase)) * size.width;
      final y = size.height * (0.2 + 0.1 * cos(phase * 0.7));
      final rect = Rect.fromCircle(center: Offset(x, y), radius: size.width * 0.3);
      final gradient = RadialGradient(
        colors: [
          AppTheme.purple.withOpacity(0.06),
          AppTheme.pink.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RadialGlowPainter extends CustomPainter {
  final double t;
  _RadialGlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (sin(t * 2 * pi * 0.2) * 0.5 + 0.5);
    final opacity = 0.03 + 0.04 * pulse;
    final center = Offset(size.width * 0.5, size.height * 0.4);
    final radius = size.width * 0.6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = RadialGradient(
      colors: [
        AppTheme.purple.withOpacity(opacity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t;
  _PetalPainter(this.petals, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final cycleProgress = (t * p.speed + p.y) % 1.0;
      final wobble = sin(t * 2 * pi + p.wobblePhase) * p.wobbleAmplitude;
      final x = ((p.x + p.drift * cycleProgress + wobble) % 1.0) * size.width;
      final y = cycleProgress * size.height;
      final rotation = p.rotation + t * 2 * pi * p.rotationSpeed;
      final edgeFade = cycleProgress < 0.1
          ? cycleProgress / 0.1
          : (cycleProgress > 0.9 ? (1.0 - cycleProgress) / 0.1 : 1.0);
      final opacity = p.opacity * edgeFade;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final petalPaint = Paint()
        ..color = AppTheme.pinkLight.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill;
      final petalRadius = p.size * 0.3;
      final distance = p.size * 0.3;
      for (int i = 0; i < 5; i++) {
        final angle = (i / 5) * 2 * pi - pi / 2;
        canvas.drawCircle(
          Offset(distance * cos(angle), distance * sin(angle)),
          petalRadius, petalPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MistPainter extends CustomPainter {
  final double t;
  _MistPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final drift = (t * 0.05) % 1.0;
    for (int i = 0; i < 2; i++) {
      final y = size.height * (0.65 + i * 0.1) - drift * 30;
      final rect = Rect.fromLTWH(-size.width * 0.2, y, size.width * 1.4, size.height * 0.4);
      final gradient = LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.surfaceDark.withOpacity(0.08),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
