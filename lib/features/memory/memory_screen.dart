import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../services/memory_service.dart';
import '../../widgets/dreamy_background.dart';
import '../../widgets/shell/main_shell.dart';

/// Memory screen — shows the facts Mira has learned about the user.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryFacts = ref.watch(memoryFactsProvider);

    return MainShell(
      currentIndex: 3,
      child: DreamyBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('memory',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary,
                        letterSpacing: 2)),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.auroraGradient.createShader(b),
                      child: const Text('What Mira remembers',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300,
                          color: Colors.white, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: memoryFacts.when(
                  data: (facts) {
                    if (facts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_outlined,
                                size: 48,
                                color: AppTheme.textSecondary.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              const Text('Mira hasn\'t learned anything yet',
                                style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14),
                                textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              const Text(
                                'Tell her about yourself in chat — she\'ll remember.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: facts.length,
                      itemBuilder: (_, i) {
                        final fact = facts[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.glassWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.magentaAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fact,
                                  style: const TextStyle(
                                    color: AppTheme.moonWhite,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.magentaAccent)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
