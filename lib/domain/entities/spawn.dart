import 'ability.dart';

enum SpawnType {
  player,
  checkpoint,
  coin,
  heart,
  doubleJumpOrb,
  dashOrb,
  wallJumpOrb,
  enemy,
  boss;

  /// Capacité accordée par une orbe, null pour les autres types.
  Ability? get ability => switch (this) {
        SpawnType.doubleJumpOrb => Ability.doubleJump,
        SpawnType.dashOrb => Ability.dash,
        SpawnType.wallJumpOrb => Ability.wallJump,
        _ => null,
      };
}

/// Point d'apparition d'une entité, en coordonnées de cellule.
class Spawn {
  const Spawn(this.type, this.cx, this.cy);

  final SpawnType type;
  final int cx;
  final int cy;

  /// Identifiant stable, utilisé pour sauvegarder ce qui a été ramassé.
  int get id => cy * 10000 + cx;
}
