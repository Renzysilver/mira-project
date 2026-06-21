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
      currentIndex: 1,
      child: AtmosphericBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Companions',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.textPrimary,
                              letterSpacing: 1.5)),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/companion/new'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.auroraGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('New',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: companionsAsync.when(
                  data: (companions) {
                    if (companions.isEmpty) {
                      return _emptyState(context);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: companions.length + 1,
                      itemBuilder: (_, i) {
                        if (i == companions.length) {
                          return GestureDetector(
                            onTap: () => context.go('/companion/new'),
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.glassWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: AppTheme.purpleLight, size: 16),
                                  SizedBox(width: 6),
                                  Text('New Companion',
                                      style: TextStyle(
                                          color: AppTheme.purpleLight,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          );
                        }
                        final c = companions[i];
                        final isActive = c.id == active?.id;
                        return _CompanionListCard(
                          name: c.name,
                          personalityType: c.personalityType,
                          ageRange: c.ageRange,
                          hairColor: c.hairColor,
                          eyeColor: c.eyeColor,
                          interestCount: c.interests.length,
                          isActive: isActive,
                          onTap: () {
                            if (!isActive) switcher.setActive(c.id);
                            context.go('/persona');
                          },
                          onLongPress: () =>
                              _showMenu(context, ref, c, isActive, storage),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.purple)),
                  error: (e, _) => Center(
                      child: Text('Failed to load: $e',
                          style: const TextStyle(color: AppTheme.errorRed))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.auroraGradient,
              ),
              child: const Icon(Icons.favorite_outline,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('No companions yet',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            const Text('Create your first AI companion.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.go('/companion/new'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.auroraGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Create Companion',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref,
      CompanionSummary c, bool isActive, FirestoreStorage? storage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              if (!isActive)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
                  title: const Text('Set as active', style: TextStyle(color: AppTheme.textPrimary)),
                  onTap: () {Navigator.pop(ctx);ref.read(companionSwitcherProvider.notifier).setActive(c.id);},
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.purpleLight),
                title: const Text('Edit', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {Navigator.pop(ctx);context.go('/companion/edit/${c.id}');},
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                title: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                onTap: () {Navigator.pop(ctx);_confirmDelete(context, ref, c, storage);},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref,
      CompanionSummary c, FirestoreStorage? storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Delete ${c.name}?', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: Text('All data for ${c.name} will be permanently deleted.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (storage != null) {
                try {
                  await storage.deleteCompanion(c.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} deleted', style: const TextStyle(color: AppTheme.textPrimary)), backgroundColor: AppTheme.surfaceDark, behavior: SnackBarBehavior.floating));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e', style: const TextStyle(color: AppTheme.errorRed))));
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _CompanionListCard extends StatelessWidget {
  final String name;
  final String personalityType;
  final String ageRange;
  final String hairColor;
  final String eyeColor;
  final int interestCount;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CompanionListCard({
    required this.name,
    required this.personalityType,
    required this.ageRange,
    required this.hairColor,
    required this.eyeColor,
    required this.interestCount,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  Color _parseColor(String n) {
    const m = {'Black': Color(0xFF1A1A1A),'Brown': Color(0xFF6B4423),'Blonde': Color(0xFFFFD700),'Red': Color(0xFFC0392B),'Pink': Color(0xFFEC4899),'Blue': Color(0xFF3498DB),'Purple': Color(0xFF8B5CF6),'White': Color(0xFFFAFAFA),'Silver': Color(0xFFC0C0C0),'Green': Color(0xFF27AE60),'Hazel': Color(0xFF8E5A2B),'Gray': Color(0xFF7F8C8D)};
    return m[n] ?? const Color(0xFFEC4899);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.pink.withOpacity(0.5) : AppTheme.glassBorder,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppTheme.pink.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? AppTheme.pinkGradient : AppTheme.auroraGradient,
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.background),
                child: Icon(Icons.face, color: _parseColor(eyeColor), size: 24),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(personalityType, style: const TextStyle(color: AppTheme.purpleLight, fontSize: 9, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 6),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.pink.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: const Text('ACTIVE', style: TextStyle(color: AppTheme.pink, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        )
                      else
                        Text('$interestCount interests', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
