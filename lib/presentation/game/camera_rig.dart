import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../core/constants.dart';
import 'shadow_relic_game.dart';

/// Cible suivie par la caméra : lissage, anticipation du regard,
/// secousses, et survol automatique du niveau derrière le menu.
class CameraRig extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  CameraRig({required Vector2 position}) : super(position: position);

  static const _attractMinX = 12 * kTile;
  static const _attractMaxX = 104 * kTile;
  static const _attractY = 20 * kTile;

  final _smooth = Vector2.zero();
  final _rng = math.Random();
  double _lookAhead = 0;
  double _shakeT = 0;
  double _shakeDuration = 1;
  double _shakeMag = 0;
  int _attractDir = 1;

  @override
  void onMount() {
    super.onMount();
    _smooth.setFrom(position);
  }

  void snapTo(Vector2 p) {
    _smooth.setFrom(p);
    position.setFrom(p);
  }

  void shake(double magnitude, double duration) {
    if (magnitude < _shakeMag && _shakeT > 0) return;
    _shakeMag = magnitude;
    _shakeDuration = duration;
    _shakeT = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = Vector2.zero();

    if (game.playing) {
      final p = game.player;
      final want = p.facing * 34 * kScale + p.vel.x * 0.08;
      _lookAhead += (want - _lookAhead) * (1 - math.exp(-3 * dt));
      target.setValues(
        p.x + p.width / 2 + _lookAhead,
        p.y + p.height / 2 - 12 * kScale + math.max(0, p.vel.y) * 0.05,
      );
      _smooth.add((target - _smooth) * (1 - math.exp(-9 * dt)));
    } else {
      _smooth.x += _attractDir * 22 * dt;
      _smooth.y += (_attractY - _smooth.y) * (1 - math.exp(-1.5 * dt));
      if (_smooth.x > _attractMaxX) _attractDir = -1;
      if (_smooth.x < _attractMinX) _attractDir = 1;
    }

    position.setFrom(_smooth);
    if (_shakeT > 0) {
      _shakeT -= dt;
      final k = _shakeMag * (_shakeT / _shakeDuration).clamp(0.0, 1.0);
      position.add(Vector2(
        (_rng.nextDouble() * 2 - 1) * k,
        (_rng.nextDouble() * 2 - 1) * k,
      ));
    } else {
      _shakeMag = 0;
    }
  }
}
