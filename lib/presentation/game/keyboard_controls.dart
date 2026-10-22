import 'package:flutter/services.dart';

import 'input_state.dart';

const _left = [
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyQ, // AZERTY
];
const _right = [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD];
const _jump = [
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyZ, // AZERTY
];
const _dash = [
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.keyC,
];
const _attack = [LogicalKeyboardKey.keyX, LogicalKeyboardKey.keyJ];

/// Met à jour [input] depuis le clavier.
/// Retourne vrai si la touche pause vient d'être pressée.
bool applyKeyboard(
  InputState input,
  KeyEvent event,
  Set<LogicalKeyboardKey> keysPressed,
) {
  bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);

  input.kbLeft = any(_left);
  input.kbRight = any(_right);
  input.kbJumpHeld = any(_jump);

  if (event is! KeyDownEvent) return false;
  final k = event.logicalKey;
  if (_jump.contains(k)) input.jumpQueued = true;
  if (_dash.contains(k)) input.dashQueued = true;
  if (_attack.contains(k)) input.attackQueued = true;
  return k == LogicalKeyboardKey.escape;
}
