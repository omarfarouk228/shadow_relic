import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/mv_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ShadowRelicApp());
}

class ShadowRelicApp extends StatelessWidget {
  const ShadowRelicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow Relic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget<MvGame>.controlled(
          gameFactory: MvGame.new,
          initialActiveOverlays: const ['menu'],
          overlayBuilderMap: {
            'menu': (context, game) => _MenuOverlay(game: game),
            'pause': (context, game) => _PauseOverlay(game: game),
            'victory': (context, game) => _VictoryOverlay(game: game),
          },
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC0C0E1A),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(this.label, this.onTap, {this.primary = true});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor:
              primary ? const Color(0xFF3FD1C0) : const Color(0xFF2A2F4A),
          foregroundColor:
              primary ? const Color(0xFF0C0E1A) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({required this.game});
  final MvGame game;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        const Text('SHADOW RELIC',
            style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Color(0xFF3FD1C0))),
        const SizedBox(height: 6),
        const Text('Un Metroidvania en Flutter + Flame',
            style: TextStyle(color: Color(0xFFAAB4E8))),
        const SizedBox(height: 28),
        _Btn('NOUVELLE PARTIE', () => game.startGame(continueSave: false)),
        _Btn('CONTINUER', () => game.startGame(continueSave: true),
            primary: false),
        const SizedBox(height: 22),
        const Text(
          'Flèches / ZQSD : bouger      Espace : sauter\n'
          'Maj : dash      X : attaquer      Échap : pause',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5A6178), fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.game});
  final MvGame game;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        const Text('PAUSE',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 20),
        _Btn('REPRENDRE', game.togglePause),
        _Btn('MENU PRINCIPAL', game.restart, primary: false),
      ],
    );
  }
}

class _VictoryOverlay extends StatelessWidget {
  const _VictoryOverlay({required this.game});
  final MvGame game;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        const Text('RELIQUE RÉCUPÉRÉE',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Color(0xFFFFD166))),
        const SizedBox(height: 10),
        Text('Le Gardien est vaincu — ${game.coins} pièces récoltées',
            style: const TextStyle(color: Color(0xFFAAB4E8))),
        const SizedBox(height: 24),
        _Btn('REJOUER', () async {
          await game.clearSave();
          await game.restart();
        }),
      ],
    );
  }
}
