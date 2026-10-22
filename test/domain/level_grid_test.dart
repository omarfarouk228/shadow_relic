import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/core/constants.dart';
import 'package:shadow_relic/data/datasources/ascii_level_parser.dart';
import 'package:shadow_relic/domain/entities/tile.dart';
import 'package:shadow_relic/domain/physics/collision.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  // 0123
  final grid = parseAsciiLevel([
    'X  X',
    'X GX',
    'XX^X',
  ]);

  group('LevelGrid', () {
    test('hors limites = solide', () {
      expect(grid.at(-1, 0), Tile.solid);
      expect(grid.at(0, 99), Tile.solid);
    });

    test('une porte est solide jusqu\'à ce qu\'on la casse', () {
      expect(grid.isSolid(2, 1), isTrue);
      grid.clearGate(2, 1);
      expect(grid.at(2, 1), Tile.empty);
      grid.clearGate(0, 0); // ne touche pas aux murs
      expect(grid.at(0, 0), Tile.solid);
    });

    test('rectTouches détecte les pics', () {
      expect(
          grid.rectTouches(2 * kTile, 2 * kTile, 10, 10, Tile.spike), isTrue);
      expect(grid.rectTouches(1 * kTile, 0, 10, 10, Tile.spike), isFalse);
    });
  });

  group('moveAndCollide', () {
    test('la chute s\'arrête sur le sol', () {
      final g = parseAsciiLevel(['    ', '    ', 'XXXX']);
      // un pas de déplacement reste inférieur à une tuile (comme à 60 fps)
      final pos = Vector2(4, 2 * kTile - 16 - 5);
      final vel = Vector2(0, 6 * kTile);
      final hit = moveAndCollide(g, pos, Vector2(12, 16), vel, 0.1);
      expect(hit.down, isTrue);
      expect(vel.y, 0);
      expect(pos.y + 16, closeTo(2 * kTile, 0.1));
    });

    test('un mur bloque horizontalement', () {
      final g = parseAsciiLevel(['   X']);
      final pos = Vector2(3 * kTile - 12 - 4, 0);
      final vel = Vector2(6 * kTile, 0);
      final hit = moveAndCollide(g, pos, Vector2(12, 12), vel, 0.1);
      expect(hit.right, isTrue);
      expect(pos.x + 12, lessThanOrEqualTo(3 * kTile));
    });

    test('onGateHit peut laisser passer une porte', () {
      final g = parseAsciiLevel(['  G ']);
      final pos = Vector2(2 * kTile - 12 - 4, 0);
      final vel = Vector2(6 * kTile, 0);
      final hit = moveAndCollide(g, pos, Vector2(12, 12), vel, 0.1,
          onGateHit: (cx, cy) {
        g.clearGate(cx, cy);
        return true;
      });
      expect(hit.right, isFalse);
      expect(g.at(2, 0), Tile.empty);
    });
  });
}
