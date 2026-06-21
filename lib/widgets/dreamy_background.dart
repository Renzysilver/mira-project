import 'dart:math';
import 'package:flutter/material.dart';

class DreamyBackground extends StatefulWidget {
  final Widget child;
  final bool showPetals;
  const DreamyBackground({super.key, required this.child, this.showPetals = true});

  @override
  State<DreamyBackground> createState() => _DreamyBackgroundState();
}

class _DreamyBackgroundState extends State<DreamyBackground>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _petalController;
  late AnimationController _shimmerController;
  final List<_Petal> _petals = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _petalController = AnimationController(
      vsync: this, duration: const Duration(seconds: 12))..repeat();
    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

    for (int i = 0; i < 12; i++) {
      _petals.add(_Petal(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 8 + 4,
        speed: _random.nextDouble() * 0.3 + 0.1,
        drift: _random.nextDouble() * 0.1 - 0.05,
        opacity: _random.nextDouble() * 0.5 + 0.2,
        rotation: _random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _petalController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080B18), Color(0xFF12082A), Color(0xFF1A0A2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Animated orbs
        AnimatedBuilder(
          animation: _orbController,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _OrbPainter(_orbController.value),
          ),
        ),

        // Mist at bottom
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (_, __) => Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFC9A7FF).withOpacity(0.04 + _shimmerController.value * 0.03),
                    const Color(0xFFFFB7C5).withOpacity(0.06 + _shimmerController.value * 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // Floating petals
        if (widget.showPetals)
          AnimatedBuilder(
            animation: _petalController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _PetalPainter(_petals, _petalController.value),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _Petal {
  double x, y, size, speed, drift, opacity, rotation;
  _Petal({
    required this.x, required this.y, required this.size,
    required this.speed, required this.drift,
    required this.opacity, required this.rotation,
  });
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Soft lavender orb top left
    _drawOrb(canvas, Offset(size.width * 0.15, size.height * (0.15 + t * 0.08)),
        size.width * 0.45, const Color(0xFFC9A7FF), 0.06 + t * 0.02);
    // Rose orb bottom right
    _drawOrb(canvas, Offset(size.width * (0.75 + t * 0.05), size.height * 0.75),
        size.width * 0.5, const Color(0xFFFFB7C5), 0.05 + t * 0.02);
    // Blue orb center
    _drawOrb(canvas, Offset(size.width * 0.5, size.height * (0.4 - t * 0.05)),
        size.width * 0.3, const Color(0xFFA7C4FF), 0.04 + t * 0.015);
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}

class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t;
  _PetalPainter(this.petals, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final y = (petal.y + t * petal.speed) % 1.0;
      final x = petal.x + sin(t * pi * 2 + petal.x * 10) * petal.drift;
      final offset = Offset(x * size.width, y * size.height);
      final paint = Paint()
        ..color = const Color(0xFFFFB7C5).withOpacity(petal.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(petal.rotation + t * pi);
      // Draw simple petal shape
      final path = Path()
        ..moveTo(0, -petal.size)
        ..quadraticBezierTo(petal.size * 0.8, -petal.size * 0.5, 0, 0)
        ..quadraticBezierTo(-petal.size * 0.8, -petal.size * 0.5, 0, -petal.size);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => old.t != t;
}
