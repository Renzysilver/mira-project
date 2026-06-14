import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/memory_service.dart';

final memoryFactsProvider = FutureProvider<List<String>>((ref) async {
  final memoryService = ref.read(memoryServiceProvider);
  return memoryService.getMemoryFacts();
});
