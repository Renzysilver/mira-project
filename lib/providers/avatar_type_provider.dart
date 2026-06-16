import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/avatar_type.dart';

// Persists avatar choice across sessions using the existing settings Hive box
final avatarTypeProvider = StateNotifierProvider<AvatarTypeNotifier, AvatarType>((ref) {
  return AvatarTypeNotifier();
});

class AvatarTypeNotifier extends StateNotifier<AvatarType> {
  static const _key = 'selectedAvatar';

  AvatarTypeNotifier() : super(AvatarType.animeGirlRemix) {
    _load();
  }

  void _load() {
    final box = Hive.box('settings');
    final saved = box.get(_key, defaultValue: 0) as int;
    state = AvatarType.values[saved];
  }

  Future<void> select(AvatarType type) async {
    state = type;
    final box = Hive.box('settings');
    await box.put(_key, type.index);
  }
}