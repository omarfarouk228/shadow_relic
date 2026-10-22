import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/entities/ability.dart';
import '../../domain/entities/game_progress.dart';
import '../../domain/entities/level_grid.dart';
import '../../domain/entities/spawn.dart';
import '../../domain/usecases/load_level.dart';
import '../../domain/usecases/progress_usecases.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../audio/game_audio.dart';
import '../components/backdrop.dart';
import '../components/boss.dart';
import '../components/enemy.dart';
import '../components/fx.dart';
import '../components/pickups.dart';
import '../components/player.dart';
import '../components/tile_renderer.dart';
import '../hud/hud.dart';
import '../overlays/overlay_ids.dart';
import '../sprites/game_sprites.dart';
import 'camera_rig.dart';
import 'input_state.dart';
import 'keyboard_controls.dart';

class ShadowRelicGame extends FlameGame with KeyboardEvents {
  ShadowRelicGame({
    required this.loadLevel,
    required this.loadProgress,
    required this.hasSavedProgress,
    required this.saveProgress,
    required this.clearProgress,
    required this.isSoundMuted,
    required this.setSoundMuted,
    required this.audio,
  }) : super(
          camera: CameraComponent.withFixedResolution(
            width: kViewWidth,
            height: kViewHeight,
          ),
        );

  final LoadLevel loadLevel;
  final LoadProgress loadProgress;
  final HasSavedProgress hasSavedProgress;
  final SaveProgress saveProgress;
  final ClearProgress clearProgress;
  final IsSoundMuted isSoundMuted;
  final SetSoundMuted setSoundMuted;
  final GameAudio audio;

  final input = InputState();
  late GameSprites sprites;
  late LevelGrid grid;
  late Player player;
  late Hud hud;
  late CameraRig rig;
  Boss? boss;
  final List<Enemy> enemies = [];

  GameProgress progress = GameProgress();
  Vector2 _startPoint = Vector2.zero();

  /// Faux pendant le menu (mode démo : la caméra survole le niveau).
  bool playing = false;

  /// Une sauvegarde existe : le menu propose « Continuer ».
  final saveAvailable = ValueNotifier<bool>(false);

  double _hitStop = 0;

  Set<Ability> get abilities => progress.abilities;
  int get coins => progress.coins;
  int get totalCoins =>
      grid.spawns.where((s) => s.type == SpawnType.coin).length;
  Vector2 get respawnPoint => progress.respawn ?? _startPoint;

  @override
  Color backgroundColor() => Palette.background;

  @override
  Future<void> onLoad() async {
    sprites = await GameSprites.load(images);
    camera.backdrop = Backdrop();
    hud = Hud();
    camera.viewport.addAll([Vignette(), hud]);
    _buildWorld();
    saveAvailable.value = await hasSavedProgress();
    await audio.load();
    audio.setMuted(await isSoundMuted());
    audio.playMusic(Music.menu);
  }

  void toggleMute() {
    final muted = !audio.muted.value;
    audio.setMuted(muted);
    setSoundMuted(muted);
    if (!muted) audio.play(Sfx.uiConfirm);
  }

  /// Point d'apparition centré dans la cellule, posé au sol.
  static Vector2 standOn(Vector2 cellTopLeft) =>
      Vector2(cellTopLeft.x + (kTile - 14) / 2, cellTopLeft.y + kTile - 16);

