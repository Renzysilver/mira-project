import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/voice/voice_provider_registry.dart';
import '../companion_creator_provider.dart';
import '../companion_creator_state.dart';
import '_shared.dart';

class VoiceStep extends ConsumerWidget {
  const VoiceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionCreatorProvider);
    final notifier = ref.read(companionCreatorProvider.notifier);

    final activeVoiceProvider = VoiceProviderRegistry.active;
    final availableVoices = activeVoiceProvider.availableVoices;

    return StepScrollContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider info banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppTheme.magentaAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.magentaAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.graphic_eq,
                    color: AppTheme.magentaAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeVoiceProvider.displayName,
                        style: const TextStyle(
                            color: AppTheme.moonWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeVoiceProvider.isAvailable
                            ? 'Active voice provider'
                            : 'Not configured — set VOICE_PROVIDER in .env',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const StepFieldLabel(label: 'Voice'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableVoices.map((voice) {
              return SelectChip(
                label: voice.name,
                isSelected: state.voiceId == voice.id,
                onTap: () => notifier.setVoiceId(voice.id),
                icon: Icons.record_voice_over_outlined,
              );
            }).toList(),
          ),
          if (availableVoices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No voices available from ${activeVoiceProvider.displayName}.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ),

          const StepFieldLabel(label: 'Accent'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.accents.map((accent) {
              return SelectChip(
                label: accent,
                isSelected: state.accent == accent,
                onTap: () => notifier.setAccent(accent),
              );
            }).toList(),
          ),

          const StepFieldLabel(label: 'Tone'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.voiceTones.map((tone) {
              return SelectChip(
                label: tone,
                isSelected: state.tone == tone,
                onTap: () => notifier.setTone(tone),
              );
            }).toList(),
          ),

          const StepFieldLabel(label: 'Energy Level'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.energyLevels.map((level) {
              return SelectChip(
                label: level,
                isSelected: state.energyLevel == level,
                onTap: () => notifier.setEnergyLevel(level),
              );
            }).toList(),
          ),

          const StepFieldLabel(label: 'Speaking Speed'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanionCreatorOptions.speakingSpeeds.map((speed) {
              return SelectChip(
                label: speed,
                isSelected: state.speakingSpeed == speed,
                onTap: () => notifier.setSpeakingSpeed(speed),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
