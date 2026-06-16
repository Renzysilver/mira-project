import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/persona_provider.dart';
import '../../providers/settings_provider.dart';
import '../../app/theme.dart';
import '../../widgets/dreamy_background.dart';
import '../../widgets/shell/main_shell.dart';
import '../../widgets/avatar_switcher_widget.dart';

/// Resolves a thumb color that's [activeColor] when the switch is selected.
WidgetStateProperty<Color?> _activeThumb(Color activeColor) =>
    WidgetStateProperty.resolveWith<Color?>((states) =>
        states.contains(WidgetState.selected) ? activeColor : null);

WidgetStateProperty<Color?> _activeTrack(Color activeColor) =>
    WidgetStateProperty.resolveWith<Color?>((states) => states
        .contains(WidgetState.selected)
        ? activeColor.withOpacity(0.4)
        : Colors.white.withOpacity(0.08));

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final personaState = ref.watch(personaProvider);

    return MainShell(
      // Settings isn't in the bottom nav — default to -1 so nothing is active.
      // But MainShell requires 0-4, so we use 4 (Profile) as the closest match.
      currentIndex: 4,
      child: DreamyBackground(
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
                      Text('settings',
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
                _SectionLabel(label: 'Persona'),
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
                _SectionLabel(label: 'Avatar'),
                const SizedBox(height: 10),
                _GlassCard(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: AvatarSwitcherWidget(),
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications / Voice
                _SectionLabel(label: 'App'),
                const SizedBox(height: 10),
                _GlassCard(
                  child: Column(
                    children: [
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
                const SizedBox(height: 32),

                // Sign out
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppTheme.errorRed.withOpacity(0.12),
                    border: Border.all(
                        color: AppTheme.errorRed.withOpacity(0.4)),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                          color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 10),
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
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      letterSpacing: 1.5))),
              ],
            ),
          ),
        ),
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
          color: AppTheme.textSecondary.withOpacity(0.7),
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
