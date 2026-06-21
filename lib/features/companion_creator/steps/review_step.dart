import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero — name + personality
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.magentaAccent.withOpacity(0.15),
                  AppTheme.deepPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.magentaAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  state.name.isEmpty ? 'Mira' : state.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.moonWhite,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.personalityType.name} • ${state.ageRange}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Identity section
          _ReviewSection(title: 'Identity', items: [
            _ReviewItem('Name', state.name.isEmpty ? 'Mira' : state.name),
            _ReviewItem('Age range', state.ageRange),
            if (state.backgroundStory.isNotEmpty)
              _ReviewItem(
                  'Background', state.backgroundStory, maxLines: 3),
          ]),

          // Personality section
          _ReviewSection(title: 'Personality', items: [
            _ReviewItem('Base', state.personalityType.name),
            _ReviewItem('Traits', state.personalityTraits.join(', ')),
          ]),

          // Appearance section
          _ReviewSection(title: 'Appearance', items: [
            _ReviewItem('Hair', '${state.hairStyle} • ${state.hairColor}'),
            _ReviewItem('Eyes', state.eyeColor),
            _ReviewItem('Face', state.faceStyle),
            _ReviewItem('Clothing', state.clothing),
            if (state.accessories.isNotEmpty)
              _ReviewItem('Accessories', state.accessories.join(', ')),
          ]),

          // Voice section
          _ReviewSection(title: 'Voice', items: [
            _ReviewItem('Provider', state.voiceProvider),
            _ReviewItem('Voice ID', state.voiceId),
            _ReviewItem('Accent', state.accent),
            _ReviewItem('Tone', state.tone),
            _ReviewItem('Energy', state.energyLevel),
            _ReviewItem('Speed', state.speakingSpeed),
          ]),

          // Interests section
          if (state.interests.isNotEmpty)
            _ReviewSection(title: 'Interests', items: [
              _ReviewItem('Selected', state.interests.join(', ')),
            ]),

          const SizedBox(height: 20),

          // Hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Avatar visual will use a Rive placeholder for now. '
                    'Future versions will support AI-generated portraits '
                    'based on your appearance selections.',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<_ReviewItem> items;
  const _ReviewSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary.withOpacity(0.7),
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  const _ReviewItem(this.label, this.value, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.moonWhite,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
