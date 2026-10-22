import '../entities/game_progress.dart';

abstract interface class ProgressRepository {
  /// Null si aucune sauvegarde valide n'existe.
  Future<GameProgress?> load();
  Future<void> save(GameProgress progress);
  Future<void> clear();
}
