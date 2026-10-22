import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/entities/ability.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/game_sprites.dart';
import '../sprites/render_utils.dart';
import 'fx.dart';

/// Objet ramassable : hitbox [size] centrée dans sa cellule, sprite 18 px.
abstract class _Pickup extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  _Pickup({required Vector2 cellTopLeft, required double hitbox})
      : super(
          position: cellTopLeft + Vector2.all((kTile - hitbox) / 2),
          size: Vector2.all(hitbox),
        );

  double t = math.Random().nextDouble() * 6;

  double get bob => math.sin(t * 3) * 1.5;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (game.playing && toRect().overlaps(game.player.toRect())) onCollect();
  }

  void onCollect();

  void renderCentered(Canvas canvas, Sprite sprite, {Paint? paint}) {
    sprite.render(
      canvas,
      position: Vector2(width / 2 - kTile / 2, height / 2 - kTile / 2 + bob),
      size: Vector2.all(kTile),
      overridePaint: paint,
    );
  }
}

class Coin extends _Pickup {
  Coin({required super.cellTopLeft, required this.id}) : super(hitbox: 10);

  final int id;

  @override
  void onCollect() {
    game.collectCoin(id);
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.coin,
      count: 6,
      speed: 90,
    )..priority = 5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    drawGlow(canvas, Offset(width / 2, height / 2 + bob), 12, Palette.coin,
        intensity: 0.18);
    final frames = game.sprites.coinFrames;
    renderCentered(canvas, frames[(t * 5).floor() % frames.length]);
  }
}

class HeartPickup extends _Pickup {
  HeartPickup({required super.cellTopLeft}) : super(hitbox: 10);

  @override
  void onCollect() {
    if (game.player.hp >= game.player.maxHp) return; // reste au sol si plein
    game.player.hp++;
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.heart,
      count: 8,
      speed: 100,
    )..priority = 5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.2 + 0.1 * math.sin(t * 5);
    drawGlow(canvas, Offset(width / 2, height / 2 + bob), 14, Palette.heart,
        intensity: pulse);
    renderCentered(canvas, game.sprites.heartFull);
  }
}

class AbilityOrb extends _Pickup {
  AbilityOrb({required super.cellTopLeft, required this.ability})
      : super(hitbox: 12);

  final Ability ability;

  Color get color => GameSprites.abilityColor(ability);

  @override
  double get bob => math.sin(t * 2.4) * 2.5;

  @override
  void onCollect() {
    game.grantAbility(ability);
    game.shake(2.5, 0.3);
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: color,
      count: 24,
      speed: 180,
    )..priority = 5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(width / 2, height / 2 + bob);
    drawGlow(canvas, c, 30, color, intensity: 0.3 + 0.1 * math.sin(t * 4));
    // rayons tournants
    final rays = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 4; i++) {
      final a = t * 1.2 + i * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a)) * 13;
      canvas.drawLine(c - d, c + d, rays);
    }
    renderCentered(canvas, game.sprites.gem,
        paint: ability == Ability.doubleJump ? null : huePaint(color));
  }
}

class Checkpoint extends PositionComponent
    with HasGameReference<ShadowRelicGame> {
  Checkpoint({
    required Vector2 cellTopLeft,
    required this.id,
    this.activated = false,
  }) : super(position: cellTopLeft, size: Vector2(kTile, kTile));

  final int id;
  bool activated;
  double t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (!activated && game.playing && toRect().overlaps(game.player.toRect())) {
      activated = true;
      game.activateCheckpoint(id, position);
      game.hud.showBanner('CHECKPOINT');
      game.world.add(ParticleBurst(
        position: position + Vector2(kTile / 2, 4),
        color: Palette.accent,
        count: 12,
        speed: 120,
      )..priority = 5);
    }
  }

  @override
  void render(Canvas canvas) {
    final s = game.sprites;
    if (activated) {
      drawGlow(canvas, const Offset(kTile / 2, 6), 26, Palette.accent,
          intensity: 0.25 + 0.08 * math.sin(t * 4));
      s.flagFrames[(t * 4).floor() % 2]
          .render(canvas, size: Vector2.all(kTile));
    } else {
      s.flagPole.render(canvas, size: Vector2.all(kTile));
    }
  }
}
