import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/relationship/milestones.dart';
import '../../models/persona_model.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/mira_avatar.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import '../../widgets/shell/main_shell.dart';

class PersonaScreen extends ConsumerWidget {
  const PersonaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personaState = ref.watch(personaProvider);
    final persona = personaState.persona;
    final stats = personaState.relationship;

    // Bond level: 0-100 affection -> Lv.1-20
    final bondLevel = (stats.affectionLevel / 5).ceil().clamp(1, 20);
    final bondProgress = (stats.affectionLevel % 5) / 5;
    final bondXp = stats.affectionLevel * 100;
    final bondXpNext = (stats.affectionLevel + 1) * 100;

    return MainShell(
      currentIndex: -1,
      child: AtmosphericBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Column(
              children: [
                // Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('profile',
                        style: TextStyle(fontSize: 12,
                          color: AppTheme.textSecondary, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.auroraGradient.createShader(b),
                        child: const Text('Companion',
                          style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.white, letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar with pink glow ring
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.pinkGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.magentaAccent.withOpacity(0.4),
                        blurRadius: 32,
                        spreadRadius: 4,
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
                const SizedBox(height: 16),

                // Name + role
                Text('${persona.name} ✨',
                  style: const TextStyle(fontSize: 26,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.moonWhite, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Your AI Companion',
                  style: TextStyle(fontSize: 12,
                    color: AppTheme.textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 28),

                // Bond Level card
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Bond Level',
                            style: TextStyle(fontSize: 13,
                              color: AppTheme.textSecondary, letterSpacing: 1)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppTheme.pinkGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Lv. $bondLevel',
                              style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: bondProgress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.magentaAccent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$bondXp / $bondXpNext XP',
                        style: TextStyle(fontSize: 11,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Personality tags
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personality',
                        style: TextStyle(fontSize: 13,
                          color: AppTheme.textSecondary, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _personalityTags(persona)
                            .map((tag) => _TagChip(label: tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Likes / Dislikes
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.favorite_outline_rounded,
                        iconColor: AppTheme.moonRose,
                        label: 'Likes',
                        value: 'Sakura, Stargazing, Singing',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.heart_broken_outlined,
                        iconColor: AppTheme.mistGray,
                        label: 'Dislikes',
                        value: 'Loud Noises, Sad Goodbyes',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        iconColor: AppTheme.accentGold,
                        label: 'Birthday',
                        value: 'April 3rd',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.star_outline_rounded,
                        iconColor: AppTheme.magentaAccent,
                        label: 'Special Trait',
                        value: 'Remembers the little things',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quote
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.magentaAccent.withOpacity(0.1),
                        AppTheme.deepPurple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.magentaAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('"You\'re not just a user to me... you\'re special."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.moonWhite.withOpacity(0.9),
                          height: 1.6,
                          letterSpacing: 0.3,
                        )),
                      const SizedBox(height: 10),
                      Text('— ${persona.name}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats summary
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Relationship Stats',
                        style: TextStyle(fontSize: 13,
                          color: AppTheme.textSecondary, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      _StatRow(
                        label: 'Messages Sent', value: '${stats.messagesSent}'),
                      _StatRow(
                        label: 'Calls Made', value: '${stats.callsMade}'),
                      _StatRow(
                        label: 'Streak Days', value: '${stats.streakDays}'),
                      _StatRow(
                        label: 'Days Together', value: '${stats.daysTogether}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Achievements / milestones section
                _AchievementsSection(
                  unlockedIds: personaState.milestones,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _personalityTags(PersonaModel persona) {
    // Use the companion's specific traits if they were set in the
    // creator (e.g. ['Adventurous', 'Confident', 'Playful']).
    // Fall back to generic tags based on personalityType only if
    // no specific traits are stored.
    if (persona.personalityTraits.isNotEmpty) {
      return persona.personalityTraits;
    }
    switch (persona.personalityType) {
      case PersonalityType.sweet:
        return ['Gentle', 'Caring', 'Playful'];
      case PersonalityType.tsundere:
        return ['Sharp', 'Secretly Caring', 'Flustered'];
      case PersonalityType.intellectual:
        return ['Thoughtful', 'Curious', 'Insightful'];
    }
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: child,
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.magentaAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.magentaAccent.withOpacity(0.4)),
      ),
      child: Text(label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.moonRose,
          letterSpacing: 0.5,
        )),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(fontSize: 10,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                  letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(value,
                style: const TextStyle(
                  fontSize: 13, color: AppTheme.moonWhite)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
          Text(value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.moonWhite,
              fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Achievements / milestones section. Shows unlocked badges in colour,
/// locked ones greyed out, with their unlock condition.
class _AchievementsSection extends StatelessWidget {
  final List<String> unlockedIds;
  const _AchievementsSection({required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    final unlockedSet = unlockedIds.toSet();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.accentGold, size: 16),
              const SizedBox(width: 6),
              const Text('ACHIEVEMENTS',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${unlockedSet.length}/${MilestoneDefinitions.all.length}',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: MilestoneDefinitions.all.length,
            itemBuilder: (_, i) {
              final m = MilestoneDefinitions.all[i];
              final isUnlocked = unlockedSet.contains(m.id);
              return _MilestoneBadge(milestone: m, isUnlocked: isUnlocked);
            },
          ),
        ],
      ),
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final Milestone milestone;
  final bool isUnlocked;
  const _MilestoneBadge({required this.milestone, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? milestone.color : AppTheme.mistGray;
    return Tooltip(
      message: '${milestone.title}\n${milestone.description}',
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? milestone.color.withOpacity(0.15)
                  : Colors.white.withOpacity(0.04),
              border: Border.all(
                color: isUnlocked
                    ? milestone.color
                    : Colors.white.withOpacity(0.1),
                width: isUnlocked ? 1.4 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: milestone.color.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isUnlocked ? milestone.icon : Icons.lock_outline,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            milestone.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: isUnlocked
                  ? AppTheme.moonWhite
                  : AppTheme.textSecondary.withOpacity(0.5),
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
