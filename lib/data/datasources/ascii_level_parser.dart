import '../../domain/entities/level_grid.dart';
import '../../domain/entities/spawn.dart';
import '../../domain/entities/tile.dart';

/// Convertit une carte ASCII en [LevelGrid].
/// Les lignes plus courtes sont complétées par du vide.
LevelGrid parseAsciiLevel(List<String> rows) {
  final cols = rows.map((r) => r.length).fold(0, (a, b) => a > b ? a : b);
  final tiles =
      List.generate(rows.length, (_) => List.filled(cols, Tile.empty));
  final spawns = <Spawn>[];

  for (var y = 0; y < rows.length; y++) {
    final line = rows[y].padRight(cols, ' ');
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
          final type = _spawnTypes[c];
          if (type == null) {
            throw FormatException('Caractère inconnu "$c" en ($x, $y)');
          }
          spawns.add(Spawn(type, x, y));
      }
    }
  }
  return LevelGrid(tiles: tiles, spawns: spawns);
}

const _spawnTypes = {
  'P': SpawnType.player,
  'C': SpawnType.checkpoint,
  'o': SpawnType.coin,
  'h': SpawnType.heart,
  'J': SpawnType.doubleJumpOrb,
  'H': SpawnType.dashOrb,
  'W': SpawnType.wallJumpOrb,
  'e': SpawnType.enemy,
  'B': SpawnType.boss,
};
