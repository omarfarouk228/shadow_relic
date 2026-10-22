import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/core/constants.dart';
import 'package:shadow_relic/domain/entities/ability.dart';
import 'package:shadow_relic/domain/entities/game_progress.dart';
import 'package:shadow_relic/domain/entities/tile.dart';
import 'package:shadow_relic/domain/repositories/progress_repository.dart';
import 'package:shadow_relic/injection.dart';
import 'package:shadow_relic/presentation/components/pickups.dart';
import 'package:shadow_relic/presentation/game/shadow_relic_game.dart';
import 'package:shadow_relic/presentation/overlays/overlay_ids.dart';

class InMemoryProgressRepository implements ProgressRepository {
  GameProgress? stored;
  int saves = 0;

  @override
  Future<GameProgress?> load() async => stored;

  @override
  Future<void> save(GameProgress progress) async {
    stored = progress;
    saves++;
  }

  @override
  Future<void> clear() async => stored = null;
}

/// Fait tourner la boucle de jeu comme le ferait le moteur à 60 fps.
Future<void> step(ShadowRelicGame game, double seconds) async {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
    await game.ready();
  }
}

Future<ShadowRelicGame> started(
  InMemoryProgressRepository repo, {
  bool continueSave = false,
}) async {
  final game = await initializeGame(() => createGame(progressRepository: repo));
  // sans GameWidget, les overlays doivent être déclarés à la main
  for (final id in [Overlays.menu, Overlays.pause, Overlays.victory]) {
    game.overlays.addEntry(id, (_, __) => const SizedBox());
  }
  await game.startGame(continueSave: continueSave);
  await game.ready();
  return game;
}

void main() {
  late InMemoryProgressRepository repo;
  setUp(() => repo = InMemoryProgressRepository());

  test('le jeu démarre en pause sur le menu', () async {
    final game =
        await initializeGame(() => createGame(progressRepository: repo));
    expect(game.paused, isTrue);
    expect(game.player, isNotNull);
  });

  test('nouvelle partie : le joueur tombe et se pose au sol', () async {
    final game = await started(repo);
    expect(game.paused, isFalse);
    expect(game.overlays.isActive(Overlays.menu), isFalse);
    await step(game, 1);
    expect(game.player.onGround, isTrue);
    expect(game.player.hp, game.player.maxHp);
  });

  test('le joueur avance vers la droite au clavier', () async {
    final game = await started(repo);
    await step(game, 0.5);
    final x0 = game.player.x;
    game.input.kbRight = true;
    await step(game, 0.5);
    expect(game.player.x, greaterThan(x0 + 50));
  });

  test('ramasser l\'orbe de double saut débloque et sauvegarde', () async {
    final game = await started(repo);
    final orb = game.world.children
        .whereType<AbilityOrb>()
        .firstWhere((o) => o.ability == Ability.doubleJump);
    game.player.position.setFrom(orb.position);
    await step(game, 0.1);
    expect(game.abilities, contains(Ability.doubleJump));
    expect(repo.stored!.abilities, contains(Ability.doubleJump));
    expect(orb.isMounted, isFalse);
  });

  test('continuer : capacités et checkpoint restaurés, orbes retirées',
      () async {
    repo.stored = GameProgress(
      abilities: {Ability.doubleJump, Ability.dash},
      respawn: Vector2(86 * kTile + 5, 21 * kTile + 4),
      coins: 3,
    );
    final game = await started(repo, continueSave: true);
    final orbs = game.world.children.whereType<AbilityOrb>().toList();
    expect(orbs.map((o) => o.ability), [Ability.wallJump]);
    expect(game.player.position, Vector2(86 * kTile + 5, 21 * kTile + 4));
    expect(game.coins, 3);
  });

  test('sans dash, la porte violette bloque le passage', () async {
    final game = await started(repo);
    game.player.position.setValues(77 * kTile, 21 * kTile + 3);
    game.input.kbRight = true;
    await step(game, 1);
    expect(game.player.x + game.player.width, lessThanOrEqualTo(80 * kTile));
    expect(game.grid.at(80, 21), Tile.gate);
  });

  test('le dash casse la porte violette', () async {
    repo.stored = GameProgress(abilities: {Ability.doubleJump, Ability.dash});
    final game = await started(repo, continueSave: true);
    game.player.position.setValues(78 * kTile, 21 * kTile + 3);
    await step(game, 0.3);
    game.input.kbRight = true;
    game.input.dashQueued = true;
    await step(game, 0.3);
    expect(game.grid.at(80, 21), Tile.empty);
    expect(game.player.x, greaterThan(80 * kTile));
  });

  test('les pics retirent un cœur et renvoient au point de départ', () async {
    final game = await started(repo);
    final start = game.respawnPoint.clone();
    game.player.position.setValues(18 * kTile + 5, 25 * kTile);
    await step(game, 1);
    expect(game.player.hp, game.player.maxHp - 1);
    expect(game.player.position.x, closeTo(start.x, 40));
  });

  test('vaincre le Gardien déclenche l\'écran de victoire', () async {
    final game = await started(repo);
    final boss = game.boss!;
    boss.active = true;
    while (!boss.dead) {
      boss.takeHit(1);
      await step(game, 0.3);
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(game.overlays.isActive(Overlays.victory), isTrue);
    expect(game.paused, isTrue);

    await game.replay();
    expect(game.overlays.isActive(Overlays.menu), isTrue);
    expect(repo.stored, isNull);
  });
}
