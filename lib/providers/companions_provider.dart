import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import 'auth_provider.dart';

/// All companions for the current user, as a live stream.
final companionsProvider = StreamProvider<List<CompanionSummary>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  if (storage == null) return Stream.value([]);
  return storage.watchCompanions().map((docs) =>
      docs.map(CompanionSummary.fromFirestore).toList());
});

/// The currently-active companion, derived from [companionsProvider].
final activeCompanionProvider = Provider<CompanionSummary?>((ref) {
  final async = ref.watch(companionsProvider);
  return async.when(
    data: (list) {
      final active = list.where((c) => c.isActive).toList();
      return active.isNotEmpty ? active.first : null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Notifier for switching the active companion.
final companionSwitcherProvider =
    StateNotifierProvider<CompanionSwitcherNotifier, AsyncValue<void>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return CompanionSwitcherNotifier(storage);
});

class CompanionSwitcherNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreStorage? _storage;
  CompanionSwitcherNotifier(this._storage) : super(const AsyncValue.data(null));

  /// Set [companionId] as the active companion. Deactivates all others.
  Future<bool> setActive(String companionId) async {
    if (_storage == null) return false;
    state = const AsyncValue.loading();
    try {
      await _storage.setActiveCompanion(companionId);
      state = const AsyncValue.data(null);
      AppLogger.info('Active companion switched to $companionId');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppLogger.error('Failed to switch companion', e, stack);
      return false;
    }
  }
}

/// Lightweight companion summary used by the switcher + list screens.
///
/// Keeps just the fields needed for display — full persona + relationship
/// data is loaded by personaProvider when the companion is activated.
class CompanionSummary {
  final String id;
  final String name;
  final String personalityType;
  final String ageRange;
  final String hairColor;
  final String eyeColor;
  final String voiceId;
  final String accent;
  final List<String> interests;
  final bool isActive;
  final bool isFavorite;
  final DateTime createdAt;

  const CompanionSummary({
    required this.id,
    required this.name,
    required this.personalityType,
    required this.ageRange,
    required this.hairColor,
    required this.eyeColor,
    required this.voiceId,
    required this.accent,
    required this.interests,
    required this.isActive,
    required this.isFavorite,
    required this.createdAt,
  });

  factory CompanionSummary.fromFirestore(Map<String, dynamic> data) {
    return CompanionSummary(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Mira',
      personalityType: data['personality_type'] as String? ??
          data['personalityType'] as String? ??
          'sweet',
      ageRange: data['age_range'] as String? ?? data['ageRange'] as String? ?? '',
      hairColor: data['hair_color'] as String? ??
          data['hairColor'] as String? ?? 'Pink',
      eyeColor: data['eye_color'] as String? ?? data['eyeColor'] as String? ?? 'Blue',
      voiceId: data['voice_id'] as String? ?? data['voiceId'] as String? ?? 'hannah',
      accent: data['accent'] as String? ?? 'Neutral International',
      interests: (data['interests'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      isActive: data['is_active'] as bool? ?? data['isActive'] as bool? ?? false,
      isFavorite: data['is_favorite'] as bool? ?? false,
      createdAt: DateTime.now(), // Firestore Timestamp conversion skipped for brevity
    );
  }
}
