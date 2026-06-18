import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

/// Slide-out sidebar drawer for the Mira home screen.
///
/// Shows secondary navigation: Settings, Memory, Call History, Chat
/// History, Companion Management, and future features. Frosted glass
/// with blur, slides in from the left.
class MiraSidebar extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const MiraSidebar({super.key, required this.onClose});

  @override
  ConsumerState<MiraSidebar> createState() => _MiraSidebarState();
}

class _MiraSidebarState extends ConsumerState<MiraSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(String route) {
    widget.onClose();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.displayName ?? 'User';

    return Stack(
      children: [
        // Dimmed background — tap to close
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        // Sliding panel
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.midnightBlue.withOpacity(0.95),
                    AppTheme.deepViolet.withOpacity(0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(
                  right: BorderSide(color: AppTheme.glassBorder, width: 1),
                ),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Header — Mira avatar + name
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.auroraGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.magentaAccent
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mira',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300,
                                            color: AppTheme.moonWhite,
                                            letterSpacing: 2)),
                                    const SizedBox(height: 2),
                                    Text('AI Assistant',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary
                                                .withOpacity(0.8),
                                            letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onClose,
                                icon: const Icon(Icons.close,
                                    color: AppTheme.textSecondary, size: 20),
                              ),
                            ],
                          ),
                        ),

                        // User greeting
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Hello, $name',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary
                                        .withOpacity(0.7),
                                    letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Menu items
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              _SidebarItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Chat History',
                                onTap: () => _navigate('/chat'),
                              ),
                              _SidebarItem(
                                icon: Icons.phone_outlined,
                                label: 'Call',
                                onTap: () => _navigate('/call'),
                              ),
                              _SidebarItem(
                                icon: Icons.psychology_outlined,
                                label: 'Memory',
                                onTap: () => _navigate('/memory'),
                              ),
                              _SidebarItem(
                                icon: Icons.people_outline_rounded,
                                label: 'Companions',
                                onTap: () => _navigate('/companions'),
                              ),
                              _SidebarItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Companion Profile',
                                onTap: () => _navigate('/persona'),
                              ),
                              _SidebarItem(
                                icon: Icons.add_rounded,
                                label: 'Create Companion',
                                onTap: () => _navigate('/companion/new'),
                              ),
                              const Divider(
                                  color: AppTheme.glassBorder, height: 24),
                              _SidebarItem(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () => _navigate('/settings'),
                              ),
                              _SidebarItem(
                                icon: Icons.auto_awesome_outlined,
                                label: 'Mira Assistant',
                                onTap: () => _navigate('/mira'),
                              ),
                            ],
                          ),
                        ),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Mirabel v1.0.0',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary
                                      .withOpacity(0.4),
                                  letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 14),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.moonWhite,
                      fontSize: 14,
                      letterSpacing: 0.5)),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary.withOpacity(0.4), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
