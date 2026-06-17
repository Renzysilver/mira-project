import 'dart:math';
import 'package:rive/rive.dart';
import '../models/avatar_type.dart';

class MiraTalkingController extends RiveAnimationController<RuntimeArtboard> {
  final AvatarType avatarType;
  MiraTalkingController(this.avatarType);

  bool _talking = false;
  dynamic _upperLip;
  dynamic _lowerLip;
  double _upperBaseY = 0.0;
  double _lowerBaseY = 0.0;
  double _phase = 0.0;

  static const double _speed   = 10.0;
  static const double _maxOpen = 10.0;

  @override
  bool init(RuntimeArtboard core) {
    // Each avatar uses different component names
    if (avatarType == AvatarType.animeGirl) {
      _upperLip = core.component('Upper Lip');
      _lowerLip = core.component('Bottom Lip');
    } else {
      _upperLip = core.component('Custom Shape3');
      _lowerLip = core.component('Custom Shape4');
    }

    try { if (_upperLip != null) _upperBaseY = (_upperLip as dynamic).y as double; } catch (_) {}
    try { if (_lowerLip != null) _lowerBaseY = (_lowerLip as dynamic).y as double; } catch (_) {}

    isActive = true;
    return _upperLip != null || _lowerLip != null;
  }

  @override
  void apply(RuntimeArtboard core, double elapsedSeconds) {
    if (!_talking) return;

    _phase += elapsedSeconds * _speed;

    final open      = (sin(_phase) * 0.5 + 0.5) * _maxOpen;
    final jitter    = sin(_phase * 2.3) * 2.0;
    final finalOpen = (open + jitter).clamp(0.0, 12.0);

    try { (_upperLip as dynamic).y = _upperBaseY - (finalOpen * 0.3); } catch (_) {}
    try { (_lowerLip as dynamic).y = _lowerBaseY + finalOpen; } catch (_) {}
  }

  void startTalking() { _talking = true;  _phase = 0.0; }

  void stopTalking() {
    _talking = false;
    _phase   = 0.0;
    try { (_upperLip as dynamic).y = _upperBaseY; } catch (_) {}
    try { (_lowerLip as dynamic).y = _lowerBaseY; } catch (_) {}
  }
}