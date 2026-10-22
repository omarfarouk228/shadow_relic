import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/entities/level_grid.dart';
import '../../domain/entities/tile.dart';
import '../game/shadow_relic_game.dart';

/// Dessine uniquement les tuiles visibles par la caméra.
class TileRenderer extends Component with HasGameReference<ShadowRelicGame> {
  TileRenderer(this.grid);

  final LevelGrid grid;

  static final _solid = Paint()..color = const Color(0xFF2A2F4A);
  static final _solidTop = Paint()..color = const Color(0xFF3D4569);
  static final _spike = Paint()..color = const Color(0xFFE05263);
  static final _gate = Paint()..color = const Color(0xFF8E5CFF);
  static final _gateLine = Paint()
    ..color = const Color(0xFFC9B2FF)
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    final x1 = math.max(0, (view.left / kTile).floor() - 1);
    final x2 = math.min(grid.cols - 1, (view.right / kTile).ceil() + 1);
    final y1 = math.max(0, (view.top / kTile).floor() - 1);
    final y2 = math.min(grid.rows - 1, (view.bottom / kTile).ceil() + 1);

    for (var cy = y1; cy <= y2; cy++) {
      for (var cx = x1; cx <= x2; cx++) {
        final t = grid.tiles[cy][cx];
        if (t == Tile.empty) continue;
        final px = cx * kTile;
        final py = cy * kTile;
        switch (t) {
          case Tile.solid:
            canvas.drawRect(Rect.fromLTWH(px, py, kTile, kTile), _solid);
            // liseré clair sur la face exposée au ciel
            if (!grid.isSolid(cx, cy - 1)) {
              canvas.drawRect(Rect.fromLTWH(px, py, kTile, 5), _solidTop);
            }
          case Tile.spike:
            for (var i = 0; i < 2; i++) {
              final sx = px + i * 16.0;
              canvas.drawPath(
                Path()
                  ..moveTo(sx, py + kTile)
                  ..lineTo(sx + 8, py + 10)
                  ..lineTo(sx + 16, py + kTile)
                  ..close(),
                _spike,
              );
            }
          case Tile.gate:
            canvas.drawRect(Rect.fromLTWH(px + 4, py, kTile - 8, kTile), _gate);
            canvas.drawLine(Offset(px + 10, py + 6),
                Offset(px + kTile - 10, py + kTile - 6), _gateLine);
          case Tile.empty:
            break;
        }
      }
    }
  }
}

/// Ciel étoilé avec léger effet de parallaxe.
class BackgroundStars extends Component with HasGameReference<ShadowRelicGame> {
  BackgroundStars(LevelGrid grid) {
    final rng = math.Random(42);
    for (var i = 0; i < 140; i++) {
      _stars.add(Offset(
        rng.nextDouble() * grid.worldWidth,
        rng.nextDouble() * grid.worldHeight,
      ));
      _sizes.add(0.8 + rng.nextDouble() * 1.6);
    }
  }

  final List<Offset> _stars = [];
  final List<double> _sizes = [];
  final _paint = Paint()..color = const Color(0x88AAB4E8);

  @override
  void render(Canvas canvas) {
    final view = game.camera.visibleWorldRect;
    // parallaxe : les étoiles "suivent" un peu la caméra
    final shift = Offset(view.left * 0.6, view.top * 0.6);
    for (var i = 0; i < _stars.length; i++) {
      final p = _stars[i] * 0.4 + shift;
      if (p.dx < view.left - 4 ||
          p.dx > view.right + 4 ||
          p.dy < view.top - 4 ||
          p.dy > view.bottom + 4) {
        continue;
      }
      canvas.drawCircle(p, _sizes[i], _paint);
    }
  }
}
