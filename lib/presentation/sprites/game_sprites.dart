import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';

import '../../core/palette.dart';
import '../../domain/entities/ability.dart';

/// Sprites Kenney (CC0) découpés dans les planches de `assets/images/`.
/// Les index correspondent aux fichiers « *_packed.png » d'origine.
class GameSprites {
  GameSprites._(this._tiles, this._chars, this._parallax, this._industrial);

  final SpriteSheet _tiles; // 18x18, 20 colonnes
  final SpriteSheet _chars; // 24x24, 9 colonnes
  final SpriteSheet _parallax; // 24x24, 4 colonnes, ciel transparent
  final SpriteSheet _industrial; // 18x18, 16 colonnes

  static Future<GameSprites> load(Images images) async {
    final loaded = await Future.wait([
      images.load('tiles.png'),
      images.load('characters.png'),
      images.load('parallax.png'),
      images.load('industrial.png'),
    ]);
    SpriteSheet sheet(int i, double size) =>
        SpriteSheet(image: loaded[i], srcSize: Vector2.all(size));
    return GameSprites._(
      sheet(0, 18),
      sheet(1, 24),
      sheet(2, 24),
      sheet(3, 18),
    );
  }

  Sprite tile(int id) => _tiles.getSpriteById(id);
  Sprite character(int id) => _chars.getSpriteById(id);

  // ---------- terrain ----------
  /// Herbe sur le dessus : isolée, bord gauche, milieu, bord droit.
  late final grassSingle = tile(0);
  late final grassLeft = tile(1);
  late final grassMid = tile(2);
  late final grassRight = tile(3);
  late final dirt = [tile(122), tile(104)];
  late final spike = tile(68);
  late final gate = _industrial.getSpriteById(62);
  late final decorations = [tile(124), tile(125), tile(126), tile(128)];

  // ---------- objets ----------
  late final coinFrames = [tile(151), tile(152)];
  late final heartFull = tile(44);
  late final heartHalf = tile(45);
  late final heartEmpty = tile(46);
  late final gem = tile(67);
  late final flagFrames = [tile(111), tile(112)];
  late final flagPole = tile(131);

  // ---------- personnages ----------
  late final crawlerFrames = [character(18), character(19)];
  late final bossCalm = character(11);
  late final bossAngry = character(12);

  // ---------- décor de fond ----------
  // (planche générée depuis tilemap-backgrounds, voir assets/CREDITS.md)
  late final cloudsLayer = [
    for (var i = 0; i < 4; i++) _parallax.getSpriteById(i)
  ];
  late final hillsLayer = [
    _parallax.getSpriteById(4),
    _parallax.getSpriteById(5)
  ];
  late final treesLayer = [
    _parallax.getSpriteById(8),
    _parallax.getSpriteById(9)
  ];

  static Color abilityColor(Ability a) => switch (a) {
        Ability.doubleJump => Palette.doubleJump,
        Ability.dash => Palette.dash,
        Ability.wallJump => Palette.wallJump,
      };
}
