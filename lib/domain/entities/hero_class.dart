/// Personnages jouables et leurs caractéristiques de gameplay.
enum HeroClass {
  /// Robuste mais un peu lent.
  knight(maxHp: 6, speed: 0.92, reach: 1.0, dashCooldown: 0.45),

  /// Katana : la plus grande allonge.
  samurai(maxHp: 5, speed: 1.0, reach: 1.35, dashCooldown: 0.45),

  /// Rapide, dash qui recharge vite, mais fragile.
  ninja(maxHp: 4, speed: 1.15, reach: 0.85, dashCooldown: 0.28);

  const HeroClass({
    required this.maxHp,
    required this.speed,
    required this.reach,
    required this.dashCooldown,
  });

  final int maxHp;

  /// Multiplicateur de vitesse de déplacement.
  final double speed;

  /// Multiplicateur de portée de l'attaque.
  final double reach;

  /// Délai entre deux dashs, en secondes.
  final double dashCooldown;
}
