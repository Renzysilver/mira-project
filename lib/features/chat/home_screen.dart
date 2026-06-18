import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

/// Live call history stream for the active companion.
final _callHistoryProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final companionId = ref.watch(personaProvider.select((s) => s.companionId));
  if (storage == null || companionId == null) return Stream.value([]);
  return storage.watchCompanionCallLogs(companionId);
});

String _personalityLabel(PersonaModel persona) {
  if (persona.personalityTraits.isNotEmpty) {
    return persona.personalityTraits.join(' · ');
  }
  return switch (persona.personalityType) {
    PersonalityType.sweet => 'Sweet & caring',
    PersonalityType.tsundere => 'Tsundere',
    PersonalityType.intellectual => 'Intellectual',
  };
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sidebarOpen = false;

  void _openSidebar() => setState(() => _sidebarOpen = true);
  void _closeSidebar() => setState(() => _sidebarOpen = false);

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaProvider).persona;
    final relationship = ref.watch(personaProvider).relationship;
    final user = ref.watch(authProvider).user;
    final name = user?.displayName?.split(' ').first ?? 'you';
    final callHistoryAsync = ref.watch(_callHistoryProvider);

    return MainShell(
      currentIndex: 2,
      child: Stack(
        children: [
          AtmosphericBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar with hamburger menu
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _openSidebar,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: const Icon(Icons.menu_rounded,
                                  color: AppTheme.moonWhite, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, $name',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        letterSpacing: 1.5)),
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.auroraGradient.createShader(b),
                                  child: const Text('Mira',
                                      style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.white,
                                          letterSpacing: 4)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _TopIconBtn(
                                  icon: Icons.add_rounded,
                                  onTap: () => context.go('/companion/new')),
                              const SizedBox(width: 8),
                              _TopIconBtn(
                                  icon: Icons.settings_outlined,
                                  onTap: () => context.go('/settings')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Assistant status banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _AssistantStatusBanner(),
                    ),
                    const SizedBox(height: 24),
                    // Hero companion card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _HeroCompanionCard(
                        persona: persona,
                        affectionLevel: relationship.affectionLevel,
                        affectionLabel: relationship.affectionLabel,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _ActionCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat',
                            sublabel: 'Send a message',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A2080), Color(0xFF9B6DFF)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                            onTap: () => context.go('/chat'),
                          )),
                          const SizedBox(width: 14),
                          Expanded(child: _ActionCard(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            sublabel: 'Hear her voice',
                            gradient: AppTheme.pinkGradient,
                            onTap: () => context.go('/call'),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _ActionCard(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Persona',
                            sublabel: 'Her character',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF204080), Color(0xFFA7C4FF)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                            onTap: () => context.go('/persona'),
                          )),
                          const SizedBox(width: 14),
                          Expanded(child: _ActionCard(
                            icon: Icons.psychology_outlined,
                            label: 'Memory',
                            sublabel: 'What she knows',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A4020), Color(0xFF98F5C4)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                            onTap: () => context.go('/memory'),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Relationship stats
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: _SectionLabel(label: 'Relationship'),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            _StatPill(label: 'Days', value: '${relationship.daysTogether}', icon: Icons.calendar_today_outlined, color: AppTheme.auroraBlue),
                            _StatPill(label: 'Messages', value: '${relationship.messagesSent}', icon: Icons.chat_outlined, color: AppTheme.moonRose),
                            _StatPill(label: 'Calls', value: '${relationship.callsMade}', icon: Icons.call_outlined, color: AppTheme.successGreen),
                            _StatPill(label: 'Streak', value: '${relationship.streakDays}d', icon: Icons.local_fire_department_outlined, color: AppTheme.accentGold),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Call history
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel(label: 'Call History'),
                          TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppTheme.magentaAccent, fontSize: 11, letterSpacing: 0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: callHistoryAsync.when(
                        data: (calls) {
                          if (calls.isEmpty) {
                            return _EmptyCard(icon: Icons.call_outlined, text: 'No calls yet. Tap "Call" to hear ${persona.name}\'s voice.');
                          }
                          return Column(
                            children: calls.take(4).map((call) {
                              final duration = call['duration'] as int? ?? 0;
                              final summary = (call['summary'] as String?) ?? '(no summary)';
                              final timeStr = 'Recently';
                              return _CallHistoryItem(duration: duration, summary: summary, timeStr: timeStr);
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppTheme.magentaAccent, strokeWidth: 2))),
                        error: (e, _) => _EmptyCard(icon: Icons.error_outline, text: 'Failed to load call history.'),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('she\'s waiting for you  ✦',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.6), letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sidebar overlay
          if (_sidebarOpen)
            MiraSidebar(onClose: _closeSidebar),
        ],
      ),
    );
  }
}

class _AssistantStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.magentaAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.magentaAccent.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.successGreen,
              boxShadow: [BoxShadow(color: AppTheme.successGreen.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mira Assistant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.moonWhite, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text('Ready to help', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary.withOpacity(0.8), letterSpacing: 0.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/mira'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(gradient: AppTheme.auroraGradient, borderRadius: BorderRadius.circular(14)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Ask Mira', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────

class _HeroCompanionCard extends StatelessWidget {
  final PersonaModel persona;
  final int affectionLevel;
  final String affectionLabel;

  const _HeroCompanionCard({
    required this.persona,
    required this.affectionLevel,
    required this.affectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.softLavender.withOpacity(0.12),
                AppTheme.moonRose.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.magentaAccent.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Big avatar with pink glow ring
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.pinkGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.magentaAccent.withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.midnightBlue,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const MiraAvatarWidget(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.name.isNotEmpty ? persona.name : 'Mira',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite,
                              letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(_personalityLabel(persona),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.successGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('online',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Affection bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(affectionLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.moonRose,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500)),
                  Text('$affectionLevel%',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withOpacity(0.8))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: affectionLevel / 100,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.magentaAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: AppTheme.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.moonWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
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
    return Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary.withOpacity(0.7),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500));
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.moonWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _CallHistoryItem extends StatelessWidget {
  final int duration;
  final String summary;
  final String timeStr;
  const _CallHistoryItem({
    required this.duration,
    required this.summary,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final mins = duration ~/ 60;
    final secs = duration % 60;
    final durStr = '${mins}m ${secs}s';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.magentaAccent.withOpacity(0.15),
              border: Border.all(
                  color: AppTheme.magentaAccent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.call,
                color: AppTheme.magentaAccent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(durStr,
                        style: const TextStyle(
                            color: AppTheme.moonWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text('·',
                        style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5))),
                    const SizedBox(width: 8),
                    Text(timeStr,
                        style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32, color: AppTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  fontSize: 12,
                  height: 1.4,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
