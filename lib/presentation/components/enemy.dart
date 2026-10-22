import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/physics/collision.dart';
import '../game/shadow_relic_game.dart';
import 'fx.dart';

class Enemy extends PositionComponent with HasGameReference<ShadowRelicGame> {
  Enemy({required Vector2 position})
      : super(position: position, size: Vector2(26, 26));

  static const speed = 42.0;
  static const gravity = 1400.0;

  final vel = Vector2.zero();
  int dir = 1;
  int hp = 2;
  double _flash = 0;
  double _knock = 0;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0.05) dt = 0.05;
    _t += dt;
    _flash = math.max(0, _flash - dt);
    _knock = math.max(0, _knock - dt);

    if (_knock <= 0) vel.x = dir * speed;
    vel.y = math.min(vel.y + gravity * dt, 520);

    final hit = moveAndCollide(game.grid, position, size, vel, dt);

    if (hit.left) dir = 1;
    if (hit.right) dir = -1;

    // demi-tour au bord d'une plateforme
    if (hit.down && _knock <= 0) {
      final aheadX = dir > 0 ? position.x + width + 2 : position.x - 2;
      final cx = (aheadX / kTile).floor();
      final cy = ((position.y + height + 4) / kTile).floor();
      if (!game.grid.isSolid(cx, cy)) dir = -dir;
    }
  }

  void takeHit(int dmg, double fromDir) {
    hp -= dmg;
    _flash = 0.15;
    _knock = 0.25;
    vel.x = fromDir * 190;
    vel.y = -160;
    if (hp <= 0) {
      game.enemies.remove(this);
      game.world.add(ParticleBurst(
        position: position + size / 2,
        color: const Color(0xFFC96BFF),
        count: 10,
      )..priority = 5);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = _flash > 0 ? Colors.white : const Color(0xFF9B4DE0);
    final bob = math.sin(_t * 6) * 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 4 + bob, width, height - 4 - bob),
        const Radius.circular(8),
      ),
      Paint()..color = c,
    );
    // yeux
    final eye = Paint()..color = const Color(0xFFFFE9A0);
    final off = dir > 0 ? 4.0 : -4.0;
    canvas.drawCircle(Offset(width / 2 - 5 + off, 12 + bob), 2.4, eye);
    canvas.drawCircle(Offset(width / 2 + 5 + off, 12 + bob), 2.4, eye);
    // pattes
    final leg = Paint()..color = const Color(0xFF6B2FA8);
    for (var i = 0; i < 3; i++) {
      final lx = 4.0 + i * 8 + math.sin(_t * 10 + i) * 2;
      canvas.drawRect(Rect.fromLTWH(lx, height - 4, 4, 4), leg);
    }
  }
}
