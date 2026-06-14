import 'dart:math';
import 'package:rive/rive.dart';

class MiraTalkingController extends RiveAnimationController<RuntimeArtboard> {
  bool _talking = false;

  // Use dynamic to avoid importing internal Node type from lib/src
  dynamic _shape3;
  dynamic _shape4;
  double _shape3BaseY = 0.0;
  double _shape4BaseY = 0.0;
  double _phase = 0.0;

  static const double _speed   = 10.0;
  static const double _maxOpen = 10.0;

  @override
  bool init(RuntimeArtboard core) {            // <-- 'core' not 'artboard'
    _shape3 = core.component('Custom Shape3');
    _shape4 = core.component('Custom Shape4');

    // Dynamic dispatch to read y — avoids needing Node import
    try { if (_shape3 != null) _shape3BaseY = (_shape3 as dynamic).y as double; } catch (_) {}
    try { if (_shape4 != null) _shape4BaseY = (_shape4 as dynamic).y as double; } catch (_) {}

    isActive = true;
    return _shape3 != null || _shape4 != null;
  }

  @override
  void apply(RuntimeArtboard core, double elapsedSeconds) {  // <-- 'core' not 'artboard'
    if (!_talking) return;

    _phase += elapsedSeconds * _speed;

    final open      = (sin(_phase) * 0.5 + 0.5) * _maxOpen;
    final jitter    = sin(_phase * 2.3) * 2.0;
    final finalOpen = (open + jitter).clamp(0.0, 12.0);

    try { (_shape3 as dynamic).y = _shape3BaseY - (finalOpen * 0.3); } catch (_) {}
    try { (_shape4 as dynamic).y = _shape4BaseY + finalOpen; } catch (_) {}
  }

  void startTalking() {
    _talking = true;
    _phase   = 0.0;
  }

  void stopTalking() {
    _talking = false;
    _phase   = 0.0;
    try { (_shape3 as dynamic).y = _shape3BaseY; } catch (_) {}
    try { (_shape4 as dynamic).y = _shape4BaseY; } catch (_) {}
  }
}