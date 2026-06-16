import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/mira_avatar.dart';
import '../../widgets/waveform_widget.dart';
import '../../app/theme.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});
  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _orbController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callProvider.notifier).startCall();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState   = ref.watch(callProvider);
    final personaState = ref.watch(personaProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Deep cosmic background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06050F), Color(0xFF0D0820), Color(0xFF150A28)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Animated ambient orbs
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _CallOrbPainter(_orbController.value,
                isSpeaking: callState.phase == CallPhase.speaking,
                isListening: callState.phase == CallPhase.listening),
            ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_particleController.value),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _GlassIconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        ref.read(callProvider.notifier).endCall();
                        context.go('/home');
                      },
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Phase label
                _PhaseLabel(phase: callState.phase, status: callState.status,
                  duration: callState.formattedDuration),

                const SizedBox(height: 24),

                // Avatar with glow ring
                _AvatarWithGlow(
                  personaName: personaState.persona.name,
                  phase: callState.phase,
                  pulseAnim: _pulseAnim,
                  isSpeaking: callState.phase == CallPhase.speaking,
                ),

                const SizedBox(height: 20),

                // Name
                Text(personaState.persona.name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w200,
                    color: AppTheme.moonWhite, letterSpacing: 3)),
                const SizedBox(height: 6),
                Text(personaState.persona.personalityType ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.5)),

                const SizedBox(height: 32),

                // Speech transcript bubble
                if (callState.lastAiSpeech.isNotEmpty || callState.lastUserSpeech.isNotEmpty)
                  _TranscriptBubble(
                    userText: callState.lastUserSpeech,
                    aiText: callState.lastAiSpeech,
                    name: personaState.persona.name,
                  ),

                const Spacer(flex: 2),

                // Controls
                _CallControls(
                  callState: callState,
                  onMute: () => ref.read(callProvider.notifier).toggleMute(),
                  onSpeaker: () => ref.read(callProvider.notifier).toggleSpeaker(),
                  onEnd: () {
                    ref.read(callProvider.notifier).endCall();
                    context.go('/home');
                  },
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PhaseLabel extends StatelessWidget {
  final CallPhase phase;
  final CallStatus status;
  final String duration;
  const _PhaseLabel({required this.phase, required this.status, required this.duration});

  @override
  Widget build(BuildContext context) {
    if (status == CallStatus.connected) {
      return Column(children: [
        Text(duration, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, letterSpacing: 2)),
        const SizedBox(height: 4),
        _phaseChip,
      ]);
    }
    if (status == CallStatus.ended) {
      return const Text('Call Ended',
        style: TextStyle(fontSize: 14, color: AppTheme.errorRed, letterSpacing: 2));
    }
    return _phaseChip;
  }

  Widget get _phaseChip {
    switch (phase) {
      case CallPhase.dialing:
        return _Chip(label: 'Ringing...', color: AppTheme.auroraBlue);
      case CallPhase.listening:
        return _Chip(label: '● Listening', color: AppTheme.successGreen);
      case CallPhase.thinking:
        return _Chip(label: '· · · Thinking', color: AppTheme.accentGold);
      case CallPhase.speaking:
        return _Chip(label: '♪ Speaking', color: AppTheme.moonRose);
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, letterSpacing: 1.5)),
    );
  }
}

