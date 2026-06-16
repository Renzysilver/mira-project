import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/avatar_type.dart';
import '../providers/avatar_type_provider.dart';

/// Drop this anywhere — settings screen, onboarding, profile page
class AvatarSwitcherWidget extends ConsumerWidget {
  const AvatarSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(avatarTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Avatar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AvatarOption(
              label: 'Remix',
              type: AvatarType.animeGirlRemix,
              isSelected: current == AvatarType.animeGirlRemix,
              onTap: () => ref.read(avatarTypeProvider.notifier).select(
                AvatarType.animeGirlRemix,
              ),
            ),
            const SizedBox(width: 16),
            _AvatarOption(
              label: 'Classic',
              type: AvatarType.animeGirl,
              isSelected: current == AvatarType.animeGirl,
              onTap: () => ref.read(avatarTypeProvider.notifier).select(
                AvatarType.animeGirl,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final String label;
  final AvatarType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.label,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFB388FF) : Colors.white24,
            width: 2,
          ),
          color: isSelected
              ? const Color(0xFFB388FF).withValues(alpha : 0.2)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFB388FF) : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}