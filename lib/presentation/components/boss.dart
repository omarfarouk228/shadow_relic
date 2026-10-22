import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/physics/collision.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/render_utils.dart';
import 'fx.dart';

class Boss extends PositionComponent with HasGameReference<ShadowRelicGame> {
  Boss({required Vector2 position})
      : _spawn = position.clone(),
        super(position: position, size: Vector2.all(bossSize));

  static const bossSize = 32.0;
  static const maxHp = 24;
  static const gravity = 1500.0 * kScale;
  static const arenaLeftLimit = 106 * kTile;
  static const windup = 0.35;

  final Vector2 _spawn;
  int hp = maxHp;
  bool active = false;
  bool dead = false;
  final vel = Vector2.zero();
  double _hopTimer = 1.2;
  double _flash = 0;
  double _iframes = 0;
  double _t = 0;
  double _squash = 0;
  bool _inAir = false;
  final List<Shockwave> shockwaves = [];

  double get hpRatio => hp / maxHp;
  bool get enraged => hp <= maxHp / 2;

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0.05) dt = 0.05;
    _t += dt;
    _flash = math.max(0, _flash - dt);
    _iframes = math.max(0, _iframes - dt);
    _squash *= math.exp(-10 * dt);
    if (dead || !game.playing) return;

    final player = game.player;

    // activation quand le joueur entre dans l'arène
    if (!active) {
      if (player.position.y < 9 * kTile &&
          (player.position.x - position.x).abs() < 9 * kTile) {
        active = true;
        game.shake(3, 0.4);
        game.hud.showBanner(
            'LE GARDIEN DE LA RELIQUE\nDétruis-le pour récupérer la relique');
      }
      return;
    }

    // phase 2 : plus rapide sous 50% de vie
    final hopEvery = enraged ? 1.1 : 1.8;

    if (!_inAir) {
      vel.x = 0;
      _hopTimer -= dt;
      if (_hopTimer <= 0) {
        _hopTimer = hopEvery;
        final dir = player.position.x > position.x ? 1 : -1;
        vel.x = dir * (enraged ? 190.0 : 140.0) * kScale;
        vel.y = -540 * kScale;
        _inAir = true;
        _squash = 0.35;
      }
    }
    vel.y = math.min(vel.y + gravity * dt, 600 * kScale);

    final hit = moveAndCollide(game.grid, position, size, vel, dt);
    position.x =
        position.x.clamp(arenaLeftLimit, game.grid.worldWidth - 3 * kTile);

    if (hit.down && _inAir) {
      _inAir = false;
      vel.x = 0;
      _squash = -0.4;
      _spawnShockwaves();
      game.shake(enraged ? 5 : 4, 0.3);
      game.world.add(
          Poof(position: position + Vector2(width / 2, height))..priority = 5);
    }
  }

  void _spawnShockwaves() {
    final y = position.y + height - Shockwave.h;
    for (final d in [-1, 1]) {
      final s = Shockwave(
        position: Vector2(position.x + width / 2 + d * 14 - Shockwave.w / 2, y),
        dir: d,
        speed: (enraged ? 230 : 175) * kScale,
      )..priority = 3;
      shockwaves.add(s);
      game.world.add(s);
    }
  }

  /// Retourne vrai si le coup a porté.
  bool takeHit(int dmg) {
    if (dead || !active || _iframes > 0) return false;
    hp -= dmg;
    _flash = 0.1;
    _iframes = 0.25;
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.boss,
      count: 6,
      glow: false,
    )..priority = 5);
    if (hp <= 0) {
      dead = true;
      active = false;
      game.shake(6, 0.6);
      game.hitStop(0.2);
      game.world.add(ParticleBurst(
        position: position + size / 2,
        color: Palette.gold,
        count: 40,
        speed: 260,
      )..priority = 5);
      for (final s in shockwaves) {
        s.removeFromParent();
      }
      shockwaves.clear();
      removeFromParent();
      game.onVictory();
    }
    return true;
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
    final center = Offset(width / 2, height / 2);
    if (active) {
      drawGlow(canvas, center, 40, enraged ? Palette.danger : Palette.boss,
          intensity: enraged ? 0.35 + 0.15 * math.sin(_t * 10) : 0.22);
    }
    // ombre au sol (rétrécit en l'air)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(width / 2, height),
          width: _inAir ? 22 : 36,
          height: 4),
      Paint()..color = const Color(0x66000000),
    );

    // prépare son saut : tremble juste avant de décoller
    final aboutToHop = active && !_inAir && _hopTimer < windup;
    final jitter = aboutToHop ? math.sin(_t * 80) * 1.0 : 0.0;
    final breathe = math.sin(_t * 3) * 0.03;
    final sy = 1 + _squash + breathe - (aboutToHop ? 0.12 : 0);
    final sx = 1 - _squash * 0.5 + (aboutToHop ? 0.08 : 0);
    final facingLeft = game.player.position.x < position.x;

    renderSpriteBottom(
      canvas,
      enraged || aboutToHop ? game.sprites.bossAngry : game.sprites.bossCalm,
      width / 2 + jitter,
      height + 2,
      size: 48,
      flip: facingLeft,
      scaleX: sx,
      scaleY: sy,
      paint: _flash > 0
          ? solidPaint(Colors.white)
          : enraged
              ? huePaint(Palette.danger)
              : null,
    );
  }
}

class Shockwave extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  Shockwave({required Vector2 position, required this.dir, required this.speed})
      : super(position: position, size: Vector2(w, h));

  static const w = 12.0;
  static const h = 10.0;

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
      game.boss?.shockwaves.remove(this);
      game.world.add(
          Poof(position: position + Vector2(width / 2, height), small: true)
            ..priority = 5);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    drawGlow(canvas, Offset(width / 2, height), 16, Palette.shockwave,
        intensity: 0.45);
    final crest = 7 + math.sin(_t * 22) * 2.5;
    final path = Path()
      ..moveTo(0, height)
      ..quadraticBezierTo(
          width * (dir > 0 ? 0.7 : 0.3), height - crest * 1.6, width, height)
      ..close();
    canvas.drawPath(path, Paint()..color = Palette.shockwave);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFE0A0),
    );
  }
}
