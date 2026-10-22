import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';

import '../../core/palette.dart';
import '../../domain/entities/hero_class.dart';

/// Lignes des atlas générés par `tool/build_hero_atlases.py`.
enum HeroAnim { idle, run, jump, fall, attack, dash, hurt }

/// Infos d'affichage d'un personnage (nom, texte, couleur, frames).
extension HeroLook on HeroClass {
  String get displayName => switch (this) {
        HeroClass.knight => 'LE CHEVALIER',
        HeroClass.samurai => 'LE SAMOURAÏ',
        HeroClass.ninja => 'LE NINJA',
      };

  String get tagline => switch (this) {
        HeroClass.knight => 'Armure lourde et bouclier : encaisse les coups.',
        HeroClass.samurai =>
          'Son katana frappe plus loin que les autres lames.',
        HeroClass.ninja => 'Vif et insaisissable, mais peu résistant.',
      };

  Color get color => switch (this) {
        HeroClass.knight => Palette.danger,
        HeroClass.samurai => Palette.gold,
        HeroClass.ninja => Palette.accent,
      };

  /// Nombre de frames par animation (doit correspondre à l'atlas).
  Map<HeroAnim, int> get frameCounts => switch (this) {
        HeroClass.knight => const {
            HeroAnim.idle: 5,
            HeroAnim.run: 6,
            HeroAnim.jump: 4,
            HeroAnim.fall: 4,
            HeroAnim.attack: 7,
            HeroAnim.dash: 7,
            HeroAnim.hurt: 3,
          },
        HeroClass.samurai => const {
            HeroAnim.idle: 4,
            HeroAnim.run: 6,
            HeroAnim.jump: 2,
            HeroAnim.fall: 2,
            HeroAnim.attack: 5,
            HeroAnim.dash: 2,
            HeroAnim.hurt: 1,
          },
        HeroClass.ninja => const {
            HeroAnim.idle: 4,
            HeroAnim.run: 6,
            HeroAnim.jump: 2,
            HeroAnim.fall: 2,
            HeroAnim.attack: 3,
            HeroAnim.dash: 2,
            HeroAnim.hurt: 1,
          },
      };

  /// Le chevalier a déjà un grand arc de lame dans ses sprites.
  bool get drawsOwnSlash => this == HeroClass.knight;
}

/// Frames d'un personnage : cellules 48x32, pieds au point (24, 31).
class HeroSprites {
  HeroSprites._(this.hero, this._frames);

  static const cellW = 48.0;
  static const cellH = 32.0;
  static const anchorX = 24.0;
  static const anchorY = 31.0;

  final HeroClass hero;
  final Map<HeroAnim, List<Sprite>> _frames;

  static Future<Map<HeroClass, HeroSprites>> loadAll(Images images) async {
    final result = <HeroClass, HeroSprites>{};
    for (final h in HeroClass.values) {
      final image = await images.load('heroes/${h.name}.png');
      final sheet = SpriteSheet(image: image, srcSize: Vector2(cellW, cellH));
      result[h] = HeroSprites._(h, {
        for (final a in HeroAnim.values)
          a: [
            for (var i = 0; i < h.frameCounts[a]!; i++)
              sheet.getSprite(a.index, i),
          ],
      });
    }
    return result;
  }

  List<Sprite> frames(HeroAnim anim) => _frames[anim]!;

  /// Frame de [anim] à l'instant [t] (en secondes), en boucle ou non.
  Sprite frameAt(HeroAnim anim, double t, {double fps = 10, bool loop = true}) {
    final f = frames(anim);
    var i = (t * fps).floor();
    i = loop ? i % f.length : i.clamp(0, f.length - 1);
    return f[i];
  }

  /// Dessine [sprite] avec les pieds au point ([x], [y]).
  static void render(
    Canvas canvas,
    Sprite sprite,
    double x,
    double y, {
    bool flip = false,
    double scaleX = 1,
    double scaleY = 1,
    double zoom = 1,
    Paint? paint,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale((flip ? -scaleX : scaleX) * zoom, scaleY * zoom);
    sprite.render(
      canvas,
      position: Vector2(-anchorX, -anchorY),
      size: Vector2(cellW, cellH),
      overridePaint: paint,
    );
    canvas.restore();
  }
}
