import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

final mainShellTabIndexProvider = StateProvider<int>((ref) => 0);

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
    '/home',
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
      bottomNavigationBar: _FloatingNav(
        currentIndex: widget.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _FloatingNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Frosted glass bar
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
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
                      _SideNavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        isSelected: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                      // Center spacer for the elevated Mira button
                      const SizedBox(width: 72),
                      _SideNavItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Companions',
                        isSelected: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Elevated center Mira button — floats above the bar
          Positioned(
            bottom: 18,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: _MiraCenterButton(isSelected: currentIndex == 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiraCenterButton extends StatelessWidget {
  final bool isSelected;
  const _MiraCenterButton({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Outer glow ring
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.pink.withOpacity(isSelected ? 0.7 : 0.35),
                blurRadius: isSelected ? 28 : 16,
                spreadRadius: isSelected ? 4 : 2,
              ),
              BoxShadow(
                color: AppTheme.purple.withOpacity(isSelected ? 0.5 : 0.2),
                blurRadius: isSelected ? 40 : 20,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSelected
                    ? [AppTheme.pink, AppTheme.purple]
                    : [
                        AppTheme.pink.withOpacity(0.7),
                        AppTheme.purple.withOpacity(0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mira',
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? AppTheme.pink : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.pink : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                letterSpacing: 0.5,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
