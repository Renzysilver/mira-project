import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/animated_avatar.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../app/theme.dart';

class PersonaScreen extends ConsumerWidget {
  const PersonaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personaState = ref.watch(personaProvider);
    final stats = personaState.relationship;

    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back)), title: const Text('Companion Profile')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              AnimatedAvatar(mood: personaState.persona.currentMood, size: 150),
              const SizedBox(height: 16),
              Text(personaState.persona.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text(personaState.persona.personalityDisplayName, style: const TextStyle(color: AppTheme.primaryPink)),
              const SizedBox(height: 24),
              Text('Affection: \${stats.affectionLabel} (\${stats.affectionLevel}%)', style: const TextStyle(color: AppTheme.accentCyan, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: stats.affectionLevel / 100, backgroundColor: AppTheme.surfaceDark, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple)),
              const SizedBox(height: 24),
              GlassmorphismCard(
                child: Column(
                  children: [
                    _buildStatRow('Messages Sent', '\${stats.messagesSent}'),
                    _buildStatRow('Calls Made', '\${stats.callsMade}'),
                    _buildStatRow('Streak Days', '\${stats.streakDays}'),
                    _buildStatRow('Days Together', '\${stats.daysTogether}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppTheme.textSecondary)), Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600))]),
    );
  }
}
