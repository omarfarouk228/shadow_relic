import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/entities/ability.dart';
import '../components/boss.dart';
import '../game/shadow_relic_game.dart';
import '../overlays/overlay_ids.dart';
import '../sprites/game_sprites.dart';
import '../sprites/render_utils.dart';
import 'touch_controls.dart';

/// Polices de l'interface (déclarées dans pubspec.yaml).
abstract final class HudFonts {
  static const title = 'KenneyFuture';
  static const body = 'KenneyMini';
}

TextPaint _text(double size, Color color, {String font = HudFonts.body}) =>
    TextPaint(
      style: TextStyle(
        fontFamily: font,
        fontSize: size,
        color: color,
        height: 1,
      ),
    );

class Hud extends PositionComponent with HasGameReference<ShadowRelicGame> {
  Hud() : super(size: Vector2(kViewWidth, kViewHeight), priority: 100);

  /// Contrôles tactiles seulement sur mobile.
  static bool get showTouchControls =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String _bannerTitle = '';
  String _bannerSub = '';
  Color _bannerColor = Palette.gold;
  double _bannerT = 0;
  static const _bannerLife = 3.2;

  int _lastHp = 5;
  double _hurtT = 0;
  double _bossShown = 0; // fondu d'apparition de la barre
  double _bossTrail = 1; // traînée blanche qui rattrape la vie réelle
  double _t = 0;

  static final _coinText = _text(10, Palette.white);
  static final _shadowText = _text(10, Palette.outline);
  static final _bossName = _text(8, Palette.white, font: HudFonts.title);
  static final _bossNameShadow =
      _text(8, Palette.outline, font: HudFonts.title);
  static final _bannerSubText = _text(8, Palette.textSoft);
  static final _bossNameEnraged =
      _text(8, const Color(0xFFFF6B7A), font: HudFonts.title);
  static final _hpText = _text(9, Palette.white);
  static final _hpShadow = _text(9, Palette.outline);

  @override
  Future<void> onLoad() async {
    if (showTouchControls) add(TouchControls(game.input));
  }

  void clearBanner() => _bannerT = 0;

  void showBanner(String text, {Color color = Palette.gold}) {
    final lines = text.split('\n');
    _bannerTitle = lines.first;
    _bannerSub = lines.length > 1 ? lines[1] : '';
    _bannerColor = color;
    _bannerT = _bannerLife;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_bannerT > 0) _bannerT -= dt;
    final hp = game.player.hp;
    if (hp < _lastHp) _hurtT = 0.4;
    _lastHp = hp;
    _hurtT = math.max(0, _hurtT - dt);

    final boss = game.boss;
    final showBoss = boss != null && boss.active && !boss.dead;
    _bossShown = (_bossShown + (showBoss ? dt : -dt) * 3).clamp(0.0, 1.0);
    final ratio = boss?.hpRatio ?? 0;
    if (_bossTrail > ratio) {
      _bossTrail = math.max(ratio, _bossTrail - dt * 0.35);
    } else {
      _bossTrail = ratio;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.playing && game.overlays.isActive(Overlays.menu)) return;
    final s = game.sprites;
    final p = game.player;

    // ---- cœurs ----
    for (var i = 0; i < p.maxHp; i++) {
      final full = i < p.hp;
      var dy = 0.0;
      if (_hurtT > 0 && i == p.hp) dy = math.sin(_hurtT * 60) * 2;
      if (full && p.hp == 1) dy = math.sin(_t * 10) * 0.8; // vie critique
      (full ? s.heartFull : s.heartEmpty).render(
        canvas,
        position: Vector2(4 + i * 15, 3 + dy),
        size: Vector2.all(18),
      );
    }

    // ---- pièces ----
    s.coinFrames[0]
        .render(canvas, position: Vector2(3, 20), size: Vector2.all(18));
    final label = '${game.coins}/${game.totalCoins}';
    _shadowText.render(canvas, label, Vector2(22, 27));
    _coinText.render(canvas, label, Vector2(21, 26));

