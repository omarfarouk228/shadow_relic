import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Peinture qui remplace toute la couleur d'un sprite (flash de dégâts,
/// silhouettes de décor).
Paint solidPaint(Color color) =>
    Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);

/// Peinture qui change la teinte d'un sprite en gardant ses ombres.
Paint huePaint(Color color) =>
    Paint()..colorFilter = ColorFilter.mode(color, BlendMode.hue);

/// Dessine [sprite] en taille native, pieds au point ([x], [y]),
/// retourné horizontalement si [flip].
void renderSpriteBottom(
  Canvas canvas,
  Sprite sprite,
  double x,
  double y, {
  bool flip = false,
  double scaleX = 1,
  double scaleY = 1,
  double size = 24,
  Paint? paint,
}) {
  canvas.save();
  canvas.translate(x, y);
  canvas.scale(flip ? -scaleX : scaleX, scaleY);
  sprite.render(
    canvas,
    position: Vector2(-size / 2, -size),
    size: Vector2.all(size),
    overridePaint: paint,
  );
  canvas.restore();
}

/// Halo lumineux additif.
void drawGlow(
  Canvas canvas,
  Offset center,
  double radius,
  Color color, {
  double intensity = 0.5,
}) {
  final paint = Paint()
    ..blendMode = BlendMode.plus
    ..shader = RadialGradient(
      colors: [
        color.withValues(alpha: intensity),
        color.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  canvas.drawCircle(center, radius, paint);
}
