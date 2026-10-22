import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/entities/level_grid.dart';
import '../../domain/entities/tile.dart';
import '../game/shadow_relic_game.dart';

/// Dessine uniquement les tuiles visibles par la caméra, avec raccords
/// d'herbe, contours, ombrage en profondeur et petites décorations.
class TileRenderer extends Component with HasGameReference<ShadowRelicGame> {
  TileRenderer(this.grid);

  final LevelGrid grid;

  /// Décorations posées sur le sol : (cx, cy, index du sprite).
  final List<(int, int, int)> _decor = [];

  static final _outline = Paint()..color = Palette.outline;

  /// Ombrage en profondeur : un dégradé par niveau (1 à 4 tuiles sous la
  /// surface), en coordonnées locales de tuile.
  static final _depthPaints = [
    for (var d = 1; d <= 4; d++)
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(12, 6, 30, (d - 1) * 0.16),
            Color.fromRGBO(12, 6, 30, math.min(4, d) * 0.16),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, kTile, kTile)),
  ];
  static final _size = Vector2.all(kTile);

  @override
  Future<void> onLoad() async {
    final rng = math.Random(1234);
    final spawnCells = {for (final s in grid.spawns) (s.cx, s.cy)};
    for (var cy = 1; cy < grid.rows; cy++) {
      for (var cx = 1; cx < grid.cols - 1; cx++) {
        if (grid.at(cx, cy) != Tile.solid) continue;
        if (grid.at(cx, cy - 1) != Tile.empty) continue;
        if (spawnCells.contains((cx, cy - 1))) continue;
        if (rng.nextDouble() < 0.18) {
          _decor.add((cx, cy - 1, rng.nextInt(4)));
        }
      }
    }
  }

  bool _solid(int cx, int cy) => grid.at(cx, cy) == Tile.solid;

  /// Nombre de tuiles pleines au-dessus (0 = surface), plafonné à 4.
  int _depthOf(int cx, int cy) {
    var d = 0;
    while (d < 4 && _solid(cx, cy - d - 1) && cy - d - 1 >= 0) {
      d++;
    }
    return d;
  }

  @override
  void render(Canvas canvas) {
    final s = game.sprites;
    final view = game.camera.visibleWorldRect;
    final x1 = math.max(0, (view.left / kTile).floor() - 1);
    final x2 = math.min(grid.cols - 1, (view.right / kTile).ceil() + 1);
    final y1 = math.max(0, (view.top / kTile).floor() - 1);
    final y2 = math.min(grid.rows - 1, (view.bottom / kTile).ceil() + 1);
    final pos = Vector2.zero();

    for (var cy = y1; cy <= y2; cy++) {
      for (var cx = x1; cx <= x2; cx++) {
        final t = grid.tiles[cy][cx];
        if (t == Tile.empty) continue;
        final px = cx * kTile;
        final py = cy * kTile;
        pos.setValues(px, py);
        switch (t) {
          case Tile.solid:
            final topOpen = grid.at(cx, cy - 1) == Tile.empty;
            if (topOpen) {
              final l = _solid(cx - 1, cy);
              final r = _solid(cx + 1, cy);
              final sprite = l && r
                  ? s.grassMid
                  : l
                      ? s.grassRight
                      : r
                          ? s.grassLeft
                          : s.grassSingle;
              sprite.render(canvas, position: pos, size: _size);
            } else {
              s.dirt[(cx * 7 + cy * 13) % s.dirt.length]
                  .render(canvas, position: pos, size: _size);
              final d = _depthOf(cx, cy);
              if (d > 0) {
                canvas.save();
                canvas.translate(px, py);
                canvas.drawRect(const Rect.fromLTWH(0, 0, kTile, kTile),
                    _depthPaints[d - 1]);
                canvas.restore();
              }
            }
            // contours sur les faces exposées
            if (!_solid(cx - 1, cy) && !topOpen) {
              canvas.drawRect(Rect.fromLTWH(px, py, 1, kTile), _outline);
            }
            if (!_solid(cx + 1, cy) && !topOpen) {
              canvas.drawRect(
                  Rect.fromLTWH(px + kTile - 1, py, 1, kTile), _outline);
            }
            if (!_solid(cx, cy + 1)) {
              canvas.drawRect(
                  Rect.fromLTWH(px, py + kTile - 1, kTile, 1), _outline);
            }
          case Tile.spike:
            s.spike.render(canvas, position: pos, size: _size);
          case Tile.gate:
            s.gate.render(canvas, position: pos, size: _size);
          case Tile.empty:
            break;
        }
      }
    }

    for (final (cx, cy, i) in _decor) {
      if (cx < x1 || cx > x2 || cy < y1 || cy > y2) continue;
      if (grid.at(cx, cy) != Tile.empty) continue;
      pos.setValues(cx * kTile, cy * kTile);
      s.decorations[i].render(canvas, position: pos, size: _size);
    }
  }
}