    // ---- capacités ----
    const slot = 20.0;
    for (var i = 0; i < Ability.values.length; i++) {
      final a = Ability.values[i];
      final x = kViewWidth - 4 - slot - (Ability.values.length - 1 - i) * 23;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 4, slot, slot), const Radius.circular(3));
      canvas.drawRRect(r, Paint()..color = const Color(0xB31E1836));
      final has = game.abilities.contains(a);
      final color = GameSprites.abilityColor(a);
      if (has) drawGlow(canvas, r.center, 14, color, intensity: 0.25);
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = has ? color : Palette.panelLight,
      );
      s.gem.render(
        canvas,
        position: Vector2(x + 1, 5),
        size: Vector2.all(18),
        overridePaint: has
            ? (a == Ability.doubleJump ? null : huePaint(color))
            : solidPaint(Palette.panelLight),
      );
    }

    // ---- barre de vie du boss (en haut, au centre) ----
    if (_bossShown > 0) {
      canvas.saveLayer(
          null, Paint()..color = Colors.white.withValues(alpha: _bossShown));
      final boss = game.boss;
      final enraged = boss?.enraged ?? false;
      const w = 220.0;
      const x = (kViewWidth - w) / 2;
      final y = 18 - (1 - _bossShown) * 8;
      final hp = math.max(0, boss?.hp ?? 0);

      // nom à gauche, points de vie à droite
      final name = enraged ? 'LE GARDIEN  ·  ENRAGÉ' : 'LE GARDIEN';
      _bossNameShadow.render(canvas, name, Vector2(x + 1, y - 10));
      (enraged ? _bossNameEnraged : _bossName)
          .render(canvas, name, Vector2(x, y - 11));
      final hpLabel = '$hp / ${Boss.maxHp}';
      _hpShadow.render(canvas, hpLabel, Vector2(x + w + 1, y - 10),
          anchor: Anchor.topRight);
      _hpText.render(canvas, hpLabel, Vector2(x + w, y - 11),
          anchor: Anchor.topRight);

      final frame = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, y - 2, w + 4, 12), const Radius.circular(3));
      if (enraged) {
        drawGlow(canvas, frame.center, w * 0.6, Palette.danger,
            intensity: 0.12 + 0.06 * math.sin(_t * 8));
      }
      canvas.drawRRect(frame, Paint()..color = Palette.outline);
      canvas.drawRect(
          Rect.fromLTWH(x, y, w, 8), Paint()..color = Palette.dangerDark);
      canvas.drawRect(Rect.fromLTWH(x, y, w * _bossTrail, 8),
          Paint()..color = const Color(0xFFFFE9D6));
      final ratio = boss?.hpRatio ?? 0;
      canvas.drawRect(
        Rect.fromLTWH(x, y, w * ratio, 8),
        Paint()
          ..shader = LinearGradient(colors: [
            Palette.danger,
            enraged ? const Color(0xFFFF3D6E) : Palette.boss,
          ]).createShader(const Rect.fromLTWH(x, 0, w, 8)),
      );
      canvas.drawRect(Rect.fromLTWH(x, y, w * ratio, 2),
          Paint()..color = const Color(0x55FFFFFF));
      // repère de la phase 2 (moitié de la vie)
      canvas.drawRect(Rect.fromLTWH(x + w / 2 - 0.5, y, 1, 8),
          Paint()..color = const Color(0x990A0815));
      canvas.restore();
    }

    // ---- bannière ----
    if (_bannerT > 0 && _bannerTitle.isNotEmpty) {
      final age = _bannerLife - _bannerT;
      final appear = Curves.easeOutBack.transform((age / 0.35).clamp(0, 1));
      final fade = (_bannerT / 0.5).clamp(0.0, 1.0);
      final title = _text(13, _bannerColor, font: HudFonts.title);
      final tw = title.getLineMetrics(_bannerTitle).width;
      final sw = _bannerSub.isEmpty
          ? 0.0
          : _bannerSubText.getLineMetrics(_bannerSub).width;
      final w = math.max(tw, sw) + 28;
      final h = _bannerSub.isEmpty ? 22.0 : 34.0;
      const cx = kViewWidth / 2;
      final y = (_bossShown > 0 ? 38.0 : 30.0) - (1 - appear) * 14;

      canvas.saveLayer(
          null, Paint()..color = Colors.white.withValues(alpha: fade));
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, y + h / 2), width: w, height: h),
          const Radius.circular(4));
      canvas.drawRRect(r, Paint()..color = const Color(0xE6120E24));
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _bannerColor.withValues(alpha: 0.8),
      );
      drawGlow(canvas, Offset(cx, y + 9), w / 2, _bannerColor, intensity: 0.12);
      title.render(canvas, _bannerTitle, Vector2(cx, y + 5),
          anchor: Anchor.topCenter);
      if (_bannerSub.isNotEmpty) {
        _bannerSubText.render(canvas, _bannerSub, Vector2(cx, y + 21),
            anchor: Anchor.topCenter);
      }
      canvas.restore();
    }
  }
}
