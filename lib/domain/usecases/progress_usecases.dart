import '../entities/game_progress.dart';
import '../repositories/progress_repository.dart';

class LoadProgress {
  const LoadProgress(this._repository);

  final ProgressRepository _repository;

  /// Repart d'une progression vide si rien n'est sauvegardé.
  Future<GameProgress> call() async =>
      await _repository.load() ?? GameProgress();
}

class HasSavedProgress {
  const HasSavedProgress(this._repository);

  final ProgressRepository _repository;

  Future<bool> call() async => await _repository.load() != null;
}

class SaveProgress {
  const SaveProgress(this._repository);

  final ProgressRepository _repository;

  Future<void> call(GameProgress progress) => _repository.save(progress);
}

class ClearProgress {
  const ClearProgress(this._repository);

  final ProgressRepository _repository;

  Future<void> call() => _repository.clear();
}
