import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../game/level_grid.dart';
import '../game/mv_game.dart';

class Hud extends PositionComponent with HasGameReference<MvGame> {
  Hud() : super(size: Vector2(640, 360), priority: 100);

  String _banner = '';
  double _bannerT = 0;

  static final _bannerPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFEFFFFB),
      fontSize: 15,
      fontWeight: FontWeight.bold,
      height: 1.4,
    ),
  );
  static final _coinPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFD166),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    _addTouchControls();
  }

  void showBanner(String text) {
    _banner = text;
    _bannerT = 3.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_bannerT > 0) _bannerT -= dt;
  }

  @override
  void render(Canvas canvas) {
    final p = game.player;

    // ---- cœurs ----
    for (var i = 0; i < p.maxHp; i++) {
      final full = i < p.hp;
      _drawHeart(canvas, Offset(14.0 + i * 20, 14),
          full ? const Color(0xFFE05263) : const Color(0xFF3A3F55));
    }

    // ---- pièces ----
    canvas.drawCircle(
        const Offset(20, 42), 6, Paint()..color = const Color(0xFFFFD166));
    _coinPaint.render(canvas, '× ${game.coins}', Vector2(30, 34));

    // ---- capacités ----
    final icons = <(Ability, Color, String)>[
      (Ability.doubleJump, const Color(0xFF4CC9F0), '2×'),
      (Ability.dash, const Color(0xFFFF8C42), '⚡'),
      (Ability.wallJump, const Color(0xFF7AE582), '≡'),
    ];
    for (var i = 0; i < icons.length; i++) {
      final (a, c, _) = icons[i];
      final has = game.abilities.contains(a);
      canvas.drawCircle(
        Offset(600.0 - i * 26, 20),
        9,
        Paint()..color = has ? c : const Color(0xFF2A2F4A),
      );
    }

    // ---- barre de vie du boss ----
    final boss = game.boss;
    if (boss != null && boss.active && !boss.dead) {
      const w = 260.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(320 - w / 2, 12, w, 12),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF2A2F4A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(320 - w / 2, 12, w * boss.hpRatio, 12),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFFD64550),
      );
    }

    // ---- bannière ----
    if (_bannerT > 0 && _banner.isNotEmpty) {
      final o = (_bannerT.clamp(0.0, 0.5)) / 0.5;
      canvas.saveLayer(null, Paint()..color = Colors.white.withOpacity(o));
      _bannerPaint.render(
        canvas,
        _banner,
        Vector2(320, 70),
        anchor: Anchor.topCenter,
      );
      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, Offset at, Color color) {
    final p = Paint()..color = color;
    canvas.drawCircle(at.translate(-3.5, 0), 4, p);
    canvas.drawCircle(at.translate(3.5, 0), 4, p);
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - 7, at.dy + 1.5)
        ..lineTo(at.dx, at.dy + 9)
        ..lineTo(at.dx + 7, at.dy + 1.5)
        ..close(),
      p,
    );
  }

  // ---------- boutons tactiles ----------

  void _addTouchControls() {
    final input = game.input;

    ButtonComponent btn({
      required Vector2 pos,
      required String label,
      required void Function() down,
      required void Function() up,
      double radius = 26,
    }) {
      return ButtonComponent(
        position: pos,
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
        button: _TouchCircle(label: label, radius: radius, pressed: false),
        buttonDown: _TouchCircle(label: label, radius: radius, pressed: true),
        onPressed: down,
        onReleased: up,
        onCancelled: up,
      );
    }

    addAll([
      btn(
        pos: Vector2(46, 320),
        label: '◀',
        down: () => input.tLeft = true,
        up: () => input.tLeft = false,
      ),
      btn(
        pos: Vector2(112, 320),
        label: '▶',
        down: () => input.tRight = true,
        up: () => input.tRight = false,
      ),
      btn(
        pos: Vector2(594, 316),
        label: '⭡',
        down: () {
          input.tJumpHeld = true;
          input.jumpQueued = true;
        },
        up: () => input.tJumpHeld = false,
        radius: 28,
      ),
      btn(
        pos: Vector2(532, 330),
        label: '⚡',
        down: () => input.dashQueued = true,
        up: () {},
        radius: 22,
      ),
      btn(
        pos: Vector2(548, 274),
        label: '✦',
        down: () => input.attackQueued = true,
        up: () {},
        radius: 22,
      ),
    ]);
  }
}

class _TouchCircle extends PositionComponent {
  _TouchCircle({
    required this.label,
    required this.radius,
    required this.pressed,
  }) : super(size: Vector2.all(radius * 2));

  final String label;
  final double radius;
  final bool pressed;

  static final _text = TextPaint(
    style: const TextStyle(color: Colors.white, fontSize: 18),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()
        ..color = pressed
            ? const Color(0x66FFFFFF)
            : const Color(0x2EFFFFFF),
    );
    _text.render(
      canvas,
      label,
      Vector2(radius, radius),
      anchor: Anchor.center,
    );
  }
}
