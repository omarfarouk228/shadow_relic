import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_relic/core/constants.dart';
import 'package:shadow_relic/domain/entities/ability.dart';
import 'package:shadow_relic/domain/entities/game_progress.dart';
import 'package:shadow_relic/domain/entities/hero_class.dart';
import 'package:shadow_relic/domain/entities/spawn.dart';
import 'package:shadow_relic/domain/entities/tile.dart';
import 'package:shadow_relic/domain/repositories/progress_repository.dart';
import 'package:shadow_relic/domain/repositories/settings_repository.dart';
import 'package:shadow_relic/injection.dart';
import 'package:shadow_relic/presentation/audio/game_audio.dart';
import 'package:shadow_relic/presentation/components/pickups.dart';
import 'package:shadow_relic/presentation/game/shadow_relic_game.dart';
import 'package:shadow_relic/presentation/overlays/overlay_ids.dart';

class InMemoryProgressRepository implements ProgressRepository {
  GameProgress? stored;

  @override
  Future<GameProgress?> load() async => stored;

  @override
  Future<void> save(GameProgress progress) async => stored = progress;

  @override
  Future<void> clear() async => stored = null;
}

class InMemorySettingsRepository implements SettingsRepository {
  bool muted = false;

  @override
  Future<bool> isSoundMuted() async => muted;

  @override
  Future<void> setSoundMuted(bool value) async => muted = value;
}

/// Fait tourner la boucle de jeu comme le ferait le moteur à 60 fps.
Future<void> step(ShadowRelicGame game, double seconds) async {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    game.update(1 / 60);
    await game.ready();
  }
}

Future<ShadowRelicGame> loaded(InMemoryProgressRepository repo) async {
  final game = await initializeGame(() => createGame(
        progressRepository: repo,
        settingsRepository: InMemorySettingsRepository(),
        audio: SilentGameAudio(),
      ));
  // sans GameWidget, les overlays doivent être déclarés à la main
  for (final id in [
    Overlays.menu,
    Overlays.heroSelect,
    Overlays.pause,
    Overlays.victory,
  ]) {
    game.overlays.addEntry(id, (_, __) => const SizedBox());
  }
  return game;
}

Future<ShadowRelicGame> started(
  InMemoryProgressRepository repo, {
  bool continueSave = false,
}) async {
  final game = await loaded(repo);
  await game.startGame(continueSave: continueSave);
  await game.ready();
  return game;
}

