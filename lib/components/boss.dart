import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/level_grid.dart';
import '../game/mv_game.dart';
import 'fx.dart';

class Boss extends PositionComponent with HasGameReference<MvGame> {
  Boss({required Vector2 position})
      : _spawn = position.clone(),
        super(position: position, size: Vector2(52, 56));

  final Vector2 _spawn;
  static const maxHp = 24;
  static const gravity = 1500.0;
  static const arenaLeftLimit = 106 * kTile;

  int hp = maxHp;
  bool active = false;
  bool dead = false;
  final vel = Vector2.zero();
  double _hopTimer = 1.2;
  double _flash = 0;
  double _iframes = 0;
  double _t = 0;
  bool _inAir = false;
  final List<Shockwave> shockwaves = [];

  double get hpRatio => hp / maxHp;

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0.05) dt = 0.05;
    _t += dt;
    _flash = math.max(0, _flash - dt);
    _iframes = math.max(0, _iframes - dt);
    if (dead) return;

    final player = game.player;

    // activation quand le joueur entre dans l'arène
    if (!active) {
      if (player.position.y < 9 * kTile &&
          (player.position.x - position.x).abs() < 9 * kTile) {
        active = true;
        game.hud.showBanner('LE GARDIEN DE LA RELIQUE');
      }
      return;
    }

    // phase 2 : plus rapide sous 50% de vie
    final enraged = hp <= maxHp / 2;
    final hopEvery = enraged ? 1.1 : 1.8;

    if (!_inAir) {
      vel.x = 0;
      _hopTimer -= dt;
      if (_hopTimer <= 0) {
        _hopTimer = hopEvery;
        final dir = player.position.x > position.x ? 1 : -1;
        vel.x = dir * (enraged ? 190.0 : 140.0);
        vel.y = -540;
        _inAir = true;
      }
    }
    vel.y = math.min(vel.y + gravity * dt, 600);

    final hit = moveAndCollide(game.grid, position, size, vel, dt);
    position.x = position.x.clamp(arenaLeftLimit, game.grid.worldWidth - 80);

    if (hit.down && _inAir) {
      _inAir = false;
      vel.x = 0;
      _spawnShockwaves(enraged);
      game.world.add(ParticleBurst(
        position: position + Vector2(width / 2, height),
        color: const Color(0xFFFF8C42),
        count: 12,
      )..priority = 5);
    }
  }

  void _spawnShockwaves(bool enraged) {
    final y = position.y + height - 14;
    for (final d in [-1, 1]) {
      final s = Shockwave(
        position: Vector2(position.x + width / 2 + d * 30, y),
        dir: d,
        speed: enraged ? 230 : 175,
      )..priority = 3;
      shockwaves.add(s);
      game.world.add(s);
    }
  }

  void takeHit(int dmg) {
    if (dead || !active || _iframes > 0) return;
    hp -= dmg;
    _flash = 0.12;
    _iframes = 0.25;
    if (hp <= 0) {
      dead = true;
      active = false;
      game.world.add(ParticleBurst(
        position: position + size / 2,
        color: const Color(0xFFFFD166),
        count: 30,
        speed: 220,
      )..priority = 5);
      for (final s in shockwaves) {
        s.removeFromParent();
      }
      shockwaves.clear();
      removeFromParent();
      game.onVictory();
    }
  }

  void resetFight() {
    if (dead) return;
    hp = maxHp;
    active = false;
    _inAir = false;
    vel.setZero();
    position.setFrom(_spawn);
    for (final s in shockwaves) {
      s.removeFromParent();
    }
    shockwaves.clear();
  }

  @override
  void render(Canvas canvas) {
    final base = _flash > 0 ? Colors.white : const Color(0xFFD64550);
    final breathe = math.sin(_t * 3) * 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, breathe, width, height - breathe),
        const Radius.circular(10),
      ),
      Paint()..color = base,
    );
    // cornes
    final horn = Paint()..color = const Color(0xFF8E2430);
    canvas.drawPath(
      Path()
        ..moveTo(6, 6)
        ..lineTo(0, -8)
        ..lineTo(14, 4)
        ..close(),
      horn,
    );
    canvas.drawPath(
      Path()
        ..moveTo(width - 6, 6)
        ..lineTo(width, -8)
        ..lineTo(width - 14, 4)
        ..close(),
      horn,
    );
    // oeil unique
    final dir = game.player.position.x > position.x ? 1 : -1;
    canvas.drawCircle(
      Offset(width / 2 + dir * 6, 20 + breathe),
      7,
      Paint()..color = const Color(0xFFFFE9A0),
    );
    canvas.drawCircle(
      Offset(width / 2 + dir * 9, 20 + breathe),
      3,
      Paint()..color = const Color(0xFF1B1B2F),
    );
  }
}

class Shockwave extends PositionComponent with HasGameReference<MvGame> {
  Shockwave({required Vector2 position, required this.dir, required this.speed})
      : super(position: position, size: Vector2(22, 16));

  final int dir;
  final double speed;
  double _life = 3.0;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _life -= dt;
    position.x += dir * speed * dt;
    final cx = ((position.x + (dir > 0 ? width : 0)) / kTile).floor();
    final cy = ((position.y + height / 2) / kTile).floor();
    if (_life <= 0 || game.grid.isSolid(cx, cy)) {
      final b = game.boss;
      b?.shockwaves.remove(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = const Color(0xFFFF8C42);
    final h = 10 + math.sin(_t * 20) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(0, height)
        ..lineTo(width / 2, height - h)
        ..lineTo(width, height)
        ..close(),
      p,
    );
  }
}
