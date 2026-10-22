import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    return BlurVeil(
      child: PopIn(
        child: GamePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSE', style: titleStyle(36)),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatTile(
                      label: 'Pièces',
                      value: '${p.coins}/${game.totalCoins}',
                      color: Palette.gold),
                  const SizedBox(width: 10),
                  StatTile(
                      label: 'Temps',
                      value: formatPlayTime(p.playTime),
                      color: Palette.accent),
                  const SizedBox(width: 10),
                  StatTile(
                      label: 'Morts',
                      value: '${p.deaths}',
                      color: Palette.danger),
                ],
              ),
              const SizedBox(height: 18),
              PixelButton('REPRENDRE', primary: true, onTap: game.togglePause),
              ValueListenableBuilder<bool>(
                valueListenable: game.audio.muted,
                builder: (context, muted, _) => PixelButton(
                  muted ? 'SON : COUPÉ' : 'SON : ACTIVÉ',
                  audio: game.audio,
                  onTap: game.toggleMute,
                ),
              ),
              PixelButton('MENU PRINCIPAL',
                  audio: game.audio, onTap: game.backToMenu),
            ],
          ),
        ),
      ),
    );
  }
}
