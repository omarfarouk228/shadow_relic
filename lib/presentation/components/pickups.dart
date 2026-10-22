import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/entities/ability.dart';
import '../game/shadow_relic_game.dart';
import 'fx.dart';

abstract class _Pickup extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  _Pickup({required Vector2 cellTopLeft, required Vector2 size})
      : super(
          position:
              cellTopLeft + Vector2((kTile - size.x) / 2, (kTile - size.y) / 2),
          size: size,
        );

  double t = math.Random().nextDouble() * 6;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (toRect().overlaps(game.player.toRect())) onCollect();
  }

  void onCollect();
}

class Coin extends _Pickup {
  Coin({required super.cellTopLeft}) : super(size: Vector2.all(14));

  @override
  void onCollect() {
    game.addCoin();
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: const Color(0xFFFFD166),
      count: 6,
      speed: 90,
    )..priority = 5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final bob = math.sin(t * 3) * 3;
    canvas.drawCircle(
      Offset(width / 2, height / 2 + bob),
      7,
      Paint()..color = const Color(0xFFFFD166),
    );
    canvas.drawCircle(
      Offset(width / 2, height / 2 + bob),
      4,
      Paint()..color = const Color(0xFFF4A93D),
    );
  }
}

class HeartPickup extends _Pickup {
  HeartPickup({required super.cellTopLeft}) : super(size: Vector2.all(18));

  @override
  void onCollect() {
    if (game.player.hp >= game.player.maxHp) return; // reste au sol si plein
    game.player.hp++;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final bob = math.sin(t * 3) * 3;
    final p = Paint()..color = const Color(0xFFE05263);
    canvas.drawCircle(Offset(5.5, 6 + bob), 4.5, p);
    canvas.drawCircle(Offset(12.5, 6 + bob), 4.5, p);
    canvas.drawPath(
      Path()
        ..moveTo(1.5, 8 + bob)
        ..lineTo(9, 17 + bob)
        ..lineTo(16.5, 8 + bob)
        ..close(),
      p,
    );
  }
}

class AbilityOrb extends _Pickup {
  AbilityOrb({required super.cellTopLeft, required this.ability})
      : super(size: Vector2.all(22));

  final Ability ability;

  Color get color => switch (ability) {
        Ability.doubleJump => const Color(0xFF4CC9F0),
        Ability.dash => const Color(0xFFFF8C42),
        Ability.wallJump => const Color(0xFF7AE582),
      };

  @override
  void onCollect() {
    game.grantAbility(ability);
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: color,
      count: 18,
      speed: 160,
    )..priority = 5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final bob = math.sin(t * 2.4) * 4;
    final c = Offset(width / 2, height / 2 + bob);
    // halo pulsant
    canvas.drawCircle(
      c,
      13 + math.sin(t * 4) * 2,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(c, 9, Paint()..color = color);
    canvas.drawCircle(
      c.translate(-2, -2),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }
}

class Checkpoint extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  Checkpoint({required Vector2 cellTopLeft})
      : super(position: cellTopLeft, size: Vector2(kTile, kTile));

  bool activated = false;
  double t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (!activated && toRect().overlaps(game.player.toRect())) {
      activated = true;
      // point de réapparition : posé au sol, centré sur le poteau
      game.setCheckpoint(
        Vector2(position.x + 5, position.y + kTile - 28),
      );
      game.hud.showBanner('CHECKPOINT');
      game.world.add(ParticleBurst(
        position: position + Vector2(kTile / 2, 8),
        color: const Color(0xFF4CC9F0),
        count: 10,
        speed: 110,
      )..priority = 5);
    }
  }

  @override
  void render(Canvas canvas) {
    // poteau
    canvas.drawRect(
      const Rect.fromLTWH(kTile / 2 - 2, 4, 4, kTile - 4),
      Paint()..color = const Color(0xFF5A6178),
    );
    // flamme (cyan si actif)
    final flame = Paint()
      ..color = activated ? const Color(0xFF4CC9F0) : const Color(0xFF3A3F55);
    final fh = activated ? 8 + math.sin(t * 8) * 2 : 7.0;
    canvas.drawCircle(const Offset(kTile / 2, 4), fh, flame);
  }
}
