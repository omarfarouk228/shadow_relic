import 'package:vector_math/vector_math.dart';

import '../../domain/entities/ability.dart';
import '../../domain/entities/game_progress.dart';

/// Sérialisation JSON de [GameProgress].
abstract final class GameProgressModel {
  static Map<String, dynamic> toJson(GameProgress p) => {
        'abilities': p.abilities.map((a) => a.name).toList(),
        if (p.respawn != null) 'respawn': [p.respawn!.x, p.respawn!.y],
        'coins': p.coins,
      };

  /// Lève une exception si le format est invalide.
  static GameProgress fromJson(Map<String, dynamic> json) {
    final r = json['respawn'] as List?;
    return GameProgress(
      abilities: {
        for (final n in (json['abilities'] as List? ?? const []))
          Ability.values.byName(n as String),
      },
      respawn: r == null
          ? null
          : Vector2((r[0] as num).toDouble(), (r[1] as num).toDouble()),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
    );
  }
}
