abstract interface class SettingsRepository {
  Future<bool> isSoundMuted();
  Future<void> setSoundMuted(bool muted);
}
