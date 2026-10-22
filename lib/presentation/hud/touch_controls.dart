import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game/input_state.dart';
import '../game/shadow_relic_game.dart';

enum _Icon { left, right, jump, dash, attack }

/// Boutons tactiles affichés dans le viewport, branchés sur [InputState].
class TouchControls extends Component with HasGameReference<ShadowRelicGame> {
  TouchControls(this.input);

  final InputState input;

  /// Masqués (et inactifs) hors partie : menu, victoire.
  @override
  void renderTree(Canvas canvas) {
    if (game.playing) super.renderTree(canvas);
  }

  @override
  Future<void> onLoad() async {
    ButtonComponent btn({
      required Vector2 pos,
      required _Icon icon,
      required void Function() down,
      required void Function() up,
      double radius = 15,
      Color color = Palette.white,
    }) {
      return ButtonComponent(
        position: pos,
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
        button: _TouchButton(icon: icon, radius: radius, color: color),
        buttonDown: _TouchButton(
            icon: icon, radius: radius, color: color, pressed: true),
        onPressed: down,
        onReleased: up,
        onCancelled: up,
      );
    }

    const b = kViewHeight - 24;
    addAll([
      btn(
        pos: Vector2(26, b),
        icon: _Icon.left,
        down: () => input.tLeft = true,
        up: () => input.tLeft = false,
      ),
      btn(
        pos: Vector2(64, b),
        icon: _Icon.right,
        down: () => input.tRight = true,
        up: () => input.tRight = false,
      ),
      btn(
        pos: Vector2(kViewWidth - 26, b - 2),
        icon: _Icon.jump,
        radius: 17,
        color: Palette.accent,
        down: () {
          input.tJumpHeld = true;
          input.jumpQueued = true;
        },
        up: () => input.tJumpHeld = false,
      ),
      btn(
        pos: Vector2(kViewWidth - 64, b + 6),
        icon: _Icon.dash,
        radius: 13,
        color: Palette.dash,
        down: () => input.dashQueued = true,
        up: () {},
      ),
      btn(
        pos: Vector2(kViewWidth - 56, b - 30),
        icon: _Icon.attack,
        radius: 13,
        color: Palette.gold,
        down: () => input.attackQueued = true,
        up: () {},
      ),
    ]);
  }
}

class _TouchButton extends PositionComponent {
  _TouchButton({
    required this.icon,
    required this.radius,
    required this.color,
    this.pressed = false,
  }) : super(size: Vector2.all(radius * 2));

  final _Icon icon;
  final double radius;
  final Color color;
  final bool pressed;

  @override
  void render(Canvas canvas) {
    final c = Offset(radius, radius);
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = pressed ? const Color(0x80000000) : const Color(0x4D000000),
    );
    canvas.drawCircle(
      c,
      radius - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: pressed ? 0.9 : 0.45),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: pressed ? 1 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final r = radius * 0.4;
    final path = Path();
    switch (icon) {
      case _Icon.left:
        path
          ..moveTo(c.dx + r * 0.4, c.dy - r)
          ..lineTo(c.dx - r * 0.6, c.dy)
          ..lineTo(c.dx + r * 0.4, c.dy + r);
      case _Icon.right:
        path
          ..moveTo(c.dx - r * 0.4, c.dy - r)
          ..lineTo(c.dx + r * 0.6, c.dy)
          ..lineTo(c.dx - r * 0.4, c.dy + r);
      case _Icon.jump:
        path
          ..moveTo(c.dx - r, c.dy + r * 0.5)
          ..lineTo(c.dx, c.dy - r * 0.6)
          ..lineTo(c.dx + r, c.dy + r * 0.5);
      case _Icon.dash:
        for (final o in [-r * 0.5, r * 0.5]) {
          path
            ..moveTo(c.dx - r * 0.5 + o, c.dy - r * 0.8)
            ..lineTo(c.dx + r * 0.3 + o, c.dy)
            ..lineTo(c.dx - r * 0.5 + o, c.dy + r * 0.8);
        }
      case _Icon.attack:
        path.addArc(Rect.fromCircle(center: c, radius: r * 1.1), -math.pi * 0.8,
            math.pi * 0.9);
        path
          ..moveTo(c.dx - r * 0.7, c.dy + r * 0.7)
          ..lineTo(c.dx + r * 0.5, c.dy - r * 0.5);
    }
    canvas.drawPath(path, paint);
  }
}
