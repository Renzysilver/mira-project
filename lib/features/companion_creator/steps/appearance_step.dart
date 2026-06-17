import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class AppearanceStep extends ConsumerWidget {
  const AppearanceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepFieldLabel(label: 'Hair Style'),
          _buildChipWrap(
              CompanionCreatorOptions.hairStyles,
              state.hairStyle,
              (v) => notifier.setHairStyle(v)),
          const StepFieldLabel(label: 'Hair Color'),
          _buildColorChipWrap(
              CompanionCreatorOptions.hairColors,
              state.hairColor,
              (v) => notifier.setHairColor(v)),
          const StepFieldLabel(label: 'Eye Color'),
          _buildColorChipWrap(
              CompanionCreatorOptions.eyeColors,
              state.eyeColor,
              (v) => notifier.setEyeColor(v)),
          const StepFieldLabel(label: 'Face Style'),
          _buildChipWrap(
              CompanionCreatorOptions.faceStyles,
              state.faceStyle,
              (v) => notifier.setFaceStyle(v)),
          const StepFieldLabel(label: 'Clothing'),
          _buildChipWrap(
              CompanionCreatorOptions.clothingStyles,
              state.clothing,
              (v) => notifier.setClothing(v)),
          const StepFieldLabel(label: 'Accessories (select multiple)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.accessories.map((a) {
              return SelectChip(
                label: a,
                isSelected: state.accessories.contains(a),
                onTap: () => notifier.toggleAccessory(a),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChipWrap(List<String> options, String current,
      void Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return SelectChip(
          label: opt,
          isSelected: current == opt,
          onTap: () => onSelect(opt),
        );
      }).toList(),
    );
  }

  Widget _buildColorChipWrap(List<String> options, String current,
      void Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return _ColorChip(
          label: opt,
          color: _parseColor(opt),
          isSelected: current == opt,
          onTap: () => onSelect(opt),
        );
      }).toList(),
    );
  }

  /// Map color name -> Flutter Color for the color picker chips.
  Color _parseColor(String name) {
    const map = {
      'Black': Color(0xFF1A1A1A),
      'Brown': Color(0xFF6B4423),
      'Blonde': Color(0xFFFFD700),
      'Red': Color(0xFFC0392B),
      'Pink': Color(0xFFFFB7C5),
      'Blue': Color(0xFF3498DB),
      'Purple': Color(0xFF9B59B6),
      'White': Color(0xFFFAFAFA),
      'Silver': Color(0xFFC0C0C0),
      'Green': Color(0xFF27AE60),
      'Hazel': Color(0xFF8E5A2B),
      'Gray': Color(0xFF7F8C8D),
      'Amber': Color(0xFFFFBF00),
      'Violet': Color(0xFF8E44AD),
    };
    return map[name] ?? const Color(0xFF888888);
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE83E8C).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE83E8C)
                : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFFFFB7C5)
                    : const Color(0xFFAA99CC),
                fontWeight:
                    isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
