import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/boss.dart';
import '../components/enemy.dart';
import '../components/fx.dart';
import '../components/pickups.dart';
import '../components/player.dart';
import '../components/tile_renderer.dart';
import '../ui/hud.dart';
import 'input_state.dart';
import 'level_grid.dart';

class MvGame extends FlameGame with KeyboardEvents {
  MvGame()
      : super(
          camera: CameraComponent.withFixedResolution(width: 640, height: 360),
        );

  final input = InputState();
  late LevelGrid grid;
  late Player player;
  Boss? boss;
  final List<Enemy> enemies = [];

  final Set<Ability> abilities = {};
  int coins = 0;
  Vector2 respawnPoint = Vector2.zero();
  late Hud hud;

  static const _saveKey = 'shadow_relic_save';

  @override
  Color backgroundColor() => const Color(0xFF0C0E1A);

  @override
  Future<void> onLoad() async {
    await _buildWorld();
    pauseEngine(); // le menu démarre la partie
  }

  Future<void> _buildWorld() async {
    grid = LevelGrid.parse();

    world.add(BackgroundStars(grid)..priority = -10);
    world.add(TileRenderer(grid)..priority = 0);

    for (final s in grid.spawns) {
      // s.pos = coin haut-gauche de la cellule marquée
      switch (s.type) {
        case 'P':
          respawnPoint = Vector2(s.pos.x + 5, s.pos.y + kTile - 28);
          player = Player(position: respawnPoint.clone())..priority = 4;
          world.add(player);
        case 'C':
          world.add(Checkpoint(cellTopLeft: s.pos)..priority = 1);
        case 'o':
          world.add(Coin(cellTopLeft: s.pos)..priority = 2);
        case 'h':
          world.add(HeartPickup(cellTopLeft: s.pos)..priority = 2);
        case 'J':
          world.add(AbilityOrb(cellTopLeft: s.pos, ability: Ability.doubleJump)
            ..priority = 2);
        case 'H':
          world.add(
              AbilityOrb(cellTopLeft: s.pos, ability: Ability.dash)..priority = 2);
        case 'W':
          world.add(AbilityOrb(cellTopLeft: s.pos, ability: Ability.wallJump)
            ..priority = 2);
        case 'e':
          final e = Enemy(position: Vector2(s.pos.x, s.pos.y + kTile - 26))
            ..priority = 3;
          enemies.add(e);
          world.add(e);
        case 'B':
          boss = Boss(position: Vector2(s.pos.x, s.pos.y + kTile - 56))
            ..priority = 3;
          world.add(boss!);
      }
    }

    hud = Hud();
    camera.viewport.add(hud);

    camera.follow(player, maxSpeed: 1200, snap: true);
    camera.setBounds(
      Rectangle.fromLTRB(0, 0, grid.worldWidth, grid.worldHeight),
      considerViewport: true,
    );
  }

  // ---------- cycle de vie ----------

  Future<void> startGame({required bool continueSave}) async {
    if (continueSave) {
      await _loadSave();
    } else {
      await clearSave();
    }
    overlays.remove('menu');
    resumeEngine();
  }

  void onVictory() {
    Future.delayed(const Duration(milliseconds: 900), () {
      pauseEngine();
      overlays.add('victory');
    });
  }

  Future<void> restart() async {
    overlays.remove('victory');
    overlays.remove('pause');
    // reconstruit tout le monde proprement
    enemies.clear();
    boss = null;
    abilities.clear();
    coins = 0;
    world.removeAll(world.children.toList());
    camera.viewport.remove(hud);
    await _buildWorld();
    overlays.add('menu');
    pauseEngine();
  }

  void togglePause() {
    if (overlays.isActive('menu') || overlays.isActive('victory')) return;
    if (paused) {
      overlays.remove('pause');
      resumeEngine();
    } else {
      overlays.add('pause');
      pauseEngine();
    }
  }

  // ---------- progression ----------

  void addCoin() {
    coins++;
    save();
  }

  void grantAbility(Ability a) {
    abilities.add(a);
    final label = switch (a) {
      Ability.doubleJump => 'DOUBLE SAUT DÉBLOQUÉ\nSaute une 2e fois en l\'air',
      Ability.dash => 'DASH DÉBLOQUÉ\nMaj / bouton ⚡ — casse les portes violettes',
      Ability.wallJump => 'WALL JUMP DÉBLOQUÉ\nGlisse sur un mur puis saute',
    };
    hud.showBanner(label);
    save();
  }

  void setCheckpoint(Vector2 p) {
    respawnPoint = p.clone();
    save();
  }

  void gateBroken(Vector2 worldPos) {
    world.add(ParticleBurst(
      position: worldPos,
      color: const Color(0xFF8E5CFF),
      count: 14,
    )..priority = 5);
  }

  // ---------- sauvegarde ----------

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _saveKey,
      jsonEncode({
        'abilities': abilities.map((a) => a.name).toList(),
        'respawn': [respawnPoint.x, respawnPoint.y],
        'coins': coins,
      }),
    );
  }

  Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  Future<void> _loadSave() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final n in (data['abilities'] as List)) {
        abilities.add(Ability.values.byName(n as String));
      }
      final r = data['respawn'] as List;
      respawnPoint = Vector2(
        (r[0] as num).toDouble(),
        (r[1] as num).toDouble(),
      );
      coins = (data['coins'] as num?)?.toInt() ?? 0;
      player.position.setFrom(respawnPoint);
      // retire les orbes déjà collectées
      for (final orb in world.children.whereType<AbilityOrb>().toList()) {
        if (abilities.contains(orb.ability)) orb.removeFromParent();
      }
    } catch (_) {
      // sauvegarde corrompue -> on ignore
    }
  }

  // ---------- clavier ----------

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool any(List<LogicalKeyboardKey> keys) =>
        keys.any(keysPressed.contains);

    input.kbLeft = any([
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyQ, // AZERTY
    ]);
    input.kbRight =
        any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]);
    input.kbJumpHeld = any([
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyZ, // AZERTY
    ]);

    if (event is KeyDownEvent) {
      final k = event.logicalKey;
      if (k == LogicalKeyboardKey.space ||
          k == LogicalKeyboardKey.arrowUp ||
          k == LogicalKeyboardKey.keyW ||
          k == LogicalKeyboardKey.keyZ) {
        input.jumpQueued = true;
      }
      if (k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight ||
          k == LogicalKeyboardKey.keyC) {
        input.dashQueued = true;
      }
      if (k == LogicalKeyboardKey.keyX || k == LogicalKeyboardKey.keyJ) {
        input.attackQueued = true;
      }
      if (k == LogicalKeyboardKey.escape) {
        togglePause();
      }
    }
    return KeyEventResult.handled;
  }
}
