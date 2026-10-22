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
      respawn: Vector2(160, 704),
      coins: 7,
    ));
    final p = (await repo.load())!;
    expect(p.abilities, {Ability.doubleJump, Ability.dash});
    expect(p.respawn, Vector2(160, 704));
    expect(p.coins, 7);
  });

  test('sans checkpoint, respawn reste null', () async {
    await repo.save(GameProgress(coins: 2));
    expect((await repo.load())!.respawn, isNull);
  });

  test('sauvegarde corrompue -> null', () async {
    SharedPreferences.setMockInitialValues(
        {'shadow_relic_save': '{"abilities":["fly"]}'});
    expect(await repo.load(), isNull);
  });

  test('clear efface la sauvegarde', () async {
    await repo.save(GameProgress(coins: 1));
    await repo.clear();
    expect(await repo.load(), isNull);
  });
}
