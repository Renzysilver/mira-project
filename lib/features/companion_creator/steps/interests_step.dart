import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class InterestsStep extends ConsumerWidget {
  const InterestsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    final iconMap = <String, IconData>{
      'Gaming': Icons.sports_esports_outlined,
      'Anime': Icons.auto_awesome_outlined,
      'Music': Icons.music_note_outlined,
      'Technology': Icons.memory,
      'Books': Icons.book_outlined,
      'Fitness': Icons.fitness_center_outlined,
      'Education': Icons.school_outlined,
      'Art': Icons.palette_outlined,
      'Cooking': Icons.restaurant_outlined,
      'Travel': Icons.flight_outlined,
      'Photography': Icons.camera_alt_outlined,
      'Writing': Icons.edit_note,
      'Sports': Icons.sports_basketball_outlined,
      'Dance': Icons.music_video_outlined,
    };

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Pick what she loves. These will shape her conversations.',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.interests.map((interest) {
              return SelectChip(
                label: interest,
                isSelected: state.interests.contains(interest),
                onTap: () => notifier.toggleInterest(interest),
                icon: iconMap[interest],
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          if (state.interests.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.glassWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECTED (${state.interests.length})',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.magentaAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.magentaAccent
                                  .withOpacity(0.4)),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                              color: AppTheme.moonRose,
                              fontSize: 11,
                              letterSpacing: 0.4),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
