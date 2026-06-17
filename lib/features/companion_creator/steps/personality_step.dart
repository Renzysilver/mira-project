import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../models/persona_model.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class PersonalityStep extends ConsumerWidget {
  const PersonalityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepFieldLabel(label: 'Base Personality'),
          _buildPersonalityTypeCards(state, notifier),
          const StepFieldLabel(label: 'Personality Traits (select multiple)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                CompanionCreatorOptions.personalityTraits.map((trait) {
              return SelectChip(
                label: trait,
                isSelected: state.personalityTraits.contains(trait),
                onTap: () => notifier.toggleTrait(trait),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPersonalityTypeCards(
      CompanionCreatorState state, CompanionCreatorNotifier notifier) {
    final types = [
      _PersonalityCard(
        type: PersonalityType.sweet,
        name: 'Sweet & Caring',
        desc: 'Warm, nurturing, freely loving',
        icon: Icons.favorite_outline_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFE83E8C), Color(0xFFFFB7C5)],
        ),
      ),
      _PersonalityCard(
        type: PersonalityType.tsundere,
        name: 'Tsundere',
        desc: 'Sharp outside, soft inside',
        icon: Icons.masks_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF5A189A), Color(0xFF9B6DFF)],
        ),
      ),
      _PersonalityCard(
        type: PersonalityType.intellectual,
        name: 'Intellectual',
        desc: 'Curious, thoughtful, deep',
        icon: Icons.psychology_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF204080), Color(0xFFA7C4FF)],
        ),
      ),
    ];

    return Column(
      children: types.map((p) {
        final isSelected = p.type == state.personalityType;
        return GestureDetector(
          onTap: () => notifier.setPersonalityType(p.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.glassWhite
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.magentaAccent
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: p.gradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              color: AppTheme.moonWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(p.desc,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.magentaAccent, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PersonalityCard {
  final PersonalityType type;
  final String name;
  final String desc;
  final IconData icon;
  final Gradient gradient;
  const _PersonalityCard({
    required this.type,
    required this.name,
    required this.desc,
    required this.icon,
    required this.gradient,
  });
}
