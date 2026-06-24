import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/persona_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wakeword_provider.dart';
import '../../app/theme.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import '../../widgets/shell/main_shell.dart';
import '../../widgets/avatar_switcher_widget.dart';

/// Resolves a thumb color that's [activeColor] when the switch is selected.
WidgetStateProperty<Color?> _activeThumb(Color activeColor) =>
    WidgetStateProperty.resolveWith<Color?>((states) =>
    states.contains(WidgetState.selected) ? activeColor : null);

WidgetStateProperty<Color?> _activeTrack(Color activeColor) =>
    WidgetStateProperty.resolveWith<Color?>((states) => states
        .contains(WidgetState.selected)
        ? activeColor.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.08));

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final personaState = ref.watch(personaProvider);
    final wakeWordEnabled = ref.watch(wakeWordProvider);

    return MainShell(
      // Settings isn't in the bottom nav — default to -1 so nothing is active.
      // But MainShell requires 0-4, so we use 4 (Profile) as the closest match.
      currentIndex: -1,
      child: AtmosphericBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('settings',
                          style: TextStyle(fontSize: 12,
                              color: AppTheme.textSecondary, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.auroraGradient.createShader(b),
                        child: const Text('Tune your bond',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Persona section
                const _SectionLabel(label: 'Persona'),
                const SizedBox(height: 10),
                _GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Flirt Mode',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Enable romantic responses',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: personaState.persona.flirtEnabled,
                        onChanged: (_) => ref
                            .read(personaProvider.notifier)
                            .toggleFlirtMode(),
                        thumbColor: _activeThumb(AppTheme.magentaAccent),
                        trackColor: _activeTrack(AppTheme.magentaAccent),
                      ),
                      SwitchListTile(
                        title: const Text('Friendship Mode',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Keep conversations platonic',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: personaState.persona.friendshipMode,
                        onChanged: (_) => ref
                            .read(personaProvider.notifier)
                            .toggleFriendshipMode(),
                        thumbColor: _activeThumb(AppTheme.magentaAccent),
                        trackColor: _activeTrack(AppTheme.magentaAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar section
                const _SectionLabel(label: 'Avatar'),
                const SizedBox(height: 10),
                const _GlassCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: AvatarSwitcherWidget(),
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications / Voice
                const _SectionLabel(label: 'App'),
                const SizedBox(height: 10),
                _GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Hey Mira',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Say "Hey Mira" to start a call — works even when the app is closed',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: wakeWordEnabled,
                        onChanged: (_) => ref
                            .read(wakeWordProvider.notifier)
                            .toggle(),
                        thumbColor: _activeThumb(AppTheme.softLavender),
                        trackColor: _activeTrack(AppTheme.softLavender),
                      ),
                      SwitchListTile(
                        title: const Text('Notifications',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Check-in messages from Mira',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: settings['notifications'] ?? true,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('notifications', v),
                        thumbColor: _activeThumb(AppTheme.magentaAccent),
                        trackColor: _activeTrack(AppTheme.magentaAccent),
                      ),
                      SwitchListTile(
                        title: const Text('AI Voice Responses',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Hear Mira speak during chat',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: settings['aiVoice'] ?? true,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('aiVoice', v),
                        thumbColor: _activeThumb(AppTheme.magentaAccent),
                        trackColor: _activeTrack(AppTheme.magentaAccent),
                      ),
                      SwitchListTile(
                        title: const Text('Sound Effects',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text('Chimes and ringtones',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        value: settings['soundEffects'] ?? true,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .updateSetting('soundEffects', v),
                        thumbColor: _activeThumb(AppTheme.magentaAccent),
                        trackColor: _activeTrack(AppTheme.magentaAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data management section
                const _SectionLabel(label: 'Data'),
                const SizedBox(height: 10),
                _GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined,
                            color: AppTheme.textSecondary, size: 20),
                        title: const Text('Clear active companion chat',
                            style: TextStyle(
                                color: AppTheme.moonWhite, fontSize: 14)),
                        subtitle: const Text(
                            'Deletes all messages with the current companion',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary, size: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () => _confirmClearActiveChat(context, ref),
                      ),
                      const Divider(height: 1, color: AppTheme.glassBorder),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep_outlined,
                            color: AppTheme.errorRed, size: 20),
                        title: const Text('Clear ALL chats',
                            style: TextStyle(
                                color: AppTheme.errorRed, fontSize: 14)),
                        subtitle: const Text(
                            'Permanently deletes messages with every companion',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.errorRed, size: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () => _confirmClearAllChats(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign out
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppTheme.errorRed.withValues(alpha: 0.12),
                    border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.4)),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                      context.go('/auth/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppTheme.errorRed, size: 18),
                        SizedBox(width: 10),
                        Text('Sign Out',
                            style: TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App version footer
                Center(
                    child: Text('Mirabel v1.0.0  •  Crafted with Love',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5),
                            letterSpacing: 1.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Chat clear confirmations ────────────────────────────────────

  void _confirmClearActiveChat(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Clear chat with this companion?',
            style: TextStyle(color: AppTheme.moonWhite, fontSize: 16)),
        content: const Text(
            'All messages with the current companion will be permanently '
                'deleted from the database. This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearActiveChat(context, ref);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllChats(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Clear ALL companion chats?',
            style: TextStyle(color: AppTheme.moonWhite, fontSize: 16)),
        content: const Text(
            'Every message with every companion will be permanently deleted '
                'from the database. This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearAllChats(context, ref);
            },
            child: const Text('Clear all',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearActiveChat(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(firestoreStorageProvider);
    final companionId = ref.read(personaProvider).companionId;
    if (storage == null || companionId == null) {
      _showToast(context, 'No active companion', isError: true);
      return;
    }
    try {
      await storage.clearAllCompanionMessages(companionId);
      if (!context.mounted) return;
      _showToast(context, 'Chat cleared');
    } catch (e) {
      _showToast(context, 'Failed: $e', isError: true);
    }
  }

  Future<void> _clearAllChats(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(firestoreStorageProvider);
    if (storage == null) {
      _showToast(context, 'Not signed in', isError: true);
      return;
    }
    try {
      await storage.clearAllChatsForAllCompanions();
      if (!context.mounted) return;
      _showToast(context, 'All chats cleared');
    } catch (e) {
      _showToast(context, 'Failed: $e', isError: true);
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
                color: isError ? AppTheme.errorRed : AppTheme.moonWhite,
                fontSize: 12)),
        backgroundColor:
        isError ? Colors.red.withValues(alpha: 0.9) : AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: child,
    );
  }
}