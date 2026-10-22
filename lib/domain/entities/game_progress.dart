import 'package:vector_math/vector_math.dart';

import 'ability.dart';

/// État persistant d'une partie.
class GameProgress {
  GameProgress({
    Set<Ability>? abilities,
    this.respawn,
    this.coins = 0,
  }) : abilities = abilities ?? {};

  final Set<Ability> abilities;

  /// Dernier checkpoint atteint, null tant qu'on est au départ.
  Vector2? respawn;
  int coins;
}
