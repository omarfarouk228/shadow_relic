import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/data/datasources/ascii_level_parser.dart';
import 'package:shadow_relic/data/repositories/level_repository_impl.dart';
import 'package:shadow_relic/domain/entities/spawn.dart';
import 'package:shadow_relic/domain/entities/tile.dart';

void main() {
  test('la carte du jeu fait 124x30 et contient tous les éléments clés', () {
    final grid = const AsciiLevelRepository().loadLevel();
    expect(grid.cols, 124);
    expect(grid.rows, 30);

    int count(SpawnType t) => grid.spawns.where((s) => s.type == t).length;
    expect(count(SpawnType.player), 1);
    expect(count(SpawnType.boss), 1);
    expect(count(SpawnType.doubleJumpOrb), 1);
    expect(count(SpawnType.dashOrb), 1);
    expect(count(SpawnType.wallJumpOrb), 1);
    expect(count(SpawnType.checkpoint), greaterThanOrEqualTo(1));
  });

  test('chaque appel retourne une grille neuve', () {
    const repo = AsciiLevelRepository(rows: ['G']);
    repo.loadLevel().clearGate(0, 0);
    expect(repo.loadLevel().at(0, 0), Tile.gate);
  });

  test('les lignes courtes sont complétées par du vide', () {
    final grid = parseAsciiLevel(['XXX', 'X']);
    expect(grid.cols, 3);
    expect(grid.at(2, 1), Tile.empty);
  });

  test('un caractère inconnu est refusé', () {
    expect(() => parseAsciiLevel(['?']), throwsFormatException);
  });
}
