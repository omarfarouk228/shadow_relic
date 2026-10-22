import '../entities/level_grid.dart';
import '../repositories/level_repository.dart';

class LoadLevel {
  const LoadLevel(this._repository);

  final LevelRepository _repository;

  LevelGrid call() => _repository.loadLevel();
}
