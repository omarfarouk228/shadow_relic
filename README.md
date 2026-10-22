# Shadow Relic 🗡️

Metroidvania complet en **Flutter + Flame** — 100 % graphismes procéduraux, zéro asset externe. Compile et tourne tel quel sur mobile, desktop et web.

## Lancer le jeu

```bash
# dans le dossier shadow_relic/
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get
flutter run          # ou: flutter run -d chrome
```

## Contrôles

| Action   | Clavier               | Tactile |
|----------|-----------------------|---------|
| Bouger   | Flèches / WASD / ZQSD | ◀ ▶     |
| Sauter   | Espace / ↑ / Z / W    | ⭡       |
| Dash     | Maj / C               | ⚡      |
| Attaquer | X / J                 | ✦       |
| Pause    | Échap                 | —       |

## Progression (ability gating)

1. **Double saut** (orbe cyan) — plateformes après le départ
2. Mur de 4 tuiles franchissable → plateau
3. **Dash** (orbe orange) — en hauteur, nécessite le double saut
4. Porte violette cassable au dash → couloir
5. **Wall jump** (orbe vert) — pedestal avant la tour
6. Tour verticale en wall jump → arène du **Gardien** (boss 2 phases)

## Features implémentées

- Physique custom : coyote time, jump buffering, saut variable, dash avec cooldown, wall slide/jump
- Combat : attaque mêlée, i-frames, knockback, ennemis patrouilleurs, boss avec ondes de choc et phase enragée
- Checkpoints + sauvegarde persistante (`shared_preferences`)
- Caméra à résolution fixe 640×360 avec bounds, culling des tuiles, parallaxe d'étoiles
- HUD complet : cœurs, pièces, capacités, barre de boss, bannières
- Menu / pause / victoire, contrôles tactiles intégrés

## Architecture

```
lib/
├── main.dart                  # app + overlays (menu, pause, victoire)
├── game/
│   ├── mv_game.dart           # FlameGame, monde, caméra, sauvegarde, clavier
│   ├── level_grid.dart        # grille de tuiles + moteur de collision AABB
│   ├── level_data.dart        # la carte du monde en ASCII (124×30)
│   └── input_state.dart       # entrées unifiées clavier + tactile
├── components/
│   ├── player.dart            # contrôleur joueur (game feel)
│   ├── enemy.dart             # patrouilleurs
│   ├── boss.dart              # le Gardien + ondes de choc
│   ├── pickups.dart           # pièces, cœurs, orbes, checkpoints
│   ├── fx.dart                # particules, slash, poofs
│   └── tile_renderer.dart     # rendu tuiles + fond étoilé
└── ui/
    └── hud.dart               # HUD + boutons tactiles
```

## Idées de série de contenu

1. Setup + rendu de la map ASCII
2. Player controller : coyote time & jump buffering
3. Double saut + dash (le moment "wow")
4. Ability gating : l'essence du Metroidvania
5. Ennemis, hitboxes et i-frames
6. Boss fight à 2 phases
7. Remplacer les graphismes procéduraux par des sprites (Pixel Adventure sur itch.io)
