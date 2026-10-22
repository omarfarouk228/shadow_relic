import 'package:shared_preferences/shared_preferences.dart';

/// Stockage brut de la sauvegarde (chaîne JSON) dans les préférences.
class ProgressLocalSource {
  static const _key = 'shadow_relic_save';

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> write(String raw) async =>
      (await SharedPreferences.getInstance()).setString(_key, raw);

  Future<void> delete() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
