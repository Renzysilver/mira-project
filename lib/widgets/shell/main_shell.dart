import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Index of the currently selected tab in the main shell.
final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-navigation shell that wraps the main screens (Chat, Call, Mira,
/// Memory, Profile). Mirrors the mockup's bottom nav bar with glass cards.
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;

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
    '/mira',      // "Mira" — the standalone AI assistant
    '/memory',
    '/persona',   // Profile
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
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
              icon: Icons.people_outline_rounded,
              label: 'Companions',
              isSelected: widget.currentIndex == 1,
              onTap: () => _onTap(1),
            ),
            _NavIcon(
              icon: Icons.home_filled,
              label: 'Mira',
              isSelected: widget.currentIndex == 2,
              isCenter: true,
              onTap: () => _onTap(2),
            ),
            _NavIcon(
              icon: Icons.psychology_outlined,
              label: 'Memory',
              isSelected: widget.currentIndex == 3,
              onTap: () => _onTap(3),
            ),
            _NavIcon(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              isSelected: widget.currentIndex == 4,
              onTap: () => _onTap(4),
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
