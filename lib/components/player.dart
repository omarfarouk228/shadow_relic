import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/level_grid.dart';
import '../game/mv_game.dart';
import 'boss.dart';
import 'enemy.dart';
import 'fx.dart';

class Player extends PositionComponent with HasGameReference<MvGame> {
  Player({required Vector2 position})
      : super(position: position, size: Vector2(22, 28));

  // --- physique ---
  static const gravity = 1500.0;
  static const maxFall = 540.0;
  static const moveSpeed = 165.0;
  static const jumpVel = -470.0;
  static const coyoteTime = 0.10;
  static const jumpBufferTime = 0.14;
  static const dashSpeed = 460.0;
  static const dashDuration = 0.16;
  static const dashCooldown = 0.45;
  static const wallSlideMax = 90.0;
  static const wallJumpVx = 235.0;
  static const wallJumpLock = 0.14;

  final vel = Vector2.zero();
  int facing = 1;
  bool onGround = false;
  double _coyote = 0;
  double _jumpBuffer = 0;
  int _airJumpsLeft = 0;
  double _dashTimer = 0;
  double _dashCd = 0;
  bool get dashing => _dashTimer > 0;
  double _wallLock = 0;
  bool _wallSliding = false;
  int _wallDir = 0;

  // --- combat / vie ---
  int maxHp = 5;
  int hp = 5;
  double _invuln = 0;
  double _attackTimer = 0;
  final Set<Component> _hitThisSwing = {};

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (dt > 0.05) dt = 0.05;
    _time += dt;
    final input = game.input;

    _coyote = math.max(0, _coyote - dt);
    _jumpBuffer = math.max(0, _jumpBuffer - dt);
    _dashCd = math.max(0, _dashCd - dt);
    _invuln = math.max(0, _invuln - dt);
    _attackTimer = math.max(0, _attackTimer - dt);
    _wallLock = math.max(0, _wallLock - dt);

    // ----- déplacement horizontal -----
    if (!dashing && _wallLock <= 0) {
      var dir = 0;
      if (input.left) dir -= 1;
      if (input.right) dir += 1;
      vel.x = dir * moveSpeed;
      if (dir != 0) facing = dir;
    }

    // ----- saut (buffer + coyote) -----
    if (input.consumeJump()) _jumpBuffer = jumpBufferTime;

    if (_jumpBuffer > 0) {
      if (onGround || _coyote > 0) {
        _doJump();
      } else if (_wallSliding &&
          game.abilities.contains(Ability.wallJump)) {
        // wall jump : on repousse du mur
        vel.y = -440;
        vel.x = -_wallDir * wallJumpVx;
        facing = -_wallDir;
        _wallLock = wallJumpLock;
        _jumpBuffer = 0;
        game.world.add(
            Poof(position: position + Vector2(_wallDir > 0 ? width : 0, 10))
              ..priority = 5);
      } else if (_airJumpsLeft > 0 &&
          game.abilities.contains(Ability.doubleJump)) {
        _airJumpsLeft--;
        _doJump();
        game.world
            .add(Poof(position: position + Vector2(width / 2, height))
              ..priority = 5);
      }
    }
    // saut variable : relâcher = coupe l'ascension
    if (!input.jumpHeld && vel.y < -140 && !dashing) vel.y = -140;

    // ----- dash -----
    if (input.consumeDash() &&
        game.abilities.contains(Ability.dash) &&
        _dashCd <= 0 &&
        !dashing) {
      _dashTimer = dashDuration;
      _dashCd = dashCooldown;
      game.world.add(Poof(position: position + Vector2(width / 2, height / 2))
        ..priority = 5);
    }
    if (dashing) {
      _dashTimer -= dt;
      vel.x = facing * dashSpeed;
      vel.y = 0;
    } else {
      // gravité
      vel.y = math.min(vel.y + gravity * dt, maxFall);
    }

    // ----- wall slide -----
    _wallSliding = false;
    if (!onGround &&
        vel.y > 0 &&
        game.abilities.contains(Ability.wallJump)) {
      if (input.right && _touchingWall(1)) {
        _wallSliding = true;
        _wallDir = 1;
      } else if (input.left && _touchingWall(-1)) {
        _wallSliding = true;
        _wallDir = -1;
      }
      if (_wallSliding) vel.y = math.min(vel.y, wallSlideMax);
    }

    // ----- attaque -----
    if (input.consumeAttack() && _attackTimer <= 0) {
      _attackTimer = 0.22;
      _hitThisSwing.clear();
      game.world.add(SlashFx(owner: this, dir: facing)..priority = 5);
    }
    if (_attackTimer > 0.06) _applySlashDamage();

    // ----- collisions -----
    final wasFalling = vel.y > 60;
    final hit = moveAndCollide(
      game.grid,
      position,
      size,
      vel,
      dt,
      onGateHit: (cx, cy) {
        if (!dashing) return false;
        game.grid.clearGate(cx, cy);
        game.gateBroken(
            Vector2(cx * kTile + kTile / 2, cy * kTile + kTile / 2));
        return true;
      },
    );

