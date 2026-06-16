import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/persona_provider.dart';
import '../../providers/settings_provider.dart';
import '../../app/theme.dart';
import '../../widgets/avatar_switcher_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final personaState = ref.watch(personaProvider);
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back)), title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Flirt Mode', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Enable romantic responses', style: TextStyle(color: AppTheme.textSecondary)),
              value: personaState.persona.flirtEnabled,
              onChanged: (_) => ref.read(personaProvider.notifier).toggleFlirtMode(),
              activeThumbColor: AppTheme.primaryPurple,
            ),
            SwitchListTile(
              title: const Text('Friendship Mode', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Keep conversations platonic', style: TextStyle(color: AppTheme.textSecondary)),
              value: personaState.persona.friendshipMode,
              onChanged: (_) => ref.read(personaProvider.notifier).toggleFriendshipMode(),
              activeThumbColor: AppTheme.primaryPurple,
            ),
            SwitchListTile(
              title: const Text('Notifications', style: TextStyle(color: AppTheme.textPrimary)),
              value: settings['notifications'] ?? true,
              onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting('notifications', v),
              activeThumbColor: AppTheme.primaryPurple,
            ),
            SwitchListTile(
              title: const Text('AI Voice Responses', style: TextStyle(color: AppTheme.textPrimary)),
              value: settings['aiVoice'] ?? true,
              onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting('aiVoice', v),
              activeThumbColor: AppTheme.primaryPurple,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AvatarSwitcherWidget(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { ref.read(authProvider.notifier).signOut(); context.go('/auth/login'); },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
