import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/palette.dart';
import '../../domain/entities/hero_class.dart';
import '../audio/game_audio.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/hero_sprites.dart';
import 'overlay_widgets.dart';

/// Écran « Choisis ton héros » avant une nouvelle partie.
class HeroSelectOverlay extends StatelessWidget {
  const HeroSelectOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    return BlurVeil(
      opacity: 0.75,
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxHeight < 480;
        final cardW = ((c.maxWidth - 80) / 3).clamp(150.0, 270.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                child: GameTitle('CHOISIS TON HÉROS', size: compact ? 30 : 44),
              ),
              SizedBox(height: compact ? 12 : 28),
              ValueListenableBuilder<HeroClass>(
                valueListenable: game.selectedHero,
                builder: (context, selected, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, h) in HeroClass.values.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: PopIn(
                          delay: 0.1 + i * 0.08,
                          child: _HeroCard(
                            game: game,
                            hero: h,
                            selected: h == selected,
                            width: cardW,
                            compact: compact,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 20),
              PopIn(
                delay: 0.4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PixelButton('RETOUR',
                        width: 180,
                        audio: game.audio,
                        onTap: game.closeHeroSelect),
                    const SizedBox(width: 16),
                    PixelButton('JOUER',
                        primary: true,
                        width: 220,
                        audio: game.audio,
                        onTap: () => game.startGame(continueSave: false)),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 18,
                  children: [
                    KeyHint('FLÈCHES', 'Choisir'),
                    KeyHint('ENTRÉE', 'Jouer'),
                    KeyHint('ÉCHAP', 'Retour'),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({
    required this.game,
    required this.hero,
    required this.selected,
    required this.width,
    required this.compact,
  });

  final ShadowRelicGame game;
  final HeroClass hero;
  final bool selected;
  final double width;
  final bool compact;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hero;
    final sel = widget.selected;
    final accent = h.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          if (sel) {
            widget.game.startGame(continueSave: false);
          } else {
            widget.game.selectedHero.value = h;
            widget.game.audio.play(Sfx.uiHover);
          }
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: sel ? 1.04 : (_hover ? 1.01 : 0.97),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: sel || _hover ? 1 : 0.62,
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? accent : Palette.outline,
                  width: sel ? 3 : 2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(Palette.panelLight, accent, sel ? 0.18 : 0)!,
                    Palette.panel,
                  ],
                ),
                boxShadow: [
                  if (sel)
                    BoxShadow(
                        color: accent.withValues(alpha: 0.35), blurRadius: 30),
                  const BoxShadow(
                      color: Color(0xAA000000), offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: widget.compact ? 96 : 150,
                    width: double.infinity,
                    child: _HeroPreview(
                      sprites: widget.game.heroSprites[h]!,
                      active: sel,
                      glow: accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(h.displayName,
                      style: titleStyle(widget.compact ? 15 : 19,
                          color: sel ? accent : Palette.white)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: widget.compact ? 30 : 36,
                    child: Text(h.tagline,
                        style: bodyStyle(widget.compact ? 10 : 12)),
                  ),
                  const SizedBox(height: 8),
                  _StatBar('VIE', h.maxHp / 6, accent),
                  _StatBar('VITESSE', (h.speed - 0.75) / 0.4, accent),
                  _StatBar('PORTÉE', (h.reach - 0.65) / 0.7, accent),
                  _StatBar('DASH', (0.6 - h.dashCooldown) / 0.32, accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jauge à 6 segments, façon jeu.
class _StatBar extends StatelessWidget {
  const _StatBar(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 6).round().clamp(1, 6);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: bodyStyle(10, color: Palette.textMuted)),
          ),
          for (var i = 0; i < 6; i++)
            Expanded(
              child: Container(
                height: 7,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < filled ? color : Palette.background,
                  border: Border.all(color: Palette.outline, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Personnage animé en grand. Sélectionné, il enchaîne repos, attaque et
/// course ; sinon il reste au repos.
class _HeroPreview extends StatefulWidget {
  const _HeroPreview({
    required this.sprites,
    required this.active,
    required this.glow,
  });

  final HeroSprites sprites;
  final bool active;
  final Color glow;

  @override
  State<_HeroPreview> createState() => _HeroPreviewState();
}

class _HeroPreviewState extends State<_HeroPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMicroseconds / 1e6);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Sprite get _frame {
    final s = widget.sprites;
    if (!widget.active) return s.frameAt(HeroAnim.idle, _t, fps: 6);
    final cycle = _t % 3.2;
    if (cycle < 1.2) return s.frameAt(HeroAnim.idle, cycle, fps: 6);
    if (cycle < 1.6) {
      final n = s.hero.frameCounts[HeroAnim.attack]!;
      return s.frameAt(HeroAnim.attack, cycle - 1.2, fps: n / 0.4, loop: false);
    }
    return s.frameAt(HeroAnim.run, cycle - 1.6, fps: 12);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PreviewPainter(_frame, widget.glow, widget.active),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.frame, this.glow, this.active);
  final Sprite frame;
  final Color glow;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = (size.height / HeroSprites.cellH * 0.95).floorToDouble();
    final feet = Offset(size.width / 2, size.height - 10);
    // socle lumineux
    canvas.drawOval(
      Rect.fromCenter(center: feet, width: size.width * 0.7, height: 16),
      Paint()
        ..shader = RadialGradient(colors: [
          glow.withValues(alpha: active ? 0.55 : 0.2),
          glow.withValues(alpha: 0),
        ]).createShader(
            Rect.fromCenter(center: feet, width: size.width * 0.7, height: 16)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: feet, width: 60, height: 8),
      Paint()..color = const Color(0x66000000),
    );
    HeroSprites.render(canvas, frame, feet.dx, feet.dy, zoom: zoom);
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.frame != frame || old.active != active;
}
