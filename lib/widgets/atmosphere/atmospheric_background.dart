import 'dart:math';
import 'package:flutter/material.dart';

/// A layered, animated atmospheric background that gives every screen in
/// the app the "magical, dreamlike, premium, cinematic" feel from the
/// PROJECT MIRA master vision document.
///
/// Six layers, rendered bottom-to-top via CustomPainter + AnimationController:
///   1. Vertical aurora gradient (deep purple -> indigo -> near-black)
///   2. Animated star particles (twinkling, biased to upper portion)
///   3. Color-shifting aurora ribbon (horizontal flow at top)
///   4. Radial avatar glow (center-biased purple/pink halo)
///   5. Floating sakura petals (drift down + wobble + rotation)
///   6. Soft mist layer (bottom third, drifts upward)
///
/// All layers are pure CustomPainter — no image assets — so this stays
/// under 60fps even on mid-range devices.
///
/// Use anywhere you'd otherwise put a flat gradient or DreamyBackground:
///   AtmosphericBackground(child: ...)
class AtmosphericBackground extends StatefulWidget {
  final Widget child;

  /// Set to false to disable the mist layer (useful for chat screens
  /// where the bottom area is busy with input fields).
  final bool showMist;

  /// Set to false to disable sakura petals (useful for very dense screens
  /// like onboarding forms where petals would distract).
  final bool showPetals;

  /// Set to false to disable the radial center glow (useful for screens
  /// where the avatar isn't centered, like settings).
  final bool showRadialGlow;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.showMist = true,
    this.showPetals = true,
    this.showRadialGlow = true,
  });

  @override
  State<AtmosphericBackground> createState() => _AtmosphericBackgroundState();
}

class _AtmosphericBackgroundState extends State<AtmosphericBackground>
    with TickerProviderStateMixin {
  // Single controller drives all layers — they each derive their own
  // phase from the same elapsed time. Cheaper than 5 separate controllers.
  late AnimationController _controller;

  // Pre-generated particle data so we don't re-randomize every frame.
  final List<_Star> _stars = [];
  final List<_Petal> _petals = [];
  final Random _rng = Random();

  static const int _starCount = 80;
  static const int _petalCount = 22;

  @override
  void initState() {
    super.initState();

    // 24s loop is long enough that the eye doesn't catch the repeat.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // Stars: biased to upper 60% of screen, small radii, varied twinkle phase
    for (int i = 0; i < _starCount; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.6, // upper 60%
        radius: _rng.nextDouble() * 1.2 + 0.4,
        twinklePhase: _rng.nextDouble() * 2 * pi,
        twinkleSpeed: 0.5 + _rng.nextDouble() * 1.5,
        baseOpacity: 0.3 + _rng.nextDouble() * 0.5,
      ));
    }

    // Petals: spread across the screen, varied size/speed/drift
    for (int i = 0; i < _petalCount; i++) {
      _petals.add(_Petal(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 4 + _rng.nextDouble() * 8, // 4-12px
        speed: 0.04 + _rng.nextDouble() * 0.08, // slow drift
        drift: (_rng.nextDouble() - 0.5) * 0.15,
        rotation: _rng.nextDouble() * 2 * pi,
        rotationSpeed: (_rng.nextDouble() - 0.5) * 0.5,
        wobblePhase: _rng.nextDouble() * 2 * pi,
        wobbleAmplitude: 0.02 + _rng.nextDouble() * 0.04,
        opacity: 0.4 + _rng.nextDouble() * 0.4,
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
        // Layer 1: Base aurora gradient (always present, no animation)
        const Positioned.fill(child: _AuroraGradientLayer()),

        // Layers 2-6: animated, all driven by the single controller.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                // Layer 2: Stars
                Positioned.fill(child: _StarFieldLayer(stars: _stars, t: t)),

                // Layer 3: Aurora ribbon (color-shifting, top of screen)
                Positioned.fill(child: _AuroraRibbonLayer(t: t)),

                // Layer 4: Radial center glow
                if (widget.showRadialGlow)
                  Positioned.fill(child: _RadialGlowLayer(t: t)),

                // Layer 5: Sakura petals
                if (widget.showPetals)
                  Positioned.fill(
                      child: _PetalLayer(petals: _petals, t: t)),

                // Layer 6: Mist at bottom
                if (widget.showMist)
                  Positioned.fill(child: _MistLayer(t: t)),
              ],
            );
          },
        ),

        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

