import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../sprites/render_utils.dart';
import 'player.dart';

/// Petits nuages de poussière (atterrissage, double saut, dash...).
class Poof extends PositionComponent {
  Poof({required Vector2 position, this.small = false})
      : super(position: position) {
    final rng = math.Random();
    final n = small ? 3 : 6;
    for (var i = 0; i < n; i++) {
      final a = math.pi + rng.nextDouble() * math.pi;
      _puffs.add((
        Offset(math.cos(a), math.sin(a) * 0.4) * (small ? 9 : 16) * kScale,
        (small ? 2.0 : 3.0) + rng.nextDouble() * 2,
      ));
    }
  }

  final bool small;
  final List<(Offset, double)> _puffs = [];
  static const life = 0.35;
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
    final ease = 1 - math.pow(1 - p, 3).toDouble();
    final paint = Paint()
      ..color = const Color(0xFFE9E1FF).withValues(alpha: 0.75 * (1 - p));
    for (final (dir, r) in _puffs) {
      canvas.drawCircle(dir * ease * 2.2, r * (1 - p * 0.6), paint);
    }
  }
}

/// Arc de coup d'épée, suit le joueur.
class SlashFx extends PositionComponent {
  SlashFx({required this.owner, required this.dir}) : super(priority: 6);

  final Player owner;
  final int dir;
  double t = 0;
  static const life = 0.14;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (t >= life || owner.isRemoved) {
      removeFromParent();
      return;
    }
    position = owner.position +
        Vector2(dir > 0 ? owner.width + 6 : -6, owner.height / 2 - 1);
  }

  @override
  void render(Canvas canvas) {
    final p = t / life;
    final rect = Rect.fromCircle(center: Offset.zero, radius: 11);
    final start = dir > 0 ? -math.pi / 2.1 : math.pi - math.pi / 1.95;
    const sweep = math.pi * 0.9;
    drawGlow(canvas, Offset(dir * 4.0, 0), 16, Palette.accent,
        intensity: 0.35 * (1 - p));
    canvas.drawArc(
      rect,
      start + p * 0.5 * dir,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - p) + 1
        ..strokeCap = StrokeCap.round
        ..color = Palette.accent.withValues(alpha: 0.8 * (1 - p)),
    );
    canvas.drawArc(
      rect.deflate(1.5),
      start + p * 0.5 * dir,
      sweep * 0.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 1 - p),
    );
  }
}

/// Explosion de particules carrées (alignées sur la grille de pixels).
class ParticleBurst extends PositionComponent {
  ParticleBurst({
    required Vector2 position,
    required this.color,
    this.count = 10,
    double speed = 130,
    this.glow = true,
  }) : super(position: position) {
    final rng = math.Random();
    final s0 = speed * kScale;
    for (var i = 0; i < count; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final s = s0 * (0.4 + rng.nextDouble() * 0.6);
      _parts.add(_P(
        Vector2.zero(),
        Vector2(math.cos(a), math.sin(a) - 0.4) * s,
        0.35 + rng.nextDouble() * 0.35,
        rng.nextBool() ? 2 : 1,
      ));
    }
  }

  final Color color;
  final int count;
  final bool glow;
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
      p.vel.y += 380 * kScale * dt;
      p.pos.add(p.vel * dt);
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (glow && t < 0.15) {
      drawGlow(canvas, Offset.zero, 26, color, intensity: 0.5 * (1 - t / 0.15));
    }
    final paint = Paint();
    for (final p in _parts) {
      if (t >= p.life) continue;
      final o = (1 - t / p.life).clamp(0.0, 1.0);
      paint.color = (t < 0.06 ? Colors.white : color).withValues(alpha: o);
      canvas.drawRect(
        Rect.fromLTWH(
            p.pos.x.roundToDouble(), p.pos.y.roundToDouble(), p.size, p.size),
        paint,
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

/// Image rémanente du joueur pendant le dash.
class Afterimage extends PositionComponent {
  Afterimage({
    required Vector2 position,
    required this.sprite,
    required this.flip,
  }) : super(position: position, priority: 3);

  final Sprite sprite;
  final bool flip;
  static const life = 0.22;
  double t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    if (t >= life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - t / life) * 0.55;
    renderSpriteBottom(canvas, sprite, 0, 0,
        flip: flip, paint: solidPaint(Palette.accent.withValues(alpha: a)));
  }
}
