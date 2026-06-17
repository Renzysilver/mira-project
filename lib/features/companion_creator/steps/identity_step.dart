import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class IdentityStep extends ConsumerWidget {
  const IdentityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepFieldLabel(label: 'Name'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: TextField(
              onChanged: notifier.setName,
              style: const TextStyle(
                color: AppTheme.moonWhite,
                fontSize: 16,
                letterSpacing: 1,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Mira, Luna, Aurora...',
                hintStyle: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),

          const StepFieldLabel(label: 'Age Range'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.ageRanges.map((a) {
              return SelectChip(
                label: a,
                isSelected: state.ageRange == a,
                onTap: () => notifier.setAgeRange(a),
              );
            }).toList(),
          ),

          const StepFieldLabel(label: 'Background Story'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: TextField(
              onChanged: notifier.setBackgroundStory,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(
                color: AppTheme.moonWhite,
                fontSize: 13,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Where does she come from? What shaped her personality? What are her dreams?',
                hintStyle: TextStyle(color: AppTheme.mistGray, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
