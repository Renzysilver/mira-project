import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

import '../controllers/mira_talking_controller.dart';
import '../models/avatar_type.dart';
import '../providers/avatar_type_provider.dart';

final isMiraSpeakingProvider = StateProvider<bool>((ref) => false);

class MiraAvatarWidget extends ConsumerStatefulWidget {
  const MiraAvatarWidget({super.key});

  @override
  ConsumerState<MiraAvatarWidget> createState() => _MiraAvatarWidgetState();
}

class _MiraAvatarWidgetState extends ConsumerState<MiraAvatarWidget> {
  Artboard? _artboard;
  StateMachineController? _stateMachine;
  MiraTalkingController? _talking;
  AvatarType? _loadedType;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRive());
  }

  String _assetPath(AvatarType type) {
    switch (type) {
      case AvatarType.animeGirlRemix:
        return 'assets/animations/animegirl.riv';
      case AvatarType.animeGirl:
        return 'assets/animations/animegirl2.riv';
    }
  }

  Future<void> _loadRive() async {
    final type = ref.read(avatarTypeProvider);

    final file = await RiveFile.asset(_assetPath(type));
    final artboard = file.mainArtboard;
    final talking = MiraTalkingController(type);

    final sm = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (sm != null) {
      artboard.addController(sm);
      _stateMachine = sm;
    }

    artboard.addController(talking);

    if (mounted) {
      setState(() {
        _artboard = artboard;
        _talking = talking;
        _loadedType = type;
        _loaded = true;
      });
    }
  }

  Future<void> _reload(AvatarType newType) async {
    if (newType == _loadedType) return;
    setState(() {
      _loaded = false;
      _artboard = null;
    });
    _stateMachine?.dispose();
    _stateMachine = null;
    _talking = null;
    await _loadRive();
  }

  @override
  void dispose() {
    // Both controllers are owned by the artboard — disposing the artboard
    // disposes them too. We null our refs to make intent explicit.
    _stateMachine?.dispose();
    _talking = null;
    _artboard?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AvatarType>(avatarTypeProvider, (_, next) => _reload(next));

    ref.listen<bool>(isMiraSpeakingProvider, (_, speaking) {
      speaking ? _talking?.startTalking() : _talking?.stopTalking();
    });

    if (!_loaded || _artboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Rive(artboard: _artboard!, fit: BoxFit.contain);
  }
}
