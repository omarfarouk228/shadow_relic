import 'package:vector_math/vector_math.dart';

import '../../core/constants.dart';
import '../entities/level_grid.dart';
import '../entities/tile.dart';

class HitInfo {
  bool left = false, right = false, up = false, down = false;
}

/// Déplace [pos] (coin haut-gauche, taille [size]) selon [vel]*dt en
/// résolvant les collisions avec la grille. Axe X puis axe Y.
/// [onGateHit] permet au dash du joueur de casser les portes.
HitInfo moveAndCollide(
  LevelGrid grid,
  Vector2 pos,
  Vector2 size,
  Vector2 vel,
  double dt, {
  bool Function(int cx, int cy)? onGateHit,
}) {
  final hit = HitInfo();
  const eps = 0.01;

  bool blocked(int cx, int cy) {
    final t = grid.at(cx, cy);
    if (t == Tile.gate && onGateHit != null && onGateHit(cx, cy)) {
      return false; // porte cassée pendant un dash
    }
    return t == Tile.solid || t == Tile.gate;
  }

  // --- axe X ---
  pos.x += vel.x * dt;
  if (vel.x != 0) {
    final y1 = (pos.y / kTile).floor();
    final y2 = ((pos.y + size.y - eps) / kTile).floor();
    if (vel.x > 0) {
      final cx = ((pos.x + size.x) / kTile).floor();
      for (var cy = y1; cy <= y2; cy++) {
        if (blocked(cx, cy)) {
          pos.x = cx * kTile - size.x - eps;
          vel.x = 0;
          hit.right = true;
          break;
        }
      }
    } else {
      final cx = (pos.x / kTile).floor();
      for (var cy = y1; cy <= y2; cy++) {
        if (blocked(cx, cy)) {
          pos.x = (cx + 1) * kTile + eps;
          vel.x = 0;
          hit.left = true;
          break;
        }
      }
    }
  }

  // --- axe Y ---
  pos.y += vel.y * dt;
  if (vel.y != 0) {
    final x1 = (pos.x / kTile).floor();
    final x2 = ((pos.x + size.x - eps) / kTile).floor();
    if (vel.y > 0) {
      final cy = ((pos.y + size.y) / kTile).floor();
      for (var cx = x1; cx <= x2; cx++) {
        if (blocked(cx, cy)) {
          pos.y = cy * kTile - size.y - eps;
          vel.y = 0;
          hit.down = true;
          break;
        }
      }
    } else {
      final cy = (pos.y / kTile).floor();
      for (var cx = x1; cx <= x2; cx++) {
        if (blocked(cx, cy)) {
          pos.y = (cy + 1) * kTile + eps;
          vel.y = 0;
          hit.up = true;
          break;
        }
      }
    }
  }
  return hit;
}