class _AvatarWithGlow extends StatelessWidget {
  final String personaName;
  final CallPhase phase;
  final Animation<double> pulseAnim;
  final bool isSpeaking;
  const _AvatarWithGlow({
    required this.personaName, required this.phase,
    required this.pulseAnim, required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = isSpeaking ? AppTheme.moonRose
        : phase == CallPhase.listening ? AppTheme.auroraBlue
        : AppTheme.softLavender;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: (phase == CallPhase.dialing || isSpeaking) ? pulseAnim.value : 1.0,
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: glowColor.withOpacity(0.25),
                  blurRadius: 60, spreadRadius: 20),
              ],
            ),
          ),
          // Frosted ring
          Container(
            width: 190, height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: glowColor.withOpacity(0.3), width: 1.5),
              color: glowColor.withOpacity(0.05),
            ),
          ),
          // Avatar
          SizedBox(
            width: 160, height: 160,
            child: MiraAvatar(isSpeaking: isSpeaking, size: 160),
          ),
        ],
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  final String userText;
  final String aiText;
  final String name;
  const _TranscriptBubble({required this.userText, required this.aiText, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (userText.isNotEmpty)
                  Text('You: $userText',
                    style: const TextStyle(fontSize: 12, color: AppTheme.auroraBlue),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (userText.isNotEmpty && aiText.isNotEmpty)
                  const SizedBox(height: 6),
                if (aiText.isNotEmpty)
                  Text('$name: $aiText',
                    style: const TextStyle(fontSize: 12, color: AppTheme.moonRose),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final CallState callState;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onEnd;
  const _CallControls({
    required this.callState, required this.onMute,
    required this.onSpeaker, required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (callState.status == CallStatus.connected) ...[
          _ControlBtn(
            icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
            color: callState.isMuted ? AppTheme.errorRed : Colors.white.withOpacity(0.15),
            iconColor: Colors.white,
            onTap: onMute,
          ),
          const SizedBox(width: 24),
        ],
        // End call
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4060), Color(0xFFFF6B8A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF4060).withOpacity(0.5),
                blurRadius: 24, spreadRadius: 4),
            ],
          ),
          child: IconButton(
            onPressed: onEnd,
            icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
            padding: const EdgeInsets.all(20),
          ),
        ),
        if (callState.status == CallStatus.connected) ...[
          const SizedBox(width: 24),
          _ControlBtn(
            icon: callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: callState.isSpeakerOn
                ? AppTheme.softLavender.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            iconColor: callState.isSpeakerOn ? AppTheme.softLavender : Colors.white,
            onTap: onSpeaker,
          ),
        ],
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.color,
    required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56, height: 56,
            color: color,
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _CallOrbPainter extends CustomPainter {
  final double t;
  final bool isSpeaking;
  final bool isListening;
  const _CallOrbPainter(this.t, {required this.isSpeaking, required this.isListening});

  @override
  void paint(Canvas canvas, Size size) {
    final speakColor = isSpeaking ? const Color(0xFFFFB7C5) : const Color(0xFFC9A7FF);
    final listenColor = isListening ? const Color(0xFFA7C4FF) : const Color(0xFF8B6DFF);

    _glow(canvas, Offset(size.width * 0.2, size.height * (0.3 + t * 0.1)),
        size.width * 0.6, speakColor, 0.08 + (isSpeaking ? t * 0.04 : 0));
    _glow(canvas, Offset(size.width * 0.8, size.height * (0.6 - t * 0.1)),
        size.width * 0.5, listenColor, 0.07 + (isListening ? t * 0.04 : 0));
    _glow(canvas, Offset(size.width * 0.5, size.height * 0.85),
        size.width * 0.4, const Color(0xFFFFD4E8), 0.05 + t * 0.02);
  }

  void _glow(Canvas canvas, Offset c, double r, Color color, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_CallOrbPainter old) =>
      old.t != t || old.isSpeaking != isSpeaking || old.isListening != isListening;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  static final _particles = List.generate(20, (_) => [
    _rng.nextDouble(), _rng.nextDouble(),
    _rng.nextDouble() * 0.003 + 0.001,
    _rng.nextDouble() * 3 + 1,
    _rng.nextDouble() * 0.4 + 0.1,
  ]);

  const _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p[1] + t * p[2] * 10) % 1.0;
      final x = p[0] + sin(t * pi * 2 + p[0] * 6) * 0.02;
      final paint = Paint()
        ..color = const Color(0xFFC9A7FF).withOpacity(p[4] * (0.5 + sin(t * pi * 4) * 0.3))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x * size.width, y * size.height), p[3], paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