// ── Data classes ────────────────────────────────────────────────────────

class _Star {
  final double x, y, radius, twinklePhase, twinkleSpeed, baseOpacity;
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.baseOpacity,
  });
}

class _Petal {
  final double x, y, size, speed, drift, rotation, rotationSpeed;
  final double wobblePhase, wobbleAmplitude, opacity;
  const _Petal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobblePhase,
    required this.wobbleAmplitude,
    required this.opacity,
  });
}

// ── Layer 1: Aurora gradient ────────────────────────────────────────────

class _AuroraGradientLayer extends StatelessWidget {
  const _AuroraGradientLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4A1C8A), // bright ethereal purple (top sky)
            const Color(0xFF6A2A8A), // pink-tinted mid-sky
            const Color(0xFF1A1A3A), // deep indigo horizon
            const Color(0xFF2A2A5A), // blue-tinted lower
            const Color(0xFF050510), // near-black ground
          ],
          stops: const [0.0, 0.18, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }
}

// ── Layer 2: Star field ─────────────────────────────────────────────────

class _StarFieldLayer extends StatelessWidget {
  final List<_Star> stars;
  final double t;
  const _StarFieldLayer({required this.stars, required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarFieldPainter(stars, t),
      size: Size.infinite,
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarFieldPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final s in stars) {
      // Twinkle: sin wave modulates opacity around the base.
      final twinkle =
          (sin(t * 2 * pi * s.twinkleSpeed + s.twinklePhase) * 0.5 + 0.5);
      final opacity = (s.baseOpacity * (0.4 + 0.6 * twinkle)).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(opacity);

      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) => true;
}

// ── Layer 3: Aurora ribbon (color-shifting horizontal flow) ─────────────

class _AuroraRibbonLayer extends StatelessWidget {
  final double t;
  const _AuroraRibbonLayer({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuroraRibbonPainter(t),
      size: Size.infinite,
    );
  }
}

class _AuroraRibbonPainter extends CustomPainter {
  final double t;
  _AuroraRibbonPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // The aurora ribbon sweeps horizontally across the top third.
    // We draw 3 overlapping radial gradients that drift with t.
    final ribbonHeight = size.height * 0.4;

    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * pi + (i * 2 * pi / 3);
      // x drifts between 0.2 and 0.8 of width
      final x = (0.5 + 0.3 * sin(phase)) * size.width;
      final y = ribbonHeight * (0.3 + 0.2 * cos(phase * 0.7));

      // Color cycles through purple -> pink -> blue
      final colorPhase = (t + i * 0.33) % 1.0;
      final color = _lerpAuroraColor(colorPhase);

      final rect = Rect.fromCircle(
        center: Offset(x, y),
        radius: size.width * 0.35,
      );
      final gradient = RadialGradient(
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.1),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, ribbonHeight),
        paint,
      );
    }
  }

  Color _lerpAuroraColor(double phase) {
    // 0.0 -> purple, 0.33 -> pink, 0.66 -> blue, 1.0 -> back to purple
    if (phase < 0.33) {
      return Color.lerp(
        const Color(0xFF6A2A8A),
        const Color(0xFFE83E8C),
        phase / 0.33,
      )!;
    } else if (phase < 0.66) {
      return Color.lerp(
        const Color(0xFFE83E8C),
        const Color(0xFF3A1C7A),
        (phase - 0.33) / 0.33,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFF3A1C7A),
        const Color(0xFF6A2A8A),
        (phase - 0.66) / 0.34,
      )!;
    }
  }

  @override
  bool shouldRepaint(_AuroraRibbonPainter oldDelegate) => true;
}

