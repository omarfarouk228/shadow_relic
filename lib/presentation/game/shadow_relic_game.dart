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
import '../components/boss.dart';
import '../components/enemy.dart';
import '../components/fx.dart';
import '../components/pickups.dart';
import '../components/player.dart';
import '../components/tile_renderer.dart';
import '../hud/hud.dart';
import '../overlays/overlay_ids.dart';
import 'input_state.dart';
import 'keyboard_controls.dart';

class ShadowRelicGame extends FlameGame with KeyboardEvents {
  ShadowRelicGame({
    required this.loadLevel,
    required this.loadProgress,
    required this.saveProgress,
    required this.clearProgress,
  }) : super(
          camera: CameraComponent.withFixedResolution(
            width: kViewWidth,
            height: kViewHeight,
          ),
        );

  final LoadLevel loadLevel;
  final LoadProgress loadProgress;
  final SaveProgress saveProgress;
  final ClearProgress clearProgress;

  final input = InputState();
  late LevelGrid grid;
  late Player player;
  late Hud hud;
  Boss? boss;
  final List<Enemy> enemies = [];

  GameProgress progress = GameProgress();
  Vector2 _startPoint = Vector2.zero();

  Set<Ability> get abilities => progress.abilities;
  int get coins => progress.coins;
  Vector2 get respawnPoint => progress.respawn ?? _startPoint;

  @override
  Color backgroundColor() => Palette.background;

  @override
  Future<void> onLoad() async {
    hud = Hud();
    camera.viewport.add(hud);
    _buildWorld();
    pauseEngine(); // le menu démarre la partie
  }

  /// Remplace le monde entier : tout ce qui était en jeu (y compris les
  /// composants pas encore montés pendant la pause) part avec l'ancien.
  void _buildWorld() {
    grid = loadLevel();
    enemies.clear();
    boss = null;
    world = World();

    world.add(BackgroundStars(grid)..priority = -10);
    world.add(TileRenderer(grid)..priority = 0);

    for (final s in grid.spawns) {
      final cell = Vector2(s.cx * kTile, s.cy * kTile);
      switch (s.type) {
        case SpawnType.player:
          _startPoint = Vector2(cell.x + 5, cell.y + kTile - 28);
        case SpawnType.checkpoint:
          world.add(Checkpoint(cellTopLeft: cell)..priority = 1);
        case SpawnType.coin:
          world.add(Coin(cellTopLeft: cell)..priority = 2);
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
          final e = Enemy(position: Vector2(cell.x, cell.y + kTile - 26))
            ..priority = 3;
          enemies.add(e);
          world.add(e);
        case SpawnType.boss:
          boss = Boss(position: Vector2(cell.x, cell.y + kTile - 56))
            ..priority = 3;
          world.add(boss!);
      }
    }

    player = Player(position: respawnPoint.clone())..priority = 4;
    world.add(player);

    camera.follow(player, maxSpeed: 1200, snap: true);
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, grid.worldWidth, grid.worldHeight),
      considerViewport: true,
    );
  }

  // ---------- cycle de vie ----------

  Future<void> startGame({required bool continueSave}) async {
    if (continueSave) {
      progress = await loadProgress();
    } else {
      await clearProgress();
      progress = GameProgress();
    }
    hud.clearBanner();
    _buildWorld();
    overlays.remove(Overlays.menu);
    resumeEngine();
  }

  void onVictory() {
    Future.delayed(const Duration(milliseconds: 900), () {
      pauseEngine();
      overlays.add(Overlays.victory);
    });
  }

  /// Retour au menu principal.
  void backToMenu() {
    overlays.remove(Overlays.victory);
    overlays.remove(Overlays.pause);
    overlays.add(Overlays.menu);
    pauseEngine();
  }

  Future<void> replay() async {
    await clearProgress();
    backToMenu();
  }

  void togglePause() {
    if (overlays.isActive(Overlays.menu) ||
        overlays.isActive(Overlays.victory)) {
      return;
    }
    if (paused) {
      overlays.remove(Overlays.pause);
      resumeEngine();
    } else {
      overlays.add(Overlays.pause);
      pauseEngine();
    }
  }

  // ---------- progression ----------

  void addCoin() {
    progress.coins++;
    saveProgress(progress);
  }

  void grantAbility(Ability a) {
    abilities.add(a);
    final label = switch (a) {
      Ability.doubleJump => 'DOUBLE SAUT DÉBLOQUÉ\nSaute une 2e fois en l\'air',
      Ability.dash =>
        'DASH DÉBLOQUÉ\nMaj / bouton ⚡ : casse les portes violettes',
      Ability.wallJump => 'WALL JUMP DÉBLOQUÉ\nGlisse sur un mur puis saute',
    };
    hud.showBanner(label);
    saveProgress(progress);
  }

  void setCheckpoint(Vector2 p) {
    progress.respawn = p.clone();
    saveProgress(progress);
  }

  void gateBroken(Vector2 worldPos) {
    world.add(ParticleBurst(
      position: worldPos,
      color: Palette.gate,
      count: 14,
    )..priority = 5);
  }

  // ---------- clavier ----------

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (applyKeyboard(input, event, keysPressed)) togglePause();
    return KeyEventResult.handled;
  }
}
