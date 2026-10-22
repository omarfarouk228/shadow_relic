import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/render_utils.dart';

/// Ciel de crépuscule avec lune, étoiles scintillantes et trois couches de
/// décor en parallaxe. Dessiné en coordonnées écran, derrière le monde.
class Backdrop extends Component with HasGameReference<ShadowRelicGame> {
  Backdrop() {
    final rng = math.Random(7);
    for (var i = 0; i < 70; i++) {
      _stars.add((
        Offset(rng.nextDouble() * 1400, rng.nextDouble() * 170),
        rng.nextDouble() < 0.15 ? 1.6 : 0.8,
        rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  final List<(Offset, double, double)> _stars = [];
  double _t = 0;

  static final _sky = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Palette.skyTop, Palette.skyMid, Palette.skyHorizon],
      stops: [0, 0.55, 1],
    ).createShader(const Rect.fromLTWH(0, 0, kViewWidth, kViewHeight));

  late final _hillsPaint = solidPaint(Palette.hillsFar);
  late final _treesPaint = solidPaint(Palette.hillsNear);
  late final _cloudPaint = solidPaint(Palette.clouds);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final cam = game.camera.viewfinder.position;
    // décalage vertical léger : le décor descend quand on monte
    final vy = (cam.y - 20 * kTile) * 0.08;

    canvas.drawRect(const Rect.fromLTWH(0, 0, kViewWidth, kViewHeight), _sky);

    // étoiles
    final starPaint = Paint();
    for (final (pos, size, phase) in _stars) {
      final x = (pos.dx - cam.x * 0.03) % 1400;
      if (x > kViewWidth) continue;
      final a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_t * 2 + phase));
      starPaint.color = Palette.white.withValues(alpha: a);
      canvas.drawRect(
          Rect.fromLTWH(x.floorToDouble(), (pos.dy - vy * 0.3).floorToDouble(),
              size, size),
          starPaint);
    }

    // lune
    const moon = Offset(kViewWidth - 90, 34);
    drawGlow(canvas, moon, 60, Palette.moon, intensity: 0.22);
    canvas.drawCircle(moon, 13, Paint()..color = Palette.moon);
    canvas.drawCircle(
        moon.translate(4, -3), 10, Paint()..color = const Color(0x22B4506A));

    final sprites = game.sprites;
    const h = kViewHeight;
    _layer(canvas, sprites.cloudsLayer, cam.x * 0.06 + _t * 4,
        h * 0.42 - vy * 0.4, 2, _cloudPaint,
        fill: Palette.clouds);
    _layer(
        canvas, sprites.hillsLayer, cam.x * 0.15, h * 0.62 - vy, 3, _hillsPaint,
        fill: Palette.hillsFar);
    _layer(canvas, sprites.treesLayer, cam.x * 0.35, h * 0.80 - vy * 1.6, 3,
        _treesPaint,
        fill: Palette.hillsNear);
  }

  /// Répète une bande de sprites horizontalement, [scroll] en pixels.
  void _layer(
    Canvas canvas,
    List<Sprite> tiles,
    double scroll,
    double baseline,
    double scale,
    Paint paint, {
    Color? fill,
  }) {
    final w = 24 * scale;
    final band = w * tiles.length;
    final start = -(scroll % band);
    var i = 0;
    for (var x = start - band; x < kViewWidth; x += w) {
      tiles[i % tiles.length].render(
        canvas,
        position: Vector2(x.floorToDouble(), baseline - w),
        size: Vector2(w + 0.5, w),
        overridePaint: paint,
      );
      i++;
    }
    if (fill != null) {
      canvas.drawRect(Rect.fromLTWH(0, baseline - 1, kViewWidth, kViewHeight),
          Paint()..color = fill);
    }
  }
}

/// Assombrit les bords de l'écran pour l'ambiance.
class Vignette extends PositionComponent {
  Vignette() : super(size: Vector2(kViewWidth, kViewHeight), priority: 50);

  static final _paint = Paint()
    ..shader = const RadialGradient(
      radius: 0.85,
      colors: [Color(0x00000000), Color(0x00000000), Color(0x8C0A0618)],
      stops: [0, 0.55, 1],
    ).createShader(const Rect.fromLTWH(0, 0, kViewWidth, kViewHeight));

  @override
  void render(Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}
