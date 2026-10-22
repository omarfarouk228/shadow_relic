import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'player.dart';

/// Petit nuage qui s'étend et disparaît (atterrissage, double saut...).
class Poof extends PositionComponent {
  Poof({required Vector2 position, this.small = false})
      : super(position: position, anchor: Anchor.center);

  final bool small;
  double life = 0.25;
  double t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = t / life;
    final r = (small ? 6 : 12) * (0.4 + p);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.5 * (1 - p)),
    );
  }
}

/// Arc de coup d'épée, suit le joueur.
class SlashFx extends PositionComponent {
  SlashFx({required this.owner, required this.dir});

  final Player owner;
  final int dir;
  double t = 0;
  static const life = 0.16;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (t >= life || owner.isRemoved) {
      removeFromParent();
      return;
    }
    position = owner.position +
        Vector2(dir > 0 ? owner.width + 14 : -14, owner.height / 2);
  }

  @override
  void render(Canvas canvas) {
    final p = t / life;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - p) + 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEFFFFB).withValues(alpha: 1 - p);
    final rect = Rect.fromCircle(center: Offset.zero, radius: 16);
    final start = dir > 0 ? -math.pi / 2.2 : math.pi - math.pi / 1.9;
    canvas.drawArc(rect, start + p * 0.6 * dir, math.pi * 0.85, false, paint);
  }
}

/// Explosion de petites particules carrées.
class ParticleBurst extends PositionComponent {
  ParticleBurst({
    required Vector2 position,
    required this.color,
    this.count = 10,
    this.speed = 130,
  }) : super(position: position) {
    final rng = math.Random();
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final s = speed * (0.4 + rng.nextDouble() * 0.6);
      _parts.add(_P(
        Vector2.zero(),
        Vector2(math.cos(a), math.sin(a) - 0.4) * s,
        0.3 + rng.nextDouble() * 0.3,
        2 + rng.nextDouble() * 3,
      ));
    }
  }

  final Color color;
  final int count;
  final double speed;
  final List<_P> _parts = [];
  double t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    var alive = false;
    for (final p in _parts) {
      if (t >= p.life) continue;
      alive = true;
      p.vel.y += 500 * dt;
      p.pos.add(p.vel * dt);
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _parts) {
      if (t >= p.life) continue;
      final o = (1 - t / p.life).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(p.pos.x, p.pos.y), width: p.size, height: p.size),
        Paint()..color = color.withValues(alpha: o),
      );
    }
  }
}

class _P {
  _P(this.pos, this.vel, this.life, this.size);
  final Vector2 pos;
  final Vector2 vel;
  final double life;
  final double size;
}
