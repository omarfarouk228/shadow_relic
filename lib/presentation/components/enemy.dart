import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/physics/collision.dart';
import '../audio/game_audio.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/render_utils.dart';
import 'fx.dart';

class Enemy extends PositionComponent with HasGameReference<ShadowRelicGame> {
  Enemy({required Vector2 position})
      : super(position: position, size: Vector2(14, 11));

  static const speed = 42.0 * kScale;
  static const gravity = 1400.0 * kScale;

  final vel = Vector2.zero();
  int dir = 1;
  int hp = 2;
  double _flash = 0;
  double _knock = 0;
  double _t = math.Random().nextDouble();

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0.05) dt = 0.05;
    _t += dt;
    _flash = math.max(0, _flash - dt);
    _knock = math.max(0, _knock - dt);

    if (_knock <= 0) vel.x = dir * speed;
    vel.y = math.min(vel.y + gravity * dt, 520 * kScale);

    final hit = moveAndCollide(game.grid, position, size, vel, dt);

    if (hit.left) dir = 1;
    if (hit.right) dir = -1;

    // demi-tour au bord d'une plateforme
    if (hit.down && _knock <= 0) {
      final aheadX = dir > 0 ? position.x + width + 1 : position.x - 1;
      final cx = (aheadX / kTile).floor();
      final cy = ((position.y + height + 2) / kTile).floor();
      if (!game.grid.isSolid(cx, cy)) dir = -dir;
    }
  }

  void takeHit(int dmg, double fromDir) {
    hp -= dmg;
    _flash = 0.12;
    _knock = 0.25;
    game.audio.play(hp <= 0 ? Sfx.enemyDie : Sfx.hit);
    vel.x = fromDir * 190 * kScale;
    vel.y = -160 * kScale;
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.enemyHit,
      count: 5,
      glow: false,
    )..priority = 5);
    if (hp <= 0) {
      game.enemies.remove(this);
      game.world.add(ParticleBurst(
        position: position + size / 2,
        color: Palette.enemyHit,
        count: 14,
        speed: 170,
      )..priority = 5);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final frames = game.sprites.crawlerFrames;
    final frame = frames[(_t * 6).floor() % 2];
    canvas.drawOval(
      Rect.fromCenter(center: Offset(width / 2, height), width: 14, height: 3),
      Paint()..color = const Color(0x55000000),
    );
    renderSpriteBottom(
      canvas,
      frame,
      width / 2,
      height + 1,
      flip: dir < 0,
      paint: _flash > 0 ? solidPaint(Colors.white) : null,
    );
  }
}
