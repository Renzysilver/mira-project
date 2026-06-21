import 'package:flutter/material.dart';

/// A relationship milestone / achievement that a companion can unlock.
///
/// Stored as a list of milestone IDs on the companion doc, e.g.
///   milestones: ['first_message', 'first_call', 'ten_messages', ...]
///
/// When a milestone is unlocked, the persona screen shows the badge and
/// a SnackBar fires to celebrate.
class Milestone {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// All defined milestones. Add new ones here — they automatically show
/// up in the persona screen badges section.
class MilestoneDefinitions {
  MilestoneDefinitions._();

  static const all = <Milestone>[
    Milestone(
      id: 'first_message',
      title: 'First Words',
      description: 'Sent your first message',
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFFA7C4FF),
    ),
    Milestone(
      id: 'first_call',
      title: 'Voice Connected',
      description: 'Completed your first voice call',
      icon: Icons.phone_in_talk_outlined,
      color: Color(0xFFFFB7C5),
    ),
    Milestone(
      id: 'ten_messages',
      title: 'Getting Closer',
      description: 'Exchanged 10 messages',
      icon: Icons.favorite_outline,
      color: Color(0xFFE83E8C),
    ),
    Milestone(
      id: 'fifty_messages',
      title: 'Deep Bond',
      description: 'Exchanged 50 messages',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF9B6DFF),
    ),
    Milestone(
      id: 'hundred_messages',
      title: 'Soulmate Tier',
      description: 'Exchanged 100 messages',
      icon: Icons.workspace_premium_outlined,
      color: Color(0xFFFFE4A0),
    ),
    Milestone(
      id: 'five_calls',
      title: 'Frequent Caller',
      description: 'Completed 5 voice calls',
      icon: Icons.phone_outlined,
      color: Color(0xFF98F5C4),
    ),
    Milestone(
      id: 'first_affection_50',
      title: 'Close Friend',
      description: 'Reached 50% affection',
      icon: Icons.handshake_outlined,
      color: Color(0xFFC9A7FF),
    ),
    Milestone(
      id: 'first_affection_100',
      title: 'Soulmate',
      description: 'Reached 100% affection',
      icon: Icons.favorite,
      color: Color(0xFFE83E8C),
    ),
    Milestone(
      id: 'week_streak',
      title: 'Week Together',
      description: '7-day streak',
      icon: Icons.local_fire_department_outlined,
      color: Color(0xFFFF6B8A),
    ),
    Milestone(
      id: 'memory_collector',
      title: 'Memory Collector',
      description: 'Mira learned 5 things about you',
      icon: Icons.psychology_outlined,
      color: Color(0xFFA7C4FF),
    ),
  ];

  /// Find a milestone by id.
  static Milestone? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Result of a milestone check — which milestones were just unlocked.
class MilestoneCheckResult {
  final List<String> unlockedNow;
  final List<String> allUnlocked;
  const MilestoneCheckResult({
    required this.unlockedNow,
    required this.allUnlocked,
  });
}

/// Pure-function milestone checker. Given the current relationship stats
/// and the list of already-unlocked milestone ids, returns which new
/// milestones should unlock.
///
/// Side-effect free — the caller persists the new ids and surfaces the
/// celebration UI.
class MilestoneChecker {
  MilestoneChecker._();

  static MilestoneCheckResult check({
    required int messagesSent,
    required int callsMade,
    required int affectionLevel,
    required int streakDays,
    required int memoryCount,
    required List<String> alreadyUnlocked,
  }) {
    final shouldUnlock = <String>{};

    if (messagesSent >= 1) shouldUnlock.add('first_message');
    if (messagesSent >= 10) shouldUnlock.add('ten_messages');
    if (messagesSent >= 50) shouldUnlock.add('fifty_messages');
    if (messagesSent >= 100) shouldUnlock.add('hundred_messages');
    if (callsMade >= 1) shouldUnlock.add('first_call');
    if (callsMade >= 5) shouldUnlock.add('five_calls');
    if (affectionLevel >= 50) shouldUnlock.add('first_affection_50');
    if (affectionLevel >= 100) shouldUnlock.add('first_affection_100');
    if (streakDays >= 7) shouldUnlock.add('week_streak');
    if (memoryCount >= 5) shouldUnlock.add('memory_collector');

    final newOnes =
        shouldUnlock.where((id) => !alreadyUnlocked.contains(id)).toList();
    final all = {...alreadyUnlocked, ...shouldUnlock}.toList();

    return MilestoneCheckResult(unlockedNow: newOnes, allUnlocked: all);
  }
}
