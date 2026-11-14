"""Outil de développement : runes gravées AU SOL (chemin d'énergie entre un mécanisme et la porte qu'il ouvre) et cadenas des portes à serrure.
Écrit dans Assets/Gemini/tuiles/ :
  - `rune_sol_1..3.png`    (16x16, transparent) : rune creusée dans la dalle, éteinte (rainure sombre + lèvre claire) ;
  - `rune_sol_on_1..3.png` (16x16, transparent) : la même rune remplie d'or (posée par-dessus quand l'énergie passe) ;
  - `cadenas.png` (10x12) : gros cadenas doré posé sur la porte de bois `E` (il saute quand on ouvre avec la clé).
Utilisées par room.gd (export `chemin_runes`) et porte.gd (activer_serrure). Indépendant des autres outils."""
import os
from PIL import Image

T = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CREUX, LEVRE = (28, 34, 52, 190), (150, 168, 196, 110)
OR, OR_CLAIR, OR_SOMBRE = (236, 180, 60, 255), (255, 232, 140, 255), (168, 112, 30, 255)

# Runes de 7x7 (# = trait), même esprit que la frise du mur (fabriquer_frise.py)
RUNES = [
    ["...#...", "..###..", ".#.#.#.", "#..#..#", "...#...", "..#.#..", ".#...#."],
    ["#.....#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.....#"],
    ["..###..", ".#...#.", "#..#..#", "#.###.#", "#..#..#", ".#...#.", "..###.."],
]


def cercle():
    """Anneau octogonal autour de la rune (centre (7,7), coins coupés)."""
    pts = []
    for y in range(15):
        for x in range(15):
            dx, dy = abs(x - 7), abs(y - 7)
            d = max(dx, dy, (dx + dy) * 0.72)
            if 6.0 <= d < 7.0:
                pts.append((x, y))
    return pts


def tuile(rune, on):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    traits = cercle()
    for j, ligne in enumerate(RUNES[rune]):
        for i, c in enumerate(ligne):
            if c == "#":
                traits.append((4 + i, 4 + j))
    traits = [(x, y) for x, y in traits if 0 <= x < 16 and 0 <= y < 15]
    for x, y in traits:
        if on:
            im.putpixel((x, y), OR_CLAIR if y < 6 else OR)
            if y + 1 < 16 and (x, y + 1) not in traits:
                im.putpixel((x, y + 1), OR_SOMBRE)
        else:
            im.putpixel((x, y), CREUX)
            if y + 1 < 16 and (x, y + 1) not in traits:
                im.putpixel((x, y + 1), LEVRE)
    return im


for k in range(3):
    tuile(k, False).save(os.path.join(T, "rune_sol_%d.png" % (k + 1)))
    tuile(k, True).save(os.path.join(T, "rune_sol_on_%d.png" % (k + 1)))

# --- Cadenas 10x12 : anse d'acier + corps doré + trou de serrure
C = Image.new("RGBA", (10, 12), (0, 0, 0, 0))
ACIER, ACIER_C, NOIR = (120, 128, 146, 255), (200, 208, 224, 255), (30, 22, 18, 255)
for y in range(0, 6):
    for x in (2, 7):
        C.putpixel((x, y), ACIER_C if x == 2 else ACIER)
for x in range(3, 7):
    C.putpixel((x, 0), ACIER_C)
for y in range(5, 12):
    for x in range(0, 10):
        bord = x in (0, 9) or y in (5, 11)
        col = OR_SOMBRE if bord else (OR_CLAIR if y < 7 else OR)
        C.putpixel((x, y), col)
for (x, y) in [(4, 7), (5, 7), (4, 8), (5, 8), (5, 9), (5, 10)]:
    C.putpixel((x, y), NOIR)
C.save(os.path.join(T, "cadenas.png"))
print("runes au sol + cadenas écrits dans", T)
