import '../entities/level_grid.dart';

abstract interface class LevelRepository {
  /// Retourne une grille neuve à chaque appel (portes intactes).
  LevelGrid loadLevel();
}
