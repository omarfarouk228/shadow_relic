import 'data/datasources/progress_local_source.dart';
import 'data/repositories/level_repository_impl.dart';
import 'data/repositories/progress_repository_impl.dart';
import 'domain/repositories/level_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'domain/usecases/load_level.dart';
import 'domain/usecases/progress_usecases.dart';
import 'presentation/game/shadow_relic_game.dart';

/// Assemble les couches : data -> domain -> presentation.
ShadowRelicGame createGame({
  LevelRepository levelRepository = const AsciiLevelRepository(),
  ProgressRepository? progressRepository,
}) {
  final progress =
      progressRepository ?? LocalProgressRepository(ProgressLocalSource());
  return ShadowRelicGame(
    loadLevel: LoadLevel(levelRepository),
    loadProgress: LoadProgress(progress),
    hasSavedProgress: HasSavedProgress(progress),
    saveProgress: SaveProgress(progress),
    clearProgress: ClearProgress(progress),
  );
}
