import '../repositories/settings_repository.dart';

class IsSoundMuted {
  const IsSoundMuted(this._repository);

  final SettingsRepository _repository;

  Future<bool> call() => _repository.isSoundMuted();
}

class SetSoundMuted {
  const SetSoundMuted(this._repository);

  final SettingsRepository _repository;

  Future<void> call(bool muted) => _repository.setSoundMuted(muted);
}
