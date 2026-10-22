import 'package:flutter/material.dart';

import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      children: [
        const Text('PAUSE',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 20),
        OverlayButton('REPRENDRE', game.togglePause),
        OverlayButton('MENU PRINCIPAL', game.backToMenu, primary: false),
      ],
    );
  }
}
