"""Assemble les planches de personnages (CC0) en atlas uniformes.

Chaque atlas : une ligne par animation, cellules de 48x32 px, les pieds du
personnage au point (24, 31) de chaque cellule. Ordre des lignes :
idle, run, jump, fall, attack, dash, hurt (voir HeroAnim côté Dart).

Usage : python3 tool/build_hero_atlases.py <dossier_sources> <dossier_sortie>
  <dossier_sources>/knight/  -> pack « Knight Hero Platformer » (PixiVan)
  <dossier_sources>/samurai/ -> pack « Samurai [Animated] » (DezrasDragons)
  <dossier_sources>/ninja/   -> pack « Ninja [Animated] » (DezrasDragons)
"""
import glob
import os
import sys

from PIL import Image

CELL_W, CELL_H = 48, 32
ANCHOR = (24, 31)
ROWS = ['idle', 'run', 'jump', 'fall', 'attack', 'dash', 'hurt']


def strip(path, fw):
    im = Image.open(path).convert('RGBA')
    return [im.crop((i * fw, 0, i * fw + fw, im.height)) for i in range(im.width // fw)]


def numbered(folder, anim):
    files = sorted(glob.glob(f'{folder}/{anim}_*.png'),
                   key=lambda p: int(p.rsplit('_', 1)[1][:-4]))
    return [Image.open(f).convert('RGBA') for f in files]


def mask(im):
    a = im.getchannel('A').load()
    return {(x, y) for y in range(im.height) for x in range(im.width) if a[x, y] > 0}


def feet(im, x_range=None):
    """Point d'appui : bas de la silhouette, centre des pieds."""
    a = im.getchannel('A').load()
    xs = range(im.width) if x_range is None else range(*x_range)
    bottom = max(y for y in range(im.height) for x in xs if a[x, y] > 0)
    cols = [x for x in xs for y in range(bottom - 2, bottom + 1) if a[x, y] > 0]
    return (round(sum(cols) / len(cols)), bottom)


def align(ref, ref_anchor, other):
    """Ancre de [other] en cherchant le décalage qui superpose le mieux
    sa silhouette à celle de [ref] (frames de tailles différentes)."""
    mr, mo = mask(ref), mask(other)
    best, best_score = (0, 0), -1
    for dx in range(-other.width, ref.width):
        for dy in range(-other.height, ref.height):
            score = sum(1 for (x, y) in mo if (x + dx, y + dy) in mr)
            if score > best_score:
                best, best_score = (dx, dy), score
    return (ref_anchor[0] - best[0], ref_anchor[1] - best[1])


def build(anims, anchors, out):
    cols = max(len(f) for f in anims.values())
    atlas = Image.new('RGBA', (cols * CELL_W, len(ROWS) * CELL_H), (0, 0, 0, 0))
    for r, name in enumerate(ROWS):
        for c, frame in enumerate(anims[name]):
            ax, ay = anchors[name]
            atlas.alpha_composite(frame, (c * CELL_W + ANCHOR[0] - ax, r * CELL_H + ANCHOR[1] - ay))
    atlas.save(out)
    print(out, {k: len(v) for k, v in anims.items()})


def knight(src, out):
    k = f'{src}/knight/Knight Hero Platfomer/'
    idle = strip(k + 'Combat Ready Idle.png', 22)
    a = feet(idle[0])
    attack = strip(k + 'Attack 2.png', 40)
    atk_anchor = align(idle[0], a, attack[0])
    anims = {
        'idle': idle,
        'run': strip(k + 'Run.png', 22),
        'jump': strip(k + 'Jump.png', 22),
        'fall': strip(k + 'Fall.png', 22),
        'attack': attack[1:8],
        'dash': strip(k + 'Roll.png', 22)[1:8],
        'hurt': strip(k + 'Hit Front.png', 22)[1:4],
    }
    anchors = {n: a for n in ROWS}
    anchors['attack'] = atk_anchor
    build(anims, anchors, out)


def dezras(folder, out, attack_frames):
    idle = numbered(f'{folder}/1x', 'idle')
    a = feet(idle[0], (12, 28))
    jump = numbered(f'{folder}/1x', 'jump')
    run = numbered(f'{folder}/1x', 'run')
    x = numbered(f'{folder}/1x', 'x')
    anims = {
        'idle': idle,
        'run': run,
        'jump': jump[:2],
        'fall': jump[2:],
        'attack': [numbered(f'{folder}/1x', 'attack')[i] for i in attack_frames],
        'dash': [run[3], run[4]],
        'hurt': [x[1]],
    }
    build(anims, {n: a for n in ROWS}, out)


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    knight(src, f'{dst}/knight.png')
    dezras(f'{src}/samurai', f'{dst}/samurai.png', [3, 4, 5, 6, 7])
    dezras(f'{src}/ninja', f'{dst}/ninja.png', [0, 1, 2])
