import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    final allCoins = p.coins == game.totalCoins;
    return BlurVeil(
      opacity: 0.7,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopIn(child: GameTitle('VICTOIRE', size: 56)),
            const SizedBox(height: 10),
            PopIn(
              delay: 0.15,
              child: Text('Le Gardien est vaincu. La relique est à toi.',
                  style: bodyStyle(15)),
            ),
            const SizedBox(height: 22),
            PopIn(
              delay: 0.3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatTile(
                      label: allCoins ? 'Toutes !' : 'Pièces',
                      value: '${p.coins}/${game.totalCoins}',
                      color: Palette.gold),
                  const SizedBox(width: 12),
                  StatTile(
                      label: 'Temps',
                      value: formatPlayTime(p.playTime),
                      color: Palette.accent),
                  const SizedBox(width: 12),
                  StatTile(
                      label: 'Morts',
                      value: '${p.deaths}',
                      color: Palette.danger),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PopIn(
              delay: 0.45,
              child: Column(
                children: [
                  PixelButton('REJOUER', primary: true, onTap: game.replay),
                  PixelButton('MENU PRINCIPAL', onTap: game.backToMenu),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
