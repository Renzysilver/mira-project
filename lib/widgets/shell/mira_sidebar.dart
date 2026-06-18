import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class MiraSidebar extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const MiraSidebar({super.key, required this.onClose});

  @override
  ConsumerState<MiraSidebar> createState() => _MiraSidebarState();
}

class _MiraSidebarState extends ConsumerState<MiraSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _slide = Tween<Offset>(
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
    // Use the root navigator's context so go works even after
    // the sidebar is dismissed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).go(route);
    });
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback: try platform default
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.displayName ?? 'User';

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
        SlideTransition(
          position: _slide,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.76,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(right: BorderSide(color: AppTheme.glassBorder)),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.auroraGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.purple.withOpacity(0.3),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Mira',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w300,
                                                color: AppTheme.textPrimary,
                                                letterSpacing: 1.5)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.purple.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Pro',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.purpleLight,
                                                  letterSpacing: 0.5)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('AI Assistant',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary
                                                .withOpacity(0.7))),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Hello, $name',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary.withOpacity(0.6))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Menu
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              _Item(icon: Icons.chat_bubble_outline, label: 'New Chat', onTap: () => _navigate('/chat')),
                              _Item(icon: Icons.phone_outlined, label: 'Voice Call', onTap: () => _navigate('/call')),
                              _Item(icon: Icons.auto_awesome_outlined, label: 'Ask Mira', onTap: () => _navigate('/mira')),
                              _Item(icon: Icons.people_outline, label: 'Companions', onTap: () => _navigate('/companions')),
                              _Item(icon: Icons.person_outline, label: 'Companion Profile', onTap: () => _navigate('/persona')),
                              _Item(icon: Icons.psychology_outlined, label: 'Memory', onTap: () => _navigate('/memory')),
                              const _Divider(),
                              // Assistant actions — use url_launcher
                              _Item(icon: Icons.phone_in_talk_outlined, label: 'Make a Phone Call', onTap: () => _launchUrl('tel:')),
                              _Item(icon: Icons.sms_outlined, label: 'Send a Message', onTap: () => _launchUrl('sms:')),
                              _Item(icon: Icons.alarm_outlined, label: 'Set Alarm', onTap: () => _launchUrl('intent://alarm#Intent;action=android.intent.action.SET_ALARM;type=android.intent.category.ALARM;end')),
                              _Item(icon: Icons.calendar_today_outlined, label: 'Open Calendar', onTap: () => _launchUrl('content://com.android.calendar/time')),
                              _Item(icon: Icons.camera_alt_outlined, label: 'Open Camera', onTap: () => _launchUrl('intent://camera#Intent;action=android.media.action.IMAGE_CAPTURE;end')),
                              const _Divider(),
                              _Item(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _navigate('/settings')),
                              _Item(icon: Icons.mood_outlined, label: 'Mood & Personality', onTap: () => _navigate('/persona')),
                            ],
                          ),
                        ),

                        // Logout
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(authProvider.notifier).signOut();
                              widget.onClose();
                              context.go('/auth/login');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.errorRed.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: AppTheme.errorRed, size: 16),
                                  SizedBox(width: 8),
                                  Text('Log out',
                                      style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
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

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.purple, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        letterSpacing: 0.3)),
              ),
              Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary.withOpacity(0.3), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(height: 1, color: AppTheme.glassBorder),
    );
  }
}
