import 'dart:ui';

/// Couleurs partagées entre le jeu, le HUD et les overlays.
/// Ambiance « crépuscule » posée sur les sprites Kenney.
abstract final class Palette {
  // Ciel et décor
  static const skyTop = Color(0xFF140F2D);
  static const skyMid = Color(0xFF3B1F4E);
  static const skyHorizon = Color(0xFFB4506A);
  static const moon = Color(0xFFFFE8C2);
  static const clouds = Color(0xFF34224F);
  static const hillsFar = Color(0xFF4A2A5E);
  static const hillsNear = Color(0xFF2B1A3F);
  static const forest = Color(0xFF1B1230);

  // Interface
  static const background = Color(0xFF0E0B1E);
  static const backgroundVeil = Color(0xCC0E0B1E);
  static const panel = Color(0xFF1E1836);
  static const panelLight = Color(0xFF2E2650);
  static const outline = Color(0xFF0A0815);
  static const accent = Color(0xFF5CE1C6);
  static const accentDark = Color(0xFF2A8F80);
  static const gold = Color(0xFFFFCC4D);
  static const goldDark = Color(0xFFB57A1B);
  static const textSoft = Color(0xFFC8C2E8);
  static const textMuted = Color(0xFF7D7599);
  static const white = Color(0xFFF7F3FF);
  static const danger = Color(0xFFE5484D);
  static const dangerDark = Color(0xFF8A1F2D);

  // Gameplay
  static const coin = Color(0xFFFFCC4D);
  static const heart = Color(0xFFE5484D);
  static const gate = Color(0xFFFFA62B);
  static const doubleJump = Color(0xFF4CC9F0);
  static const dash = Color(0xFFFF8C42);
  static const wallJump = Color(0xFF7AE582);
  static const boss = Color(0xFFFFA62B);
  static const shockwave = Color(0xFFFF7A3D);
  static const enemyHit = Color(0xFF8FD3FF);
}
