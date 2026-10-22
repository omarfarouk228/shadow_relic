import '../../core/constants.dart';
import 'spawn.dart';
import 'tile.dart';

/// Grille de tuiles du niveau. Mutable : les portes se cassent au dash.
class LevelGrid {
  LevelGrid({required this.tiles, required this.spawns})
      : rows = tiles.length,
        cols = tiles.isEmpty ? 0 : tiles.first.length;

  final int cols;
  final int rows;
  final List<List<Tile>> tiles;
  final List<Spawn> spawns;

  double get worldWidth => cols * kTile;
  double get worldHeight => rows * kTile;

  /// Hors de la grille, tout est considéré solide.
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
