import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  static const _mutedKey = 'shadow_relic_muted';

  @override
  Future<bool> isSoundMuted() async =>
      (await SharedPreferences.getInstance()).getBool(_mutedKey) ?? false;

  @override
  Future<void> setSoundMuted(bool muted) async =>
      (await SharedPreferences.getInstance()).setBool(_mutedKey, muted);
}
