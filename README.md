# Shadow Relic 🗡️

Metroidvania complet en **Flutter + Flame**, en pixel art, avec 3 héros jouables, bruitages et
musique chiptune (assets CC0 : Kenney, PixiVan, DezrasDragons, Juhani Junkala).
Compile et tourne tel quel sur mobile, desktop et web.

![Écran titre](docs/screenshots/menu.png)

| Choix du héros | Exploration | Le Gardien |
|---|---|---|
| ![Héros](docs/screenshots/heros.png) | ![Niveau](docs/screenshots/niveau.png) | ![Boss](docs/screenshots/boss.png) |

## Lancer le jeu

```bash
flutter pub get
flutter run -d macos     # ou : -d chrome, un téléphone, etc.
```

## Contrôles

| Action   | Clavier               | Tactile (mobile)   |
|----------|-----------------------|--------------------|
| Bouger   | Flèches / WASD / ZQSD | ◀ ▶                |
| Sauter   | Espace / ↑ / Z / W    | bouton saut        |
| Dash     | Maj / C               | bouton dash        |
| Attaquer | X / J                 | bouton attaque     |
| Pause    | Échap / P             |                    |
| Son      | M                     | (menu pause)       |
| Jouer    | Entrée (menu)         |                    |

## Personnages

| Héros | Vie | Points forts |
|---|---|---|
| **Le Chevalier** | 6 | robuste, un peu plus lent |
| **Le Samouraï** | 5 | katana à grande allonge |
| **Le Ninja** | 4 | le plus rapide, dash qui recharge vite |

Le héros se choisit au lancement d'une nouvelle partie et suit la sauvegarde.

## Progression (ability gating)

1. **Double saut** (gemme bleue) : plateformes après le départ
2. Mur de 4 tuiles franchissable → plateau
3. **Dash** (gemme orange) : en hauteur, nécessite le double saut
4. Caisses industrielles brisées au dash → couloir
5. **Saut mural** (gemme verte) : piédestal avant la tour
6. Tour verticale en saut mural → arène du **Gardien** (boss 2 phases)

## Fonctionnalités

- **Physique** : coyote time, jump buffering, saut variable, dash avec cooldown, glissade et saut mural
- **Combat** : attaque mêlée, i-frames, recul, ennemis patrouilleurs, boss avec ondes de choc et phase enragée
- **Game feel** : squash & stretch, images rémanentes du dash, hit-stop, secousses de caméra,
  caméra lissée qui anticipe le regard, poussière, particules et halos lumineux
- **Décor** : ciel de crépuscule, lune, étoiles scintillantes, 3 couches de parallaxe,
  raccords d'herbe automatiques, ombrage en profondeur, décorations générées
- **Interface** : choix du héros avec aperçu animé et statistiques, écran titre sur le niveau
  qui défile en démo, pause floutée avec statistiques, écran de victoire (pièces, temps, morts),
  HUD pixel art, barre de vie du boss (points de vie, phase), bannières animées,
  contrôles tactiles uniquement sur mobile
- **Son** : musiques chiptune en boucle (menu, niveau, boss), 24 bruitages (sauts, dash,
  coups, pièces, checkpoints, boss, interface), son coupable et réglage conservé
- **Sauvegarde** : capacités, pièces ramassées, checkpoints allumés, morts et temps de jeu
  (`shared_preferences`)

## Architecture (clean architecture)

Les dépendances vont toujours vers l'intérieur : `presentation` -> `domain` <- `data`.
Le domaine est en Dart pur (aucun import Flutter ni Flame) et testable isolément.

```
lib/
├── main.dart                        # point d'entrée
├── injection.dart                   # assemblage data -> domain -> presentation
├── core/
│   ├── constants.dart               # tuile 18 px, échelle, résolution 480x270
│   └── palette.dart                 # couleurs partagées
├── domain/                          # règles du jeu, Dart pur
│   ├── entities/                    # Ability, HeroClass, Tile, Spawn, LevelGrid, GameProgress
│   ├── physics/collision.dart       # moteur de collision AABB sur grille
│   ├── repositories/                # contrats Level, Progress, Settings
│   └── usecases/                    # niveau, progression, réglage du son
├── data/                            # implémentations concrètes
│   ├── datasources/                 # carte ASCII (124x30), parseur, shared_preferences
│   ├── models/game_progress_model.dart  # sérialisation JSON versionnée
│   └── repositories/                # AsciiLevelRepository, LocalProgressRepository
└── presentation/                    # Flutter + Flame
    ├── app.dart                     # MaterialApp + GameWidget
    ├── game/                        # ShadowRelicGame, caméra, entrées clavier / tactile
    ├── audio/                       # GameAudio (flame_audio) + version silencieuse
    ├── sprites/                     # découpe des planches Kenney, helpers de rendu
    ├── components/                  # joueur, ennemis, boss, objets, fx, tuiles, décor
    ├── hud/                         # HUD + contrôles tactiles
    └── overlays/                    # menu, pause, victoire
```

## Assets

Graphismes, polices et bruitages : [Kenney](https://kenney.nl). Personnages : PixiVan et
DezrasDragons. Musique :
[Juhani Junkala](https://opengameart.org/content/4-chiptunes-adventure). Tout est en CC0,
détail dans
[`assets/CREDITS.md`](assets/CREDITS.md).

## Tests

```bash
flutter analyze
flutter test
```

- `test/domain` : grille et collisions
- `test/data` : parsing de la carte, sauvegarde (aller-retour, corruption, ancienne version)
- `test/presentation` : parties simulées sur la vraie carte (démo du menu, atterrissage,
  déplacement, orbe, pièces et checkpoints conservés, caisse brisée au dash, pics, mort,
  victoire contre le Gardien, pause et retour au menu)

## Idées de série de contenu

1. Setup + rendu de la map ASCII
2. Player controller : coyote time & jump buffering
3. Double saut + dash (le moment "wow")
4. Ability gating : l'essence du Metroidvania
5. Ennemis, hitboxes et i-frames
6. Boss fight à 2 phases
7. Passer du procédural aux sprites pixel art (Kenney) + game feel
