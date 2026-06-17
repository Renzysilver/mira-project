import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/companions_provider.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import '../../widgets/shell/main_shell.dart';

class CompanionsScreen extends ConsumerWidget {
  const CompanionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(companionsProvider);
    final active = ref.watch(activeCompanionProvider);
    final switcher = ref.read(companionSwitcherProvider.notifier);

    return MainShell(
      // Companions tab is now index 1 (was 2 before bottom nav reorder)
      currentIndex: 1,
      child: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('companions',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 2)),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppTheme.auroraGradient.createShader(b),
                            child: const Text('Your circle',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/companion/new'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppTheme.pinkGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.magentaAccent
                                  .withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('New Companion',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Companion grid
              Expanded(
                child: companionsAsync.when(
                  data: (companions) {
                    if (companions.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: companions.length,
                      itemBuilder: (_, i) {
                        final c = companions[i];
                        final isActive = c.id == active?.id;
                        return _CompanionCard(
                          name: c.name,
                          subtitle:
                              '${c.personalityType} • ${c.ageRange.isEmpty ? "—" : c.ageRange}',
                          hairColor: c.hairColor,
                          eyeColor: c.eyeColor,
                          interestCount: c.interests.length,
                          isActive: isActive,
                          onTap: () async {
                            if (!isActive) {
                              await switcher.setActive(c.id);
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.magentaAccent),
                  ),
                  error: (e, _) => Center(
                    child: Text('Failed to load: $e',
                        style: const TextStyle(color: AppTheme.errorRed)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.magentaAccent.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_outline,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('No companions yet',
                style: TextStyle(
                    color: AppTheme.moonWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text(
                'Create your first AI companion to begin a new connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/companion/new'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Create Companion',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String hairColor;
  final String eyeColor;
  final int interestCount;
  final bool isActive;
  final VoidCallback onTap;

  const _CompanionCard({
    required this.name,
    required this.subtitle,
    required this.hairColor,
    required this.eyeColor,
    required this.interestCount,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.magentaAccent.withOpacity(0.1)
              : AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? AppTheme.magentaAccent
                : AppTheme.glassBorder,
            width: isActive ? 1.6 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.magentaAccent.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Avatar with hair color ring
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
                border: Border.all(
                    color: _parseColor(hairColor).withOpacity(0.5),
                    width: 1.5),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.midnightBlue,
                ),
                child: Icon(Icons.face,
                    color: _parseColor(eyeColor), size: 32),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(name,
                style: const TextStyle(
                    color: AppTheme.moonWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            // Subtitle
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // Active badge or interest count
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.magentaAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.magentaAccent.withOpacity(0.5)),
                ),
                child: const Text('ACTIVE',
                    style: TextStyle(
                        color: AppTheme.moonRose,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
              )
            else
              Text('$interestCount interests',
                  style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String name) {
    const map = {
      'Black': Color(0xFF1A1A1A),
      'Brown': Color(0xFF6B4423),
      'Blonde': Color(0xFFFFD700),
      'Red': Color(0xFFC0392B),
      'Pink': Color(0xFFFFB7C5),
      'Blue': Color(0xFF3498DB),
      'Purple': Color(0xFF9B59B6),
      'White': Color(0xFFFAFAFA),
      'Silver': Color(0xFFC0C0C0),
      'Green': Color(0xFF27AE60),
      'Hazel': Color(0xFF8E5A2B),
      'Gray': Color(0xFF7F8C8D),
      'Amber': Color(0xFFFFBF00),
      'Violet': Color(0xFF8E44AD),
    };
    return map[name] ?? const Color(0xFFFFB7C5);
  }
}
