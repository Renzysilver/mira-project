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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Looping pulse for dialing screen
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callProvider.notifier).startCall();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final personaState = ref.watch(personaProvider);

    ref.listen<CallState>(callProvider, (_, next) {
      ref.read(isMiraSpeakingProvider.notifier).state =
          next.phase == CallPhase.speaking;
    });

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      ref.read(callProvider.notifier).endCall();
                      context.go('/home');
                    },
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  ),
                ),
                const Spacer(flex: 1),
                const SizedBox(
                  width: 300,
                  height: 300,
                  child: MiraAvatarWidget(),
                ),
                const SizedBox(height: 24),
                Text(
                  personaState.persona.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusText(callState),
                const SizedBox(height: 32),
                _buildPhaseUI(callState),
                const SizedBox(height: 16),
                if (callState.lastUserSpeech.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4),
                    child: Text(
                      'You: ${callState.lastUserSpeech}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (callState.lastAiSpeech.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4),
                    child: Text(
                      '${personaState.persona.name}: ${callState.lastAiSpeech}',
                      style: const TextStyle(
                        color: AppTheme.primaryPink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (callState.status == CallStatus.connected)
                      _buildControlButton(
                        callState.isMuted ? Icons.mic_off : Icons.mic,
                        callState.isMuted ? Colors.red : AppTheme.surfaceLight,
                        () => ref.read(callProvider.notifier).toggleMute(),
                      ),
                    _buildControlButton(
                      Icons.call_end,
                      Colors.red,
                      () {
                        ref.read(callProvider.notifier).endCall();
                        context.go('/home');
                      },
                    ),
                    if (callState.status == CallStatus.connected)
                      _buildControlButton(
                        callState.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        callState.isSpeakerOn
                            ? AppTheme.primaryPurple
                            : AppTheme.surfaceLight,
                        () => ref.read(callProvider.notifier).toggleSpeaker(),
                      ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(CallState callState) {
    switch (callState.status) {
      case CallStatus.ringing:
        return const Text('Ringing...',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary));
      case CallStatus.connected:
        return Text(callState.formattedDuration,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary));
      case CallStatus.ended:
        return const Text('Call Ended',
            style: TextStyle(fontSize: 16, color: AppTheme.errorRed));
    }
  }

  Widget _buildPhaseUI(CallState callState) {
    switch (callState.phase) {
      case CallPhase.dialing:
        return Column(
          children: [
            const Text('Ringing...',
                style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCyan.withValues(alpha : 0.25),
                  border: Border.all(color: AppTheme.accentCyan, width: 2),
                ),
                child: const Icon(Icons.phone, color: AppTheme.accentCyan, size: 30),
              ),
            ),
          ],
        );
      case CallPhase.listening:
        return const Column(
          children: [
            Text('Listening...',
                style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            WaveformWidget(isActive: true),
          ],
        );
      case CallPhase.thinking:
        return const Column(
          children: [
            Text('Thinking...',
                style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            CircularProgressIndicator(color: AppTheme.accentGold),
          ],
        );
      case CallPhase.speaking:
        return const Column(
          children: [
            Text('Speaking...',
                style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            WaveformWidget(isActive: true),
          ],
        );
    }
  }

  Widget _buildControlButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: color,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
