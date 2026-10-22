import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../domain/entities/ability.dart';
import '../../domain/entities/tile.dart';
import '../../domain/physics/collision.dart';
import '../audio/game_audio.dart';
import '../game/shadow_relic_game.dart';
import '../sprites/render_utils.dart';
import 'fx.dart';

class Player extends PositionComponent with HasGameReference<ShadowRelicGame> {
  Player({required Vector2 position})
      : super(position: position, size: Vector2(14, 16));

  // --- physique (réglée en unités 32 px, voir kScale) ---
  static const gravity = 1500.0 * kScale;
  static const maxFall = 540.0 * kScale;
  static const moveSpeed = 165.0 * kScale;
  static const jumpVel = -470.0 * kScale;
  static const jumpCutVel = -140.0 * kScale;
  static const coyoteTime = 0.10;
  static const jumpBufferTime = 0.14;
  static const dashSpeed = 460.0 * kScale;
  static const dashDuration = 0.16;
  static const dashCooldown = 0.45;
  static const wallSlideMax = 90.0 * kScale;
  static const wallJumpVx = 235.0 * kScale;
  static const wallJumpVy = -440.0 * kScale;
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

  // --- rendu ---
  double _time = 0;
  double _stretch = 0; // > 0 : étiré (saut), < 0 : écrasé (atterrissage)
  double _ghostTimer = 0;
  double _dustTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.playing) return;
    if (dt > 0.05) dt = 0.05;
    _time += dt;
    final input = game.input;

    _coyote = math.max(0, _coyote - dt);
    _jumpBuffer = math.max(0, _jumpBuffer - dt);
    _dashCd = math.max(0, _dashCd - dt);
    _invuln = math.max(0, _invuln - dt);
    _attackTimer = math.max(0, _attackTimer - dt);
    _wallLock = math.max(0, _wallLock - dt);
    _stretch *= math.exp(-14 * dt);

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
        game.audio.play(Sfx.jump);
      } else if (_wallSliding && game.abilities.contains(Ability.wallJump)) {
        // wall jump : on repousse du mur
        vel.y = wallJumpVy;
        vel.x = -_wallDir * wallJumpVx;
        facing = -_wallDir;
        _wallLock = wallJumpLock;
        _jumpBuffer = 0;
        _stretch = 0.3;
        game.audio.play(Sfx.wallJump);
        game.world.add(
            Poof(position: position + Vector2(_wallDir > 0 ? width : 0, 8))
              ..priority = 5);
      } else if (_airJumpsLeft > 0 &&
          game.abilities.contains(Ability.doubleJump)) {
        _airJumpsLeft--;
        _doJump();
        game.audio.play(Sfx.doubleJump);
        game.world.add(Poof(position: position + Vector2(width / 2, height))
          ..priority = 5);
      }
    }
    // saut variable : relâcher = coupe l'ascension
    if (!input.jumpHeld && vel.y < jumpCutVel && !dashing) vel.y = jumpCutVel;

    // ----- dash -----
    if (input.consumeDash() &&
        game.abilities.contains(Ability.dash) &&
        _dashCd <= 0 &&
        !dashing) {
      _dashTimer = dashDuration;
      _dashCd = dashCooldown;
      _stretch = -0.25;
      game.shake(1.5, 0.12);
      game.audio.play(Sfx.dash);
      game.world.add(
          Poof(position: position + Vector2(width / 2, height))..priority = 5);
    }
    if (dashing) {
      _dashTimer -= dt;
      vel.x = facing * dashSpeed;
      vel.y = 0;
      _ghostTimer -= dt;
      if (_ghostTimer <= 0) {
        _ghostTimer = 0.03;
        game.world.add(Afterimage(
          position: position + Vector2(width / 2, height),
          sprite: game.sprites.playerFrames[1],
          flip: facing < 0,
        ));
      }
    } else {
      // gravité
      vel.y = math.min(vel.y + gravity * dt, maxFall);
    }

    // ----- wall slide -----
    _wallSliding = false;
    if (!onGround && vel.y > 0 && game.abilities.contains(Ability.wallJump)) {
      if (input.right && _touchingWall(1)) {
        _wallSliding = true;
        _wallDir = 1;
      } else if (input.left && _touchingWall(-1)) {
        _wallSliding = true;
        _wallDir = -1;
      }
      if (_wallSliding) {
        vel.y = math.min(vel.y, wallSlideMax);
        _dustTimer -= dt;
        if (_dustTimer <= 0) {
          _dustTimer = 0.12;
          game.world.add(Poof(
            position: position + Vector2(_wallDir > 0 ? width : 0, height - 2),
            small: true,
          )..priority = 5);
        }
      }
    }

    // ----- attaque -----
    if (input.consumeAttack() && _attackTimer <= 0) {
      _attackTimer = 0.22;
      _hitThisSwing.clear();
      game.world.add(SlashFx(owner: this, dir: facing));
      game.audio.play(Sfx.swing);
    }
    if (_attackTimer > 0.06) _applySlashDamage();

    // ----- collisions -----
    final fallSpeed = vel.y;
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
      if (!onGround && fallSpeed > 120 * kScale) {
        _stretch = -0.35 * (fallSpeed / maxFall).clamp(0.4, 1.0);
        game.audio.play(Sfx.land);
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
    _stretch = 0.3;
  }

  bool _touchingWall(int dir) {
    final x = dir > 0 ? position.x + width + 1 : position.x - 1;
    final cx = (x / kTile).floor();
    final cy1 = ((position.y + 2) / kTile).floor();
    final cy2 = ((position.y + height - 2) / kTile).floor();
    for (var cy = cy1; cy <= cy2; cy++) {
      if (game.grid.isSolid(cx, cy)) return true;
    }
    return false;
  }

  Rect get slashRect {
    const w = 30.0 * kScale, h = 26.0 * kScale;
    final x = facing > 0 ? position.x + width : position.x - w;
    return Rect.fromLTWH(x, position.y, w, h);
  }

  void _applySlashDamage() {
    final r = slashRect;
    for (final e in game.enemies.toList()) {
      if (e.isRemoved || _hitThisSwing.contains(e)) continue;
      if (r.overlaps(e.toRect())) {
        _hitThisSwing.add(e);
        e.takeHit(1, facing.toDouble());
        game.hitStop(0.05);
        game.shake(1.5, 0.1);
      }
    }
    final b = game.boss;
    if (b != null &&
        !b.isRemoved &&
        !_hitThisSwing.contains(b) &&
        r.overlaps(b.toRect())) {
      _hitThisSwing.add(b);
      if (b.takeHit(1)) {
        game.hitStop(0.05);
        game.shake(2, 0.12);
      }
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
    vel.x = dir * 220 * kScale;
    vel.y = -260 * kScale;
    _wallLock = 0.2;
    game.hitStop(0.08);
    game.shake(3, 0.25);
    game.audio.play(Sfx.hurt);
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.heart,
      count: 10,
    )..priority = 5);
    if (hp <= 0) _die();
  }

  void _hazardHit() {
    if (_invuln > 0) return;
    hp--;
    _invuln = 1.1;
    game.shake(3, 0.2);
    game.audio.play(Sfx.hurt);
    if (hp <= 0) {
      _die();
    } else {
      _respawn(); // les pics renvoient au checkpoint (style Hollow Knight)
    }
  }

  void _die() {
    game.world.add(ParticleBurst(
      position: position + size / 2,
      color: Palette.accent,
      count: 24,
      speed: 200,
    )..priority = 5);
    hp = maxHp;
    game.boss?.resetFight();
    game.onPlayerDeath();
    _respawn();
  }

  void _respawn() {
    position.setFrom(game.respawnPoint);
    vel.setZero();
    _dashTimer = 0;
    game.world.add(
        Poof(position: position + Vector2(width / 2, height))..priority = 5);
  }

  @override
  void render(Canvas canvas) {
    // clignote pendant l'invulnérabilité
    if (_invuln > 0 && (_time * 14).floor().isEven) return;

    final frames = game.sprites.playerFrames;
    final moving = vel.x.abs() > 1;
    final frame = !onGround || dashing
        ? frames[1]
        : moving
            ? frames[(_time * 9).floor() % 2]
            : frames[0];

    // respiration au repos, squash & stretch sinon
    final idle = onGround && !moving ? math.sin(_time * 3) * 0.03 : 0.0;
    final sy = 1 + _stretch + idle;
    final sx = 1 - _stretch * 0.6;

    // ombre portée
    if (onGround) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(width / 2, height), width: 14, height: 3),
        Paint()..color = const Color(0x55000000),
      );
    }
    final tilt = _wallSliding || dashing
        ? 0.0
        : (vel.x / moveSpeed).clamp(-1.0, 1.0) * 0.06;
    canvas.save();
    canvas.translate(width / 2, height);
    canvas.rotate(tilt);
    renderSpriteBottom(canvas, frame, 0, 0,
        flip: facing < 0, scaleX: sx, scaleY: sy);
    canvas.restore();
  }
}
