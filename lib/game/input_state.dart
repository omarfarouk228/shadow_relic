/// Entrées unifiées : clavier (flèches/WASD/ZQSD) + boutons tactiles.
class InputState {
  // Maintien clavier
  bool kbLeft = false, kbRight = false, kbJumpHeld = false;
  // Maintien tactile
  bool tLeft = false, tRight = false, tJumpHeld = false;

  // Événements "un coup" (consommés par le joueur)
  bool jumpQueued = false;
  bool dashQueued = false;
  bool attackQueued = false;

  bool get left => kbLeft || tLeft;
  bool get right => kbRight || tRight;
  bool get jumpHeld => kbJumpHeld || tJumpHeld;

  bool consumeJump() {
    final v = jumpQueued;
    jumpQueued = false;
    return v;
  }

  bool consumeDash() {
    final v = dashQueued;
    dashQueued = false;
    return v;
  }

  bool consumeAttack() {
    final v = attackQueued;
    attackQueued = false;
    return v;
  }
}
