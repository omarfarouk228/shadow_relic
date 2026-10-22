import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../game/shadow_relic_game.dart';
import 'overlay_widgets.dart';

/// Écran titre posé sur le niveau qui défile en fond.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});
  final ShadowRelicGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // assombrit la gauche pour la lisibilité, laisse voir le niveau
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xF00E0B1E),
                  Color(0x990E0B1E),
                  Color(0x000E0B1E)
                ],
                stops: [0, 0.45, 0.85],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE60E0B1E), Color(0x000E0B1E)],
                stops: [0, 0.3],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 24, 24, 20),
            child: LayoutBuilder(builder: (context, c) {
              final compact = c.maxHeight < 420;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  PopIn(
                    child: GameTitle('SHADOW', size: compact ? 44 : 64),
                  ),
                  PopIn(
                    delay: 0.1,
                    child: GameTitle('RELIC',
                        size: compact ? 44 : 64, color: Palette.accent),
                  ),
                  const SizedBox(height: 10),
                  PopIn(
                    delay: 0.2,
                    child: Text(
                        'Retrouve la relique gardée au sommet de la tour',
                        style: bodyStyle(compact ? 12 : 14)),
                  ),
                  SizedBox(height: compact ? 14 : 28),
                  ValueListenableBuilder<bool>(
                    valueListenable: game.saveAvailable,
                    builder: (context, hasSave, _) => PopIn(
                      delay: 0.3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PixelButton(
                            'CONTINUER',
                            primary: hasSave,
                            audio: game.audio,
                            onTap: hasSave
                                ? () => game.startGame(continueSave: true)
                                : null,
                          ),
                          PixelButton(
                            'NOUVELLE PARTIE',
                            primary: !hasSave,
                            audio: game.audio,
                            onTap: game.openHeroSelect,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!compact)
                    const Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        KeyHint('FLÈCHES', 'Bouger'),
                        KeyHint('ESPACE', 'Sauter'),
                        KeyHint('MAJ', 'Dash'),
                        KeyHint('X', 'Attaquer'),
                        KeyHint('ÉCHAP', 'Pause'),
                        KeyHint('M', 'Son'),
                        KeyHint('ENTRÉE', 'Jouer'),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Text(
                      'Graphismes, polices et bruitages : Kenney.nl (CC0)  ·  '
                      'Musique : Juhani Junkala (CC0)',
                      style: bodyStyle(10, color: Palette.textMuted)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
