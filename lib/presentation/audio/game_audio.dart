import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Bruitages : le nom de l'enum = fichier `assets/audio/sfx/<nom>.mp3`.
enum Sfx {
  jump('jump', 0.55),
  doubleJump('double_jump', 0.55),
  wallJump('wall_jump', 0.55),
  dash('dash', 0.5),
  swing('swing', 0.35),
  hit('hit', 0.8),
  enemyDie('enemy_die', 0.6),
  hurt('hurt', 0.9),
  land('land', 0.35),
  coin('coin', 0.5),
  heart('heart', 0.6),
  ability('ability', 0.8),
  checkpoint('checkpoint', 0.6),
  crate('crate', 0.8),
  bossLand('boss_land', 0.9),
  bossHit('boss_hit', 0.7),
  bossAppear('boss_appear', 0.8),
  bossDie('boss_die', 0.9),
  victory('victory', 0.8),
  death('death', 0.7),
  uiHover('ui_hover', 0.5),
  uiConfirm('ui_confirm', 0.6),
  uiOpen('ui_open', 0.6),
  uiClose('ui_close', 0.6);

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

/// Musiques en boucle : `assets/audio/music/<nom>.mp3`.
enum Music { menu, level, boss }

abstract interface class GameAudio {
  Future<void> load();
  void play(Sfx sfx);
  void playMusic(Music music);
  void stopMusic();
  void pauseMusic();
  void resumeMusic();

  /// Coupe ou rétablit tout le son.
  ValueListenable<bool> get muted;
  void setMuted(bool value);
}

/// Pour les tests et les plateformes sans audio.
class SilentGameAudio implements GameAudio {
  final _muted = ValueNotifier(false);

  @override
  Future<void> load() async {}
  @override
  void play(Sfx sfx) {}
  @override
  void playMusic(Music music) {}
  @override
  void stopMusic() {}
  @override
  void pauseMusic() {}
  @override
  void resumeMusic() {}
  @override
  ValueListenable<bool> get muted => _muted;
  @override
  void setMuted(bool value) => _muted.value = value;
}

/// Implémentation flame_audio. Aucune erreur audio ne doit faire planter le
/// jeu (navigateur qui bloque l'autoplay, périphérique absent...) : tout est
/// rattrapé et ignoré.
class FlameGameAudio implements GameAudio {
  static const _musicVolume = 0.4;

  final Map<Sfx, AudioPool> _pools = {};
  final Map<Sfx, int> _lastPlayed = {};
  final _muted = ValueNotifier(false);
  final _clock = Stopwatch()..start();
  Music? _music;
  bool _musicPaused = false;

  @override
  ValueListenable<bool> get muted => _muted;

  @override
  Future<void> load() async {
    FlameAudio.bgm.initialize();
    await Future.wait(Sfx.values.map((s) async {
      try {
        _pools[s] = await FlameAudio.createPool('sfx/${s.file}.mp3',
            minPlayers: 1, maxPlayers: 3);
      } catch (e) {
        debugPrint('Audio : ${s.file} indisponible ($e)');
      }
    }));
  }

  @override
  void play(Sfx sfx) {
    if (_muted.value) return;
    // anti-mitraillage : un même son au plus toutes les 50 ms
    final now = _clock.elapsedMilliseconds;
    if (now - (_lastPlayed[sfx] ?? -1000) < 50) return;
    _lastPlayed[sfx] = now;
    _guard(_pools[sfx]?.start(volume: sfx.volume));
  }

  @override
  void playMusic(Music music) {
    if (_music == music && !_musicPaused) return;
    _music = music;
    _musicPaused = false;
    if (_muted.value) return;
    _guard(
        FlameAudio.bgm.play('music/${music.name}.mp3', volume: _musicVolume));
  }

  @override
  void stopMusic() {
    _music = null;
    _guard(FlameAudio.bgm.stop());
  }

  @override
  void pauseMusic() {
    _musicPaused = true;
    _guard(FlameAudio.bgm.pause());
  }

  @override
  void resumeMusic() {
    _musicPaused = false;
    if (_muted.value || _music == null) return;
    _guard(FlameAudio.bgm.resume());
  }

  @override
  void setMuted(bool value) {
    if (_muted.value == value) return;
    _muted.value = value;
    if (value) {
      _guard(FlameAudio.bgm.stop());
    } else if (_music != null && !_musicPaused) {
      final m = _music!;
      _music = null;
      playMusic(m);
    }
  }

  void _guard(Future<void>? f) {
    f?.catchError((Object e) => debugPrint('Audio : $e'));
  }
}
