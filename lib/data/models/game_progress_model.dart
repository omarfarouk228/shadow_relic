import 'package:vector_math/vector_math.dart';

import '../../domain/entities/ability.dart';
import '../../domain/entities/game_progress.dart';
import '../../domain/entities/hero_class.dart';

/// Sérialisation JSON de [GameProgress].
abstract final class GameProgressModel {
  static const version = 2;

  static Map<String, dynamic> toJson(GameProgress p) => {
        'version': version,
        'hero': p.hero.name,
        'abilities': p.abilities.map((a) => a.name).toList(),
        'coins': p.collectedCoins.toList(),
        'checkpoints': p.activatedCheckpoints.toList(),
        if (p.respawn != null) 'respawn': [p.respawn!.x, p.respawn!.y],
        'deaths': p.deaths,
        'playTime': p.playTime,
      };

  /// Lève une exception si le format est invalide. Les sauvegardes v1
  /// (coordonnées en tuiles de 32 px, pièces comptées) sont refusées.
  static GameProgress fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) {
      throw const FormatException('Version de sauvegarde incompatible');
    }
    Set<int> ints(String key) =>
        {for (final v in (json[key] as List? ?? const [])) (v as num).toInt()};
    final r = json['respawn'] as List?;
    final hero = json['hero'] as String?;
    return GameProgress(
      hero: hero == null ? HeroClass.knight : HeroClass.values.byName(hero),
      abilities: {
        for (final n in (json['abilities'] as List? ?? const []))
          Ability.values.byName(n as String),
      },
      collectedCoins: ints('coins'),
      activatedCheckpoints: ints('checkpoints'),
      respawn: r == null
          ? null
          : Vector2((r[0] as num).toDouble(), (r[1] as num).toDouble()),
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      playTime: (json['playTime'] as num?)?.toDouble() ?? 0,
    );
  }
}
