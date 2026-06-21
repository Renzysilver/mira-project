import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/companion_model.dart';
import 'auth_provider.dart';
import 'persona_provider.dart';

/// The currently active companion.
///
/// For now there's only one companion per user (the legacy single-companion
/// behaviour), so this just wraps personaProvider. When multi-companion
/// support lands, this provider will track the user's selected companion
/// ID and expose the matching CompanionModel.
final currentCompanionProvider = Provider<CompanionModel>((ref) {
  final personaState = ref.watch(personaProvider);
  final user = ref.watch(authProvider).user;
  return CompanionModel(
    id: user?.uid != null ? 'companion_${user!.uid}' : 'default',
    persona: personaState.persona,
    relationship: personaState.relationship,
    createdAt: DateTime.now(),
  );
});

/// Placeholder for the future list of all the user's companions.
///
/// Currently returns a single-item list containing the current companion.
/// When multi-companion lands, this will read from a `companions`
/// collection in Firestore.
final companionsProvider = Provider<List<CompanionModel>>((ref) {
  final current = ref.watch(currentCompanionProvider);
  return [current];
});
