import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/companions_provider.dart';

/// Compact companion switcher for the chat header.
///
/// Shows the current companion's name + a dropdown arrow. Tapping opens
/// a bottom sheet listing all companions; tapping one switches the
/// active companion (which automatically reloads chat / persona / etc.
/// via the activeCompanionProvider dependency chain).
class CompanionSwitcher extends ConsumerWidget {
  const CompanionSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCompanionProvider);
    final companionsAsync = ref.watch(companionsProvider);

    return GestureDetector(
      onTap: () => _showSwitcherSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini avatar
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            // Name
            Text(
              active?.name ?? 'Mira',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.moonWhite,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            // Dropdown chevron
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSwitcherSheet(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.read(companionsProvider);
    final active = ref.read(activeCompanionProvider);
    final switcher = ref.read(companionSwitcherProvider.notifier);

    companionsAsync.when(
      data: (companions) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (sheetContext) => Container(
            decoration: const BoxDecoration(
              color: AppTheme.midnightBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                  top: BorderSide(color: AppTheme.glassBorder, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
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
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Companions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite,
                              letterSpacing: 1.5)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/companion/new');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.pinkGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('New',
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
                  const SizedBox(height: 16),
                  // Companion list
                  if (companions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border,
                              size: 40,
                              color: AppTheme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text(
                              'No companions yet. Create your first one!',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: companions.length,
                        itemBuilder: (_, i) {
                          final c = companions[i];
                          final isSelected = c.id == active?.id;
                          return _CompanionRow(
                            name: c.name,
                            subtitle:
                                '${c.personalityType} • ${c.ageRange.isEmpty ? "—" : c.ageRange}',
                            hairColor: c.hairColor,
                            isSelected: isSelected,
                            onTap: () async {
                              Navigator.pop(context);
                              if (!isSelected) {
                                await switcher.setActive(c.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => _showLoading(context),
      error: (e, _) => _showError(context, e.toString()),
    );
  }

  void _showLoading(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppTheme.midnightBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.magentaAccent),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load companions: $error')));
  }
}

class _CompanionRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final String hairColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompanionRow({
    required this.name,
    required this.subtitle,
    required this.hairColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.magentaAccent.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.magentaAccent
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with hair color accent
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
                border: Border.all(
                    color: _parseColor(hairColor).withOpacity(0.6),
                    width: 2),
              ),
              child: const Icon(Icons.face,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppTheme.moonWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.magentaAccent, size: 18),
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
    };
    return map[name] ?? const Color(0xFFFFB7C5);
  }
}
