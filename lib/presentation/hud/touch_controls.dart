import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import '../game/input_state.dart';

/// Boutons tactiles affichés dans le viewport, branchés sur [InputState].
class TouchControls extends Component {
  TouchControls(this.input);

  final InputState input;

  @override
  Future<void> onLoad() async {
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
        ..color = pressed ? const Color(0x66FFFFFF) : const Color(0x2EFFFFFF),
    );
    _text.render(
      canvas,
      label,
      Vector2(radius, radius),
      anchor: Anchor.center,
    );
  }
}
