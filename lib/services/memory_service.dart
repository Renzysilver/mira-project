import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../providers/companions_provider.dart';
import '../core/utils/logger.dart';

/// Memory service — now scoped per-companion.
///
/// Watches [activeCompanionProvider] and reads/writes memories at:
///   users/{uid}/companions/{companionId}/memories/facts
///
/// Each companion builds its own relationship with the user — memories
/// do NOT transfer between companions.
final memoryServiceProvider = Provider<MemoryService>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final activeCompanion = ref.watch(activeCompanionProvider);
  return MemoryService(storage, activeCompanion?.id);
});

final memoryFactsProvider = StreamProvider<List<String>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  final activeCompanion = ref.watch(activeCompanionProvider);
  if (storage == null || activeCompanion == null) return Stream.value([]);
  return storage.watchCompanionMemoryFacts(activeCompanion.id);
});

class MemoryService {
  final FirestoreStorage? _storage;
  final String? _companionId;
  MemoryService(this._storage, this._companionId);

  Future<List<String>> getMemoryFacts() async {
    if (_storage == null || _companionId == null) return [];
    return _storage.getCompanionMemoryFacts(_companionId!);
  }

  Future<void> addFact(String fact, {String category = 'personal'}) async {
    if (_storage == null || _companionId == null) return;
    await _storage.saveCompanionMemoryFact(_companionId!, fact);
    AppLogger.info('Memory stored for companion $_companionId: $fact');
  }

  Future<void> processMessage(String message) async {
    final facts = _extractFacts(message);
    for (final fact in facts) {
      await addFact(fact);
    }
  }

  Future<void> clearAll() async {
    if (_storage == null || _companionId == null) return;
    await _storage.clearCompanionMemoryFacts(_companionId!);
  }

  List<String> _extractFacts(String message) {
    final facts = <String>[];
    final lower = message.toLowerCase();
    if (lower.contains('my name is ')) {
      final parts = lower.split('my name is ');
      if (parts.length > 1) facts.add("User's name is ${parts[1].split(' ').first}");
    }
    if (lower.contains('i like ')) {
      final parts = lower.split('i like ');
      if (parts.length > 1) facts.add("User likes ${parts[1].split('.').first}");
    }
    return facts;
  }
}
