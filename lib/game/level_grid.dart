import 'package:flame/components.dart';
import 'level_data.dart';

const double kTile = 32.0;

enum Tile { empty, solid, spike, gate }

enum Ability { doubleJump, dash, wallJump }

class Spawn {
  final String type;
  final Vector2 pos; // coin bas-gauche de la cellule -> converti par le jeu
  Spawn(this.type, this.pos);
}

class LevelGrid {
  late final int cols;
  late final int rows;
  late final List<List<Tile>> tiles;
  final List<Spawn> spawns = [];

  LevelGrid.parse() {
    rows = levelRows.length;
    cols = levelRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    tiles = List.generate(rows, (_) => List.filled(cols, Tile.empty));
    for (var y = 0; y < rows; y++) {
      final line = levelRows[y].padRight(cols, ' ');
      for (var x = 0; x < cols; x++) {
        final c = line[x];
        switch (c) {
          case 'X':
            tiles[y][x] = Tile.solid;
          case '^':
            tiles[y][x] = Tile.spike;
          case 'G':
            tiles[y][x] = Tile.gate;
          case ' ':
            break;
          default:
            spawns.add(Spawn(c, Vector2(x * kTile, y * kTile)));
        }
      }
    }
  }

  double get worldWidth => cols * kTile;
  double get worldHeight => rows * kTile;

  Tile at(int cx, int cy) {
    if (cx < 0 || cy < 0 || cx >= cols || cy >= rows) return Tile.solid;
    return tiles[cy][cx];
  }

  bool isSolid(int cx, int cy) {
    final t = at(cx, cy);
    return t == Tile.solid || t == Tile.gate;
  }

  void clearGate(int cx, int cy) {
    if (at(cx, cy) == Tile.gate) tiles[cy][cx] = Tile.empty;
  }

  /// Vrai si le rectangle touche au moins une tuile de type [t].
  bool rectTouches(double left, double top, double w, double h, Tile t) {
    final x1 = (left / kTile).floor();
    final x2 = ((left + w - 0.01) / kTile).floor();
    final y1 = (top / kTile).floor();
    final y2 = ((top + h - 0.01) / kTile).floor();
    for (var cy = y1; cy <= y2; cy++) {
      for (var cx = x1; cx <= x2; cx++) {
        if (at(cx, cy) == t) return true;
      }
    }
    return false;
  }
}

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
