import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../core/utils/logger.dart';

final memoryServiceProvider = Provider<MemoryService>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return MemoryService(storage);
});

final memoryFactsProvider = StreamProvider<List<String>>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  if (storage == null) return Stream.value([]);
  return storage.watchMemoryFacts();
});

class MemoryService {
  final FirestoreStorage? _storage;
  MemoryService(this._storage);

  Future<List<String>> getMemoryFacts() async {
    if (_storage == null) return [];
    return _storage.getMemoryFacts();
  }

  Future<void> addFact(String fact, {String category = 'personal'}) async {
    if (_storage == null) return;
    await _storage.saveMemoryFact(fact);
    AppLogger.info('Memory stored: $fact');
  }

  Future<void> processMessage(String message) async {
    final facts = _extractFacts(message);
    for (final fact in facts) {
      await addFact(fact);
    }
  }

  Future<void> clearAll() async {
    if (_storage == null) return;
    await _storage.clearMemoryFacts();
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