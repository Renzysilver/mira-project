import 'dart:math';
import 'package:flutter/material.dart';

import '../models/persona_model.dart';
import '../app/theme.dart';

class AnimatedAvatar extends StatefulWidget {
  final AvatarMood mood;
  final double size;
  final bool isSpeaking;
  const AnimatedAvatar({super.key, required this.mood, this.size = 200, this.isSpeaking = false});

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _floatController;
  late AnimationController _speakController;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);
    _speakController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat(reverse: true);
    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(3000)), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) { setState(() => _isBlinking = false); _startBlinking(); }
      });
    });
  }

  @override
  void dispose() { _breathController.dispose(); _floatController.dispose(); _speakController.dispose(); super.dispose(); }

  Color get _faceColor {
    switch (widget.mood) {
      case AvatarMood.happy: case AvatarMood.excited: return const Color(0xFFFFB7C5);
      case AvatarMood.shy: case AvatarMood.flirty: return const Color(0xFFFFA0B8);
      case AvatarMood.sad: return const Color(0xFFB8C0FF);
      case AvatarMood.thinking: return const Color(0xFFC5CAFF);
      case AvatarMood.sleepy: return const Color(0xFFD0C5FF);
      case AvatarMood.neutral: return const Color(0xFFD4B8FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathController, _floatController, _speakController]),
      builder: (context, child) {
        final floatOffset = sin(_floatController.value * pi) * 5;
        final speakScale = widget.isSpeaking ? 1.0 + sin(_speakController.value * pi) * 0.05 : 1.0;
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: SizedBox(
            width: widget.size, height: widget.size,
            child: Center(
              child: Container(
                width: widget.size * 0.8, height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_faceColor, _faceColor.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hair
                    Positioned(
                      top: widget.size * 0.05,
                      child: Container(
                        width: widget.size * 0.75, height: widget.size * 0.4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B3FA0),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(widget.size * 0.35),
                            topRight: Radius.circular(widget.size * 0.35),
                          ),
                        ),
                      ),
                    ),
                    // Eyes
                    Positioned(
                      top: widget.size * 0.3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildEye(_isBlinking),
                          SizedBox(width: widget.size * 0.15),
                          _buildEye(_isBlinking),
                        ],
                      ),
                    ),
                    // Mouth
                    Positioned(
                      top: widget.size * 0.48,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: widget.isSpeaking ? widget.size * 0.15 : widget.size * 0.1,
                        height: widget.isSpeaking ? widget.size * 0.12 : widget.size * 0.05,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B8A),
                          borderRadius: BorderRadius.circular(widget.size * 0.1),
                        ),
                      ),
                    ),
                    // Blush
                    if (widget.mood == AvatarMood.shy || widget.mood == AvatarMood.flirty) ...[
                      Positioned(top: widget.size * 0.42, left: widget.size * 0.15, child: _buildBlush()),
                      Positioned(top: widget.size * 0.42, right: widget.size * 0.15, child: _buildBlush()),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEye(bool blink) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: widget.size * 0.08,
      height: blink ? widget.size * 0.02 : widget.size * 0.08,
      decoration: BoxDecoration(color: const Color(0xFF2A1B3D), borderRadius: BorderRadius.circular(widget.size * 0.1)),
    );
  }

  Widget _buildBlush() {
    return Container(
      width: widget.size * 0.1, height: widget.size * 0.05,
      decoration: BoxDecoration(color: Colors.pink.withOpacity(0.3), borderRadius: BorderRadius.circular(widget.size * 0.1)),
    );
  }
}
