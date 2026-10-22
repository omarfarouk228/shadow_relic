import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../hud/hud.dart';

/// Formate un temps de jeu en « mm:ss » (ou « h:mm:ss »).
String formatPlayTime(double seconds) {
  final s = seconds.floor();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final ss = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

TextStyle titleStyle(double size, {Color color = Palette.white}) => TextStyle(
      fontFamily: HudFonts.title,
      fontSize: size,
      color: color,
      letterSpacing: size * 0.08,
      height: 1,
    );

TextStyle bodyStyle(double size, {Color color = Palette.textSoft}) => TextStyle(
      fontFamily: HudFonts.body,
      fontSize: size,
      color: color,
      height: 1.3,
    );

/// Fond flouté + voile sombre, pour la pause et la victoire.
class BlurVeil extends StatelessWidget {
  const BlurVeil({super.key, required this.child, this.opacity = 0.6});
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Palette.background.withValues(alpha: opacity),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Apparition en fondu + léger zoom.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = 0});
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -delay, end: 1),
      duration: Duration(milliseconds: (450 * (1 + delay)).round()),
      curve: Curves.linear,
      builder: (context, v, child) {
        final t = Curves.easeOutBack.transform(v.clamp(0.0, 1.0));
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
      child: child,
    );
  }
}

/// Panneau type « fenêtre de jeu » : bord sombre, liseré clair, ombre.
class GamePanel extends StatelessWidget {
  const GamePanel({super.key, required this.child, this.accent});
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final a = accent ?? Palette.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
      decoration: BoxDecoration(
        color: Palette.panel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Palette.outline, width: 3),
        boxShadow: [
          BoxShadow(color: a.withValues(alpha: 0.25), blurRadius: 40),
          const BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.panelLight, Palette.panel],
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border:
            Border(top: BorderSide(color: a.withValues(alpha: 0.6), width: 2)),
      ),
      child: child,
    );
  }
}

/// Bouton en relief façon jeu, sans prise de focus clavier
/// (le clavier reste au jeu).
class PixelButton extends StatefulWidget {
  const PixelButton(
    this.label, {
    super.key,
    required this.onTap,
    this.primary = false,
    this.width = 260,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final double width;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final primary = widget.primary && enabled;
    final face = !enabled
        ? Palette.panel
        : primary
            ? (_hover ? const Color(0xFF7FF0DA) : Palette.accent)
            : (_hover ? Palette.panelLight : Palette.panel);
    final edge = primary ? Palette.accentDark : Palette.outline;
    final textColor = !enabled
        ? Palette.textMuted
        : primary
            ? Palette.background
            : (_hover ? Palette.white : Palette.textSoft);
    final lift = _down ? 1.0 : 5.0;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: widget.width,
          margin: EdgeInsets.only(top: 5 - lift + 6, bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: _hover && enabled && !primary
                  ? Palette.accent
                  : Palette.outline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: edge, offset: Offset(0, lift)),
              if (_hover && enabled)
                BoxShadow(
                  color: Palette.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hover && enabled ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.play_arrow_rounded,
                      size: 16, color: textColor),
                ),
              ),
              Text(widget.label, style: titleStyle(16, color: textColor)),
              const SizedBox(width: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grand titre doré avec contour et halo, qui flotte doucement.
class GameTitle extends StatefulWidget {
  const GameTitle(this.text, {super.key, this.size = 64, this.color});
  final String text;
  final double size;
  final Color? color;

  @override
  State<GameTitle> createState() => _GameTitleState();
}

class _GameTitleState extends State<GameTitle>
    with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = titleStyle(widget.size);
    final tint = widget.color ?? Palette.gold;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * math.pi * 2) * 3),
        child: child,
      ),
      child: Stack(
        children: [
          // ombre portée
          Transform.translate(
            offset: Offset(0, widget.size * 0.09),
            child:
                Text(widget.text, style: base.copyWith(color: Palette.outline)),
          ),
          // contour
          Text(
            widget.text,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = widget.size * 0.12
                ..color = Palette.outline,
              shadows: [
                Shadow(color: tint.withValues(alpha: 0.6), blurRadius: 30)
              ],
            ),
          ),
          // remplissage dégradé
          ShaderMask(
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(tint, Colors.white, 0.6)!,
                tint,
                Color.lerp(tint, Colors.black, 0.35)!
              ],
              stops: const [0, 0.55, 1],
            ).createShader(r),
            child: Text(widget.text, style: base),
          ),
        ],
      ),
    );
  }
}

/// Case de statistique (victoire, pause).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Palette.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(value, style: titleStyle(22, color: color)),
          const SizedBox(height: 6),
          Text(label, style: bodyStyle(12)),
        ],
      ),
    );
  }
}

/// Indication de touche : [ESPACE] Sauter.
class KeyHint extends StatelessWidget {
  const KeyHint(this.keyLabel, this.action, {super.key});
  final String keyLabel;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Palette.panelLight,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Palette.outline, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Palette.outline, offset: Offset(0, 2)),
            ],
          ),
          child: Text(keyLabel, style: bodyStyle(11, color: Palette.white)),
        ),
        const SizedBox(width: 6),
        Text(action, style: bodyStyle(11, color: Palette.textMuted)),
      ],
    );
  }
}
