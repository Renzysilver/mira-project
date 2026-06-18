import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Index of the currently selected tab in the main shell.
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-navigation shell that wraps the main screens (Chat, Call, Mira,
/// Bottom-navigation shell with 3 tabs: Chat, Mira (center), Companions.
/// Pass currentIndex = -1 for non-tab screens (persona, memory, settings)
/// so no tab is highlighted.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex; // -1 = no tab highlighted

  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _routes = [
    '/chat',
    '/companions',
    '/home',      // "Mira" — center, elevated
  ];

  void _onTap(int i) {
    if (i == widget.currentIndex) return;
    context.go(_routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(60, 0, 60, 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              isSelected: widget.currentIndex == 0,
              onTap: () => _onTap(0),
            ),
            _NavIcon(
              icon: Icons.auto_awesome_rounded,
              label: 'Mira',
              isSelected: widget.currentIndex == 2,
              isCenter: true,
              onTap: () => _onTap(2),
            ),
            _NavIcon(
              icon: Icons.people_outline_rounded,
              label: 'Companions',
              isSelected: widget.currentIndex == 1,
              onTap: () => _onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.magentaAccent : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCenter ? 44 : 36,
            height: isCenter ? 44 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppTheme.magentaAccent.withOpacity(0.15)
                  : Colors.transparent,
              border: isCenter
                  ? Border.all(color: AppTheme.magentaAccent, width: 1.5)
                  : null,
            ),
            child: Icon(icon, color: color, size: isCenter ? 22 : 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              letterSpacing: 0.8,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
