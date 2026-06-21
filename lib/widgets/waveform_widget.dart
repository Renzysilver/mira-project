import 'dart:math';
import 'package:flutter/material.dart';

/// Animated audio waveform visualizer for the call screen.
/// Shows 28 vertical bars that animate based on the call phase.
class AnimatedWaveform extends StatefulWidget {
  final String phase; // 'dialing', 'listening', 'thinking', 'speaking'
  final double maxHeight;

  const AnimatedWaveform({
    super.key,
    required this.phase,
    this.maxHeight = 48,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();
  List<double> _barHeights = List.filled(28, 0.1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _regenerateHeights();
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  void _regenerateHeights() {
    if (!mounted) return;
    setState(() {
      final intensity = switch (widget.phase) {
        'speaking' => 1.0,
        'listening' => 0.6,
        'thinking' => 0.15,
        _ => 0.0,
      };
      _barHeights = List.generate(28, (i) {
        if (intensity == 0) return 0.05;
        return 0.1 + _rng.nextDouble() * intensity;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _barColor => switch (widget.phase) {
        'speaking' => const Color(0xFFEC4899),
        'listening' => const Color(0xFF60A5FA),
        'thinking' => const Color(0xFF9CA3AF),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight + 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _barHeights.map((h) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: (h * widget.maxHeight).clamp(3.0, widget.maxHeight),
            decoration: BoxDecoration(
              color: _barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
