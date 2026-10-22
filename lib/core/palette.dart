import 'dart:ui';

/// Couleurs partagées entre le jeu, le HUD et les overlays.
abstract final class Palette {
  static const background = Color(0xFF0C0E1A);
  static const backgroundVeil = Color(0xCC0C0E1A);
  static const accent = Color(0xFF3FD1C0);
  static const textSoft = Color(0xFFAAB4E8);
  static const textMuted = Color(0xFF5A6178);
  static const surface = Color(0xFF2A2F4A);
  static const surfaceLight = Color(0xFF3D4569);
  static const inactive = Color(0xFF3A3F55);
  static const white = Color(0xFFEFFFFB);

  static const coin = Color(0xFFFFD166);
  static const coinCore = Color(0xFFF4A93D);
  static const heart = Color(0xFFE05263);
  static const gate = Color(0xFF8E5CFF);
  static const gateLine = Color(0xFFC9B2FF);

  static const doubleJump = Color(0xFF4CC9F0);
  static const dash = Color(0xFFFF8C42);
  static const wallJump = Color(0xFF7AE582);

  static const boss = Color(0xFFD64550);
}
