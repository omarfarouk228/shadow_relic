import 'package:vector_math/vector_math.dart';

import 'ability.dart';

/// État persistant d'une partie.
class GameProgress {
  GameProgress({
    Set<Ability>? abilities,
    Set<int>? collectedCoins,
    Set<int>? activatedCheckpoints,
    this.respawn,
    this.deaths = 0,
    this.playTime = 0,
  })  : abilities = abilities ?? {},
        collectedCoins = collectedCoins ?? {},
        activatedCheckpoints = activatedCheckpoints ?? {};

  final Set<Ability> abilities;

  /// Identifiants ([Spawn.id]) des pièces déjà ramassées.
  final Set<int> collectedCoins;

  /// Identifiants ([Spawn.id]) des checkpoints déjà allumés.
  final Set<int> activatedCheckpoints;

  /// Dernier checkpoint atteint, null tant qu'on est au départ.
  Vector2? respawn;
  int deaths;

  /// Temps de jeu cumulé, en secondes.
  double playTime;

  int get coins => collectedCoins.length;
}
