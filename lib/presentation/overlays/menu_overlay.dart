import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      children: [
        const Text('SHADOW RELIC',
            style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Palette.accent)),
        const SizedBox(height: 6),
        const Text('Un Metroidvania en Flutter + Flame',
            style: TextStyle(color: Palette.textSoft)),
        const SizedBox(height: 28),
        OverlayButton(
            'NOUVELLE PARTIE', () => game.startGame(continueSave: false)),
        OverlayButton('CONTINUER', () => game.startGame(continueSave: true),
            primary: false),
        const SizedBox(height: 22),
        const Text(
          'Flèches / ZQSD : bouger      Espace : sauter\n'
          'Maj : dash      X : attaquer      Échap : pause',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.textMuted, fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}
