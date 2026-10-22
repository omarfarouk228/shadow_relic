import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le son est actif par défaut et le réglage est conservé', () async {
    final repo = LocalSettingsRepository();
    expect(await repo.isSoundMuted(), isFalse);
    await repo.setSoundMuted(true);
    expect(await LocalSettingsRepository().isSoundMuted(), isTrue);
  });
}