    if (hit.down) {
      if (wasFalling) {
        // petite poussière d'atterrissage
        game.world.add(
            Poof(position: position + Vector2(width / 2, height), small: true)
              ..priority = 5);
      }
      onGround = true;
      _coyote = coyoteTime;
      _airJumpsLeft = 1;
    } else {
      if (onGround) _coyote = coyoteTime; // vient de quitter le sol
      onGround = false;
    }
    if (hit.left || hit.right) _dashTimer = 0;

    // ----- dangers -----
    if (game.grid
        .rectTouches(position.x, position.y, width, height, Tile.spike)) {
      _hazardHit();
    }
    _checkEnemyContact();
  }

  void _doJump() {
    vel.y = jumpVel;
    _jumpBuffer = 0;
    _coyote = 0;
    onGround = false;
  }

  bool _touchingWall(int dir) {
    final x = dir > 0 ? position.x + width + 2 : position.x - 2;
    final cx = (x / kTile).floor();
    final cy1 = ((position.y + 4) / kTile).floor();
    final cy2 = ((position.y + height - 4) / kTile).floor();
    for (var cy = cy1; cy <= cy2; cy++) {
      if (game.grid.isSolid(cx, cy)) return true;
    }
    return false;
  }

  Rect get slashRect {
    const w = 30.0, h = 26.0;
    final x = facing > 0 ? position.x + width : position.x - w;
    return Rect.fromLTWH(x, position.y + 1, w, h);
  }

  void _applySlashDamage() {
    final r = slashRect;
    for (final e in game.enemies.toList()) {
      if (e.isRemoved || _hitThisSwing.contains(e)) continue;
      if (r.overlaps(e.toRect())) {
        _hitThisSwing.add(e);
        e.takeHit(1, facing.toDouble());
      }
    }
    final b = game.boss;
    if (b != null &&
        !b.isRemoved &&
        !_hitThisSwing.contains(b) &&
        r.overlaps(b.toRect())) {
      _hitThisSwing.add(b);
      b.takeHit(1);
    }
  }

  void _checkEnemyContact() {
    if (_invuln > 0) return;
    final r = toRect();
    for (final e in game.enemies) {
      if (!e.isRemoved && r.overlaps(e.toRect())) {
        takeDamage(from: e.position);
        return;
      }
    }
    final b = game.boss;
    if (b != null && b.active && !b.isRemoved) {
      if (r.overlaps(b.toRect())) {
        takeDamage(from: b.position);
        return;
      }
      for (final s in b.shockwaves.toList()) {
        if (!s.isRemoved && r.overlaps(s.toRect())) {
          takeDamage(from: s.position);
          return;
        }
      }
    }
  }

  void takeDamage({required Vector2 from}) {
    if (_invuln > 0) return;
    hp--;
    _invuln = 1.1;
    _dashTimer = 0;
    final dir = position.x < from.x ? -1 : 1;
    vel.x = dir * 220;
    vel.y = -260;
    _wallLock = 0.2;
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: const Color(0xFFE05263),
      count: 8,
    )..priority = 5);
    if (hp <= 0) _die();
  }

  void _hazardHit() {
    if (_invuln > 0) return;
    hp--;
    _invuln = 1.1;
    if (hp <= 0) {
      _die();
    } else {
      _respawn(); // les pics renvoient au checkpoint (style Hollow Knight)
    }
  }

  void _die() {
    hp = maxHp;
    game.boss?.resetFight();
    _respawn();
  }

  void _respawn() {
    position.setFrom(game.respawnPoint);
    vel.setZero();
    _dashTimer = 0;
    game.world.add(Poof(position: position + size / 2)..priority = 5);
  }

  @override
  void render(Canvas canvas) {
    // clignote pendant l'invulnérabilité
    if (_invuln > 0 && (_time * 12).floor().isEven) return;

    final body = Paint()
      ..color = dashing ? const Color(0xFF9BE8FF) : const Color(0xFF3FD1C0);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, width, height - 4),
      const Radius.circular(5),
    );
    // écharpe qui suit le mouvement
    final scarf = Paint()..color = const Color(0xFFE0B34C);
    final sway = -vel.x * 0.03 - facing * 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width / 2 - 4 + sway, 8, 9, 6),
        const Radius.circular(3),
      ),
      scarf,
    );
    canvas.drawRRect(rrect, body);
    // tête / visière
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 0, width - 6, 10),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2A9D8F),
    );
    final eyeX = facing > 0 ? width - 9.0 : 4.0;
    canvas.drawRect(
      Rect.fromLTWH(eyeX, 3, 5, 4),
      Paint()..color = const Color(0xFFEFFFFB),
    );
    if (_wallSliding) {
      canvas.drawRect(
        Rect.fromLTWH(_wallDir > 0 ? width - 2 : 0, 6, 2, height - 10),
        Paint()..color = const Color(0xFFB6FFF4),
      );
    }
  }
}