// ── Layer 4: Radial center glow ─────────────────────────────────────────

class _RadialGlowLayer extends StatelessWidget {
  final double t;
  const _RadialGlowLayer({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadialGlowPainter(t),
      size: Size.infinite,
    );
  }
}

class _RadialGlowPainter extends CustomPainter {
  final double t;
  _RadialGlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Slow pulse on the center glow — opacity 0.08 -> 0.16.
    final pulse = (sin(t * 2 * pi * 0.25) * 0.5 + 0.5);
    final opacity = 0.08 + 0.08 * pulse;

    final center = Offset(size.width * 0.5, size.height * 0.45);
    final radius = size.width * 0.6;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFE83E8C).withOpacity(opacity),
        const Color(0xFF6A2A8A).withOpacity(opacity * 0.6),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_RadialGlowPainter oldDelegate) => true;
}

// ── Layer 5: Sakura petals ──────────────────────────────────────────────

class _PetalLayer extends StatelessWidget {
  final List<_Petal> petals;
  final double t;
  const _PetalLayer({required this.petals, required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PetalPainter(petals, t),
      size: Size.infinite,
    );
  }
}

class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t;
  _PetalPainter(this.petals, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      // Position cycles: y goes 0 -> 1 over (1/speed) loop iterations.
      final cycleProgress = (t * p.speed + p.y) % 1.0;

      // Wobble: horizontal sinusoidal drift.
      final wobble = sin(t * 2 * pi + p.wobblePhase) * p.wobbleAmplitude;

      final x = ((p.x + p.drift * cycleProgress + wobble) % 1.0) * size.width;
      final y = cycleProgress * size.height;
      final rotation = p.rotation + t * 2 * pi * p.rotationSpeed;

      // Fade in at top, fade out at bottom for smooth recycling.
      final edgeFade = (cycleProgress < 0.1)
          ? cycleProgress / 0.1
          : (cycleProgress > 0.9
              ? (1.0 - cycleProgress) / 0.1
              : 1.0);
      final opacity = p.opacity * edgeFade;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      _drawPetal(canvas, p.size, opacity);
      canvas.restore();
    }
  }

  void _drawPetal(Canvas canvas, double size, double opacity) {
    // Stylised 5-petal sakura: 5 small circles around a center.
    final petalPaint = Paint()
      ..color = const Color(0xFFFFB7C5).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = const Color(0xFFE83E8C).withOpacity(opacity * 0.8)
      ..style = PaintingStyle.fill;

    final petalRadius = size * 0.35;
    final distance = size * 0.35;

    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi - pi / 2;
      canvas.drawCircle(
        Offset(distance * cos(angle), distance * sin(angle)),
        petalRadius,
        petalPaint,
      );
    }
    canvas.drawCircle(Offset.zero, size * 0.12, centerPaint);
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) => true;
}

// ── Layer 6: Mist at bottom ─────────────────────────────────────────────

class _MistLayer extends StatelessWidget {
  final double t;
  const _MistLayer({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MistPainter(t),
      size: Size.infinite,
    );
  }
}

class _MistPainter extends CustomPainter {
  final double t;
  _MistPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Two overlapping translucent gradients drifting upward.
    final baseY = size.height * 0.7;
    final drift = (t * 0.1) % 1.0;
    final y1 = baseY - drift * 40;
    final y2 = baseY + 20 - drift * 60;

    for (int i = 0; i < 2; i++) {
      final y = i == 0 ? y1 : y2;
      final rect = Rect.fromLTWH(
        -size.width * 0.2,
        y,
        size.width * 1.4,
        size.height * 0.5,
      );
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF1A1A3A).withOpacity(i == 0 ? 0.18 : 0.12),
          const Color(0xFF050510).withOpacity(i == 0 ? 0.25 : 0.18),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_MistPainter oldDelegate) => true;
}