/// Place le joueur debout dans la cellule ([cx], [cy]).
void standAt(ShadowRelicGame game, int cx, int cy) => game.player.position
    .setFrom(ShadowRelicGame.standOn(Vector2(cx * kTile, cy * kTile)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InMemoryProgressRepository repo;
  setUp(() => repo = InMemoryProgressRepository());

  test('au lancement : mode démo derrière le menu, sans sauvegarde', () async {
    final game = await loaded(repo);
    expect(game.playing, isFalse);
    expect(game.saveAvailable.value, isFalse);
    final x0 = game.player.x;
    await step(game, 1);
    expect(game.player.x, x0, reason: 'le joueur ne bouge pas en démo');
  });

  test('nouvelle partie : le joueur tombe et se pose au sol', () async {
    final game = await started(repo);
    expect(game.playing, isTrue);
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
    expect(game.player.x, greaterThan(x0 + 2 * kTile));
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

  test('une pièce ramassée ne réapparaît pas après « Continuer »', () async {
    var game = await started(repo);
    final coin = game.world.children.whereType<Coin>().first;
    game.player.position.setFrom(coin.position);
    await step(game, 0.1);
    expect(game.coins, 1);

    game = await started(repo, continueSave: true);
    expect(game.coins, 1);
    expect(game.world.children.whereType<Coin>().map((c) => c.id),
        isNot(contains(coin.id)));
    expect(game.world.children.whereType<Coin>().length, game.totalCoins - 1);
  });

  test('continuer : capacités, checkpoint et drapeau restaurés', () async {
    final cp = (await started(repo))
        .grid
        .spawns
        .lastWhere((s) => s.type == SpawnType.checkpoint && s.cy == 21);
    final respawn =
        ShadowRelicGame.standOn(Vector2(cp.cx * kTile, cp.cy * kTile));
    repo.stored = GameProgress(
      abilities: {Ability.doubleJump, Ability.dash},
      activatedCheckpoints: {cp.id},
      respawn: respawn,
    );
    final game = await started(repo, continueSave: true);
    final orbs = game.world.children.whereType<AbilityOrb>().toList();
    expect(orbs.map((o) => o.ability), [Ability.wallJump]);
    expect(game.player.position, respawn);
    final flag = game.world.children
        .whereType<Checkpoint>()
        .firstWhere((c) => c.id == cp.id);
    expect(flag.activated, isTrue);
  });

  test('toucher un checkpoint l\'allume et le sauvegarde', () async {
    final game = await started(repo);
    final flag = game.world.children.whereType<Checkpoint>().first;
    game.player.position.setFrom(flag.position);
    await step(game, 0.1);
    expect(flag.activated, isTrue);
    expect(repo.stored!.activatedCheckpoints, contains(flag.id));
    expect(repo.stored!.respawn, isNotNull);
  });

  test('sans dash, la caisse bloque le passage', () async {
    final game = await started(repo);
    standAt(game, 78, 21);
    game.input.kbRight = true;
    await step(game, 1);
    expect(game.player.x + game.player.width, lessThanOrEqualTo(80 * kTile));
    expect(game.grid.at(80, 21), Tile.gate);
  });

  test('le dash brise la caisse', () async {
    repo.stored = GameProgress(abilities: {Ability.doubleJump, Ability.dash});
    final game = await started(repo, continueSave: true);
    standAt(game, 78, 21);
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
    game.player.position.setValues(18 * kTile + 2, 25 * kTile);
    await step(game, 1);
    expect(game.player.hp, game.player.maxHp - 1);
    expect(game.player.position.x, closeTo(start.x, 2 * kTile));
  });

  test('mourir compte une mort et rend toute la vie', () async {
    final game = await started(repo);
    game.player.hp = 1;
    game.player.takeDamage(from: game.player.position + Vector2(10, 0));
    expect(game.player.hp, game.player.maxHp);
    expect(game.progress.deaths, 1);
    expect(repo.stored!.deaths, 1);
  });

  test('vaincre le Gardien déclenche l\'écran de victoire', () async {
    final game = await started(repo);
    final boss = game.boss!;
    boss.active = true;
    while (!boss.dead) {
      boss.takeHit(1);
      await step(game, 0.3);
    }
    expect(game.playing, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(game.overlays.isActive(Overlays.victory), isTrue);
    expect(game.paused, isTrue);

    await game.replay();
    expect(game.overlays.isActive(Overlays.victory), isFalse);
    expect(game.playing, isTrue);
    expect(game.coins, 0);
  });

  test('menu : Entrée ouvre le choix du héros, flèches puis Entrée lancent',
      () async {
    final game = await loaded(repo);
    game.overlays.add(Overlays.menu);
    void press(LogicalKeyboardKey k) => game.onKeyEvent(
        KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: k,
            timeStamp: Duration.zero),
        {k});

    press(LogicalKeyboardKey.enter);
    expect(game.overlays.isActive(Overlays.heroSelect), isTrue);
    press(LogicalKeyboardKey.arrowRight);
    press(LogicalKeyboardKey.arrowRight);
    expect(game.selectedHero.value, HeroClass.ninja);
    press(LogicalKeyboardKey.arrowRight);
    expect(game.selectedHero.value, HeroClass.knight, reason: 'boucle');
    press(LogicalKeyboardKey.arrowLeft);
    expect(game.selectedHero.value, HeroClass.ninja);
    press(LogicalKeyboardKey.enter);
    await Future<void>.delayed(Duration.zero);
    await game.ready();
    expect(game.playing, isTrue);
    expect(game.player.hero, HeroClass.ninja);
    expect(repo.stored, isNull,
        reason: 'rien à sauver tant qu\'on n\'a rien fait');
  });

  test('chaque héros applique ses caractéristiques et est sauvegardé',
      () async {
    final game = await loaded(repo);
    await game.startGame(continueSave: false, hero: HeroClass.ninja);
    await game.ready();
    expect(game.player.maxHp, HeroClass.ninja.maxHp);
    expect(game.player.hp, 4);
    await step(game, 0.5);
    final x0 = game.player.x;
    game.input.kbRight = true;
    await step(game, 0.5);
    final ninjaRun = game.player.x - x0;

    final knight = await started(repo);
    expect(knight.player.maxHp, 6);
    await step(knight, 0.5);
    final k0 = knight.player.x;
    knight.input.kbRight = true;
    await step(knight, 0.5);
    expect(ninjaRun, greaterThan(knight.player.x - k0));

    // le héros suit la sauvegarde
    repo.stored = GameProgress(hero: HeroClass.samurai);
    final resumed = await started(repo, continueSave: true);
    expect(resumed.player.hero, HeroClass.samurai);
    expect(resumed.selectedHero.value, HeroClass.samurai);
  });

  test('la touche M coupe et rétablit le son', () async {
    final game = await started(repo);
    expect(game.audio.muted.value, isFalse);
    game.toggleMute();
    expect(game.audio.muted.value, isTrue);
    game.toggleMute();
    expect(game.audio.muted.value, isFalse);
  });

  test('pause puis retour au menu : partie sauvegardée', () async {
    final game = await started(repo);
    await step(game, 0.5);
    game.togglePause();
    expect(game.paused, isTrue);
    expect(game.overlays.isActive(Overlays.pause), isTrue);
    await game.backToMenu();
    expect(game.playing, isFalse);
    expect(game.overlays.isActive(Overlays.menu), isTrue);
    expect(game.saveAvailable.value, isTrue);
    expect(repo.stored!.playTime, greaterThan(0));
  });
}
