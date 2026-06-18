import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/storage/firebase_storage.dart';
import '../../models/persona_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/companions_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import '../../widgets/mira_avatar.dart';
import '../../widgets/shell/main_shell.dart';
import '../../widgets/shell/mira_sidebar.dart';

final _callHistoryProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final companionId = ref.watch(personaProvider.select((s) => s.companionId));
  if (storage == null || companionId == null) return Stream.value([]);
  return storage.watchCompanionCallLogs(companionId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaProvider).persona;
    final relationship = ref.watch(personaProvider).relationship;
    final user = ref.watch(authProvider).user;
    final name = user?.displayName?.split(' ').first ?? 'you';
    final callHistoryAsync = ref.watch(_callHistoryProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return PopScope(
      canPop: !_sidebarOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _sidebarOpen) setState(() => _sidebarOpen = false);
      },
      child: MainShell(
        currentIndex: 2,
        child: Stack(
          children: [
            AtmosphericBackground(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            _iconBtn(Icons.menu_rounded, () => setState(() => _sidebarOpen = true)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Center(
                                child: ShaderMask(
                                  shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                                  child: const Text('Mira  \u2726',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white,
                                          letterSpacing: 3)),
                                ),
                              ),
                            ),
                            _iconBtn(Icons.tune_rounded, () => context.go('/settings')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hero — Mira avatar + greeting
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Large avatar with glow
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.auroraGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.purple.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 44),
                            ),
                            const SizedBox(height: 16),
                            Text('$greeting, $name',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary.withOpacity(0.8))),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                              child: const Text('I\'m Mira  \u2726',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                      letterSpacing: 2)),
                            ),
                            const SizedBox(height: 4),
                            Text('Your AI Assistant \u2014 Here to help, anytime.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Message input bar (taps to open chat)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => context.go('/chat'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.glassWhite,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('Message Mira...',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary.withOpacity(0.5),
                                          fontSize: 13)),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/call'),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.auroraGradient,
                                    ),
                                    child: const Icon(Icons.mic_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick suggestions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _suggestion('Ask anything'),
                            const SizedBox(width: 8),
                            _suggestion('Generate image'),
                            const SizedBox(width: 8),
                            _suggestion('Help me write'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick actions grid 2x2
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: _actionCard(Icons.chat_bubble_outline_rounded, 'Smart Chat', 'Chat with Mira', () => context.go('/chat'))),
                            const SizedBox(width: 12),
                            Expanded(child: _actionCard(Icons.phone_outlined, 'Voice Call', 'Talk with Mira', () => context.go('/call'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: _actionCard(Icons.auto_awesome_outlined, 'AI Tools', 'Explore abilities', () => context.go('/mira'))),
                            const SizedBox(width: 12),
                            Expanded(child: _actionCard(Icons.person_outline_rounded, 'Persona', 'Her character', () => context.go('/persona'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Relationship stats
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('RELATIONSHIP',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardGlass,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            children: [
                              _stat('Days', '${relationship.daysTogether}', Icons.calendar_today_outlined),
                              _stat('Messages', '${relationship.messagesSent}', Icons.chat_outlined),
                              _stat('Calls', '${relationship.callsMade}', Icons.call_outlined),
                              _stat('Streak', '${relationship.streakDays}d', Icons.local_fire_department_outlined),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Call history
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CALL HISTORY',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w500)),
                            TextButton(
                              onPressed: () {},
                              child: const Text('See all',
                                  style: TextStyle(color: AppTheme.purple, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: callHistoryAsync.when(
                          data: (calls) {
                            if (calls.isEmpty) {
                              return _emptyState('No calls yet. Tap Call to hear ${persona.name}.');
                            }
                            return Column(
                              children: calls.take(3).map((call) {
                                final duration = call['duration'] as int? ?? 0;
                                final summary = (call['summary'] as String?) ?? '';
                                return _callItem(duration, summary);
                              }).toList(),
                            );
                          },
                          loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(color: AppTheme.purple, strokeWidth: 2))),
                          error: (_, __) => _emptyState('Failed to load.'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_sidebarOpen) MiraSidebar(onClose: () => setState(() => _sidebarOpen = false)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
    );
  }

  Widget _suggestion(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go('/mira'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.purple.withOpacity(0.15),
              ),
              child: Icon(icon, color: AppTheme.purpleLight, size: 16),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.purpleLight, size: 16),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _callItem(int duration, String summary) {
    final mins = duration ~/ 60;
    final secs = duration % 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.call, color: AppTheme.purple, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${mins}m ${secs}s', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                if (summary.isNotEmpty)
                  Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11)),
    );
  }
}
