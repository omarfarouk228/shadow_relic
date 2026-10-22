import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/shadow_relic_game.dart';
import 'overlays/menu_overlay.dart';
import 'overlays/overlay_ids.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/victory_overlay.dart';

class ShadowRelicApp extends StatelessWidget {
  const ShadowRelicApp({super.key, required this.gameFactory});

  final ShadowRelicGame Function() gameFactory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow Relic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget<ShadowRelicGame>.controlled(
          gameFactory: gameFactory,
          initialActiveOverlays: const [Overlays.menu],
          overlayBuilderMap: {
            Overlays.menu: (context, game) => MenuOverlay(game: game),
            Overlays.pause: (context, game) => PauseOverlay(game: game),
            Overlays.victory: (context, game) => VictoryOverlay(game: game),
          },
        ),
      ),
    );
  }
}
