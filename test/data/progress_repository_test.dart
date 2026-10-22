import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/data/datasources/progress_local_source.dart';
import 'package:shadow_relic/data/repositories/progress_repository_impl.dart';
import 'package:shadow_relic/domain/entities/ability.dart';
import 'package:shadow_relic/domain/entities/game_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  late LocalProgressRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = LocalProgressRepository(ProgressLocalSource());
  });

  test('aucune sauvegarde -> null', () async {
    expect(await repo.load(), isNull);
  });

  test('aller-retour sauvegarde / chargement', () async {
    await repo.save(GameProgress(
      abilities: {Ability.doubleJump, Ability.dash},
      collectedCoins: {210010, 210011},
      activatedCheckpoints: {250005},
      respawn: Vector2(92, 434),
      deaths: 3,
      playTime: 125.5,
    ));
    final p = (await repo.load())!;
    expect(p.abilities, {Ability.doubleJump, Ability.dash});
    expect(p.collectedCoins, {210010, 210011});
    expect(p.coins, 2);
    expect(p.activatedCheckpoints, {250005});
    expect(p.respawn, Vector2(92, 434));
    expect(p.deaths, 3);
    expect(p.playTime, 125.5);
  });

  test('sans checkpoint, respawn reste null', () async {
    await repo.save(GameProgress(deaths: 2));
    expect((await repo.load())!.respawn, isNull);
  });

  test('sauvegarde corrompue -> null', () async {
    SharedPreferences.setMockInitialValues(
        {'shadow_relic_save': '{"version":2,"abilities":["fly"]}'});
    expect(await repo.load(), isNull);
  });

  test('ancienne sauvegarde (v1, tuiles de 32 px) -> ignorée', () async {
    SharedPreferences.setMockInitialValues({
      'shadow_relic_save':
          '{"abilities":["dash"],"respawn":[160.0,800.0],"coins":4}'
    });
    expect(await repo.load(), isNull);
  });

  test('clear efface la sauvegarde', () async {
    await repo.save(GameProgress(deaths: 1));
    await repo.clear();
    expect(await repo.load(), isNull);
  });
}
