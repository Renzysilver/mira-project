import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
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
    final storage = ref.watch(firestoreStorageProvider);

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
                        childAspectRatio: 0.95,
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
                          onTap: () {
                            // Tap opens the companion's profile (persona screen).
                            // Also set as active so the profile shows the right data.
                            if (!isActive) {
                              switcher.setActive(c.id);
                            }
                            context.go('/persona');
                          },
                          onLongPress: () => _showCompanionMenu(
                              context, ref, c, isActive, storage),
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

  /// Long-press menu: Edit / Delete / Set Active (if not active).
  void _showCompanionMenu(
    BuildContext context,
    WidgetRef ref,
    CompanionSummary companion,
    bool isActive,
    FirestoreStorage? storage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.midnightBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(companion.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.moonWhite,
                      letterSpacing: 1.5)),
              const SizedBox(height: 20),
              if (!isActive)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppTheme.successGreen),
                  title: const Text('Set as active',
                      style: TextStyle(color: AppTheme.moonWhite)),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref
                        .read(companionSwitcherProvider.notifier)
                        .setActive(companion.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppTheme.auroraBlue),
                title: const Text('Edit companion',
                    style: TextStyle(color: AppTheme.moonWhite)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/companion/edit/${companion.id}');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                title: const Text('Delete companion',
                    style: TextStyle(color: AppTheme.errorRed)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, companion, storage);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CompanionSummary companion,
    FirestoreStorage? storage,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Delete ${companion.name}?',
            style: const TextStyle(color: AppTheme.moonWhite, fontSize: 16)),
        content: Text(
            'All chat history, memories, and call logs for ${companion.name} will be permanently deleted. This cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (storage != null) {
                try {
                  await storage.deleteCompanion(companion.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${companion.name} deleted',
                            style: const TextStyle(color: AppTheme.moonWhite)),
                        backgroundColor: AppTheme.surfaceDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed: $e',
                              style: const TextStyle(color: AppTheme.errorRed))),
                    );
                  }
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
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
  final VoidCallback? onLongPress;

  const _CompanionCard({
    required this.name,
    required this.subtitle,
    required this.hairColor,
    required this.eyeColor,
    required this.interestCount,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.magentaAccent.withOpacity(0.1)
              : AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(22),
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
        // IntrinsicHeight ensures the Column fills the card height
        // without overflowing — text widgets use Flexible so they
        // shrink instead of pushing past the boundary.
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with hair color ring (compact)
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2),
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
                      color: _parseColor(eyeColor), size: 24),
                ),
              ),
              const SizedBox(height: 6),
              // Name — Flexible so it shrinks if needed
              Flexible(
                child: Text(name,
                    style: const TextStyle(
                        color: AppTheme.moonWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Flexible(
                child: Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              // Active badge or interest count
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.magentaAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.magentaAccent.withOpacity(0.5)),
                  ),
                  child: const Text('ACTIVE',
                      style: TextStyle(
                          color: AppTheme.moonRose,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                )
              else
                Text('$interestCount interests',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontSize: 9)),
            ],
          ),
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