  /// Remplace le monde entier : tout ce qui était en jeu (y compris les
  /// composants pas encore montés pendant la pause) part avec l'ancien.
  void _buildWorld() {
    grid = loadLevel();
    enemies.clear();
    boss = null;
    world = World();

    world.add(TileRenderer(grid)..priority = 0);

    for (final s in grid.spawns) {
      final cell = Vector2(s.cx * kTile, s.cy * kTile);
      switch (s.type) {
        case SpawnType.player:
          _startPoint = standOn(cell);
        case SpawnType.checkpoint:
          world.add(Checkpoint(
            cellTopLeft: cell,
            id: s.id,
            activated: progress.activatedCheckpoints.contains(s.id),
          )..priority = 1);
        case SpawnType.coin:
          if (!progress.collectedCoins.contains(s.id)) {
            world.add(Coin(cellTopLeft: cell, id: s.id)..priority = 2);
          }
        case SpawnType.heart:
          world.add(HeartPickup(cellTopLeft: cell)..priority = 2);
        case SpawnType.doubleJumpOrb ||
              SpawnType.dashOrb ||
              SpawnType.wallJumpOrb:
          final ability = s.type.ability!;
          if (!abilities.contains(ability)) {
            world.add(
                AbilityOrb(cellTopLeft: cell, ability: ability)..priority = 2);
          }
        case SpawnType.enemy:
          final e = Enemy(position: Vector2(cell.x + 2, cell.y + kTile - 11))
            ..priority = 3;
          enemies.add(e);
          world.add(e);
        case SpawnType.boss:
          boss = Boss(
            position: Vector2(cell.x, cell.y + kTile - Boss.bossSize),
          )..priority = 3;
          world.add(boss!);
      }
    }

    player = Player(position: respawnPoint.clone())..priority = 4;
    world.add(player);

    rig = CameraRig(
      position: playing
          ? player.position + player.size / 2
          : Vector2(12 * kTile, 20 * kTile),
    );
    world.add(rig);
    camera.follow(rig, snap: true);
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, grid.worldWidth, grid.worldHeight),
      considerViewport: true,
    );
  }

  // ---------- boucle ----------

  @override
  void update(double dt) {
    if (_hitStop > 0) {
      _hitStop -= dt;
      dt = 0; // gel bref de l'action pour donner du poids aux coups
    }
    if (playing) progress.playTime += dt;
    super.update(dt);
  }

  void hitStop(double seconds) {
    if (seconds > _hitStop) _hitStop = seconds;
  }

  void shake(double magnitude, double duration) =>
      rig.shake(magnitude, duration);

  // ---------- cycle de vie ----------

  Future<void> startGame({required bool continueSave}) async {
    if (continueSave) {
      progress = await loadProgress();
    } else {
      await clearProgress();
      progress = GameProgress();
    }
    playing = true;
    hud.clearBanner();
    _buildWorld();
    audio.play(Sfx.uiConfirm);
    audio.playMusic(Music.level);
    overlays.remove(Overlays.menu);
    overlays.remove(Overlays.victory);
    resumeEngine();
  }

  void onVictory() {
    playing = false;
    hud.clearBanner();
    audio.stopMusic();
    audio.play(Sfx.bossDie);
    Future.delayed(const Duration(milliseconds: 700), () {
      audio.play(Sfx.victory);
    });
    saveProgress(progress);
    Future.delayed(const Duration(milliseconds: 1400), () {
      pauseEngine();
      overlays.add(Overlays.victory);
    });
  }

  /// Retour au menu principal, le niveau tourne en fond.
  Future<void> backToMenu() async {
    if (playing) await saveProgress(progress);
    playing = false;
    progress = GameProgress();
    overlays.remove(Overlays.victory);
    overlays.remove(Overlays.pause);
    hud.clearBanner();
    _buildWorld();
    overlays.add(Overlays.menu);
    resumeEngine();
    audio.playMusic(Music.menu);
    saveAvailable.value = await hasSavedProgress();
  }

  /// Efface la sauvegarde et relance une partie neuve.
  Future<void> replay() async {
    await clearProgress();
    saveAvailable.value = false;
    await startGame(continueSave: false);
  }

  void togglePause() {
    if (!playing || overlays.isActive(Overlays.victory)) return;
    if (paused) {
      overlays.remove(Overlays.pause);
      resumeEngine();
      audio.play(Sfx.uiClose);
      audio.resumeMusic();
    } else {
      overlays.add(Overlays.pause);
      pauseEngine();
      audio.play(Sfx.uiOpen);
      audio.pauseMusic();
      saveProgress(progress);
    }
  }

  // ---------- progression ----------

  void collectCoin(int id) {
    progress.collectedCoins.add(id);
    audio.play(Sfx.coin);
    saveProgress(progress);
  }

  void grantAbility(Ability a) {
    abilities.add(a);
    final label = switch (a) {
      Ability.doubleJump => 'DOUBLE SAUT\nAppuie à nouveau sur saut en l\'air',
      Ability.dash => 'DASH\nMaj ou bouton dash : brise les caisses',
      Ability.wallJump => 'SAUT MURAL\nGlisse contre un mur puis saute',
    };
    hud.showBanner(label, color: GameSprites.abilityColor(a));
    audio.play(Sfx.ability);
    saveProgress(progress);
  }

  void activateCheckpoint(int id, Vector2 cellTopLeft) {
    progress.activatedCheckpoints.add(id);
    audio.play(Sfx.checkpoint);
    progress.respawn = standOn(cellTopLeft);
    saveProgress(progress);
  }

  void onPlayerDeath() {
    progress.deaths++;
    audio.play(Sfx.death);
    saveProgress(progress);
  }

  void gateBroken(Vector2 worldPos) {
    shake(2.5, 0.2);
    audio.play(Sfx.crate);
    world.add(ParticleBurst(
      position: worldPos,
      color: Palette.gate,
      count: 16,
    )..priority = 5);
  }

  // ---------- clavier ----------

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final pause = applyKeyboard(input, event, keysPressed);
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyM) {
      toggleMute();
    }
    if (!playing) {
      // menu : Entrée lance l'option principale
      if (event is KeyDownEvent &&
          overlays.isActive(Overlays.menu) &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        startGame(continueSave: saveAvailable.value);
      }
      input.clearQueued();
      return KeyEventResult.handled;
    }
    if (pause) togglePause();
    return KeyEventResult.handled;
  }
}
