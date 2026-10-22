import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      children: [
        const Text('RELIQUE RÉCUPÉRÉE',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Palette.coin)),
        const SizedBox(height: 10),
        Text('Le Gardien est vaincu. ${game.coins} pièces récoltées.',
            style: const TextStyle(color: Palette.textSoft)),
        const SizedBox(height: 24),
        OverlayButton('REJOUER', game.replay),
      ],
    );
  }
}
