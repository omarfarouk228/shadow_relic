# Shadow Relic 🗡️

Metroidvania complet en **Flutter + Flame**, 100 % graphismes procéduraux, zéro asset externe. Compile et tourne tel quel sur mobile, desktop et web.

## Lancer le jeu

```bash
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
| Pause    | Échap                 |         |

## Progression (ability gating)

1. **Double saut** (orbe cyan) : plateformes après le départ
2. Mur de 4 tuiles franchissable → plateau
3. **Dash** (orbe orange) : en hauteur, nécessite le double saut
4. Porte violette cassable au dash → couloir
5. **Wall jump** (orbe vert) : piédestal avant la tour
6. Tour verticale en wall jump → arène du **Gardien** (boss 2 phases)

## Features implémentées

- Physique custom : coyote time, jump buffering, saut variable, dash avec cooldown, wall slide/jump
- Combat : attaque mêlée, i-frames, knockback, ennemis patrouilleurs, boss avec ondes de choc et phase enragée
- Checkpoints + sauvegarde persistante (`shared_preferences`)
- Caméra à résolution fixe 640×360 avec bounds, culling des tuiles, parallaxe d'étoiles
- HUD complet : cœurs, pièces, capacités, barre de boss, bannières
- Menu / pause / victoire, contrôles tactiles intégrés

## Architecture (clean architecture)

Les dépendances vont toujours vers l'intérieur : `presentation` -> `domain` <- `data`.
Le domaine est en Dart pur (aucun import Flutter ni Flame) et testable isolément.

```
lib/
├── main.dart                        # point d'entrée
├── injection.dart                   # assemblage data -> domain -> presentation
├── core/
│   ├── constants.dart               # taille de tuile, résolution
│   └── palette.dart                 # couleurs partagées
├── domain/                          # règles du jeu, Dart pur
│   ├── entities/                    # Ability, Tile, Spawn, LevelGrid, GameProgress
│   ├── physics/collision.dart       # moteur de collision AABB sur grille
│   ├── repositories/                # contrats LevelRepository, ProgressRepository
│   └── usecases/                    # LoadLevel, Load/Save/ClearProgress
├── data/                            # implémentations concrètes
│   ├── datasources/                 # carte ASCII (124x30), parseur, shared_preferences
│   ├── models/game_progress_model.dart  # sérialisation JSON
│   └── repositories/                # AsciiLevelRepository, LocalProgressRepository
└── presentation/                    # Flutter + Flame
    ├── app.dart                     # MaterialApp + GameWidget
    ├── game/                        # ShadowRelicGame, entrées clavier / tactile
    ├── components/                  # joueur, ennemis, boss, pickups, fx, tuiles
    ├── hud/                         # HUD + contrôles tactiles
    └── overlays/                    # menu, pause, victoire
```

## Tests

```bash
flutter analyze
flutter test
```

- `test/domain` : grille et collisions
- `test/data` : parsing de la carte, sauvegarde (aller-retour, corruption)
- `test/presentation` : parties simulées sur la vraie carte (atterrissage, déplacement,
  orbe, continuer, porte cassée au dash, pics, victoire contre le Gardien)

## Idées de série de contenu

1. Setup + rendu de la map ASCII
2. Player controller : coyote time & jump buffering
3. Double saut + dash (le moment "wow")
4. Ability gating : l'essence du Metroidvania
5. Ennemis, hitboxes et i-frames
6. Boss fight à 2 phases
7. Remplacer les graphismes procéduraux par des sprites (Pixel Adventure sur itch.io)
