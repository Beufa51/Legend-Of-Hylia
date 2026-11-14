"""Outil de développement : décor de mur des ailes du donjon, repris de la FAÇADE (frise de runes dorées sur la corniche, plumes de pierre).
Écrit dans Assets/Gemini/tuiles/ : `frise_runes_1..4.png` (16x7, bandeau sombre + 2 runes dorées) et `plume_pierre.png` (16x21, plume de pierre gravée dans un panneau).
Utilisées par room.gd::_poser_frise. À lancer APRÈS traiter_pack_donjon.py (ordre sans importance : n'écrase aucun autre fichier)."""
import os, math
from PIL import Image

T = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
OR, OR_CLAIR = (232, 176, 56, 255), (255, 226, 130, 255)
BANDE, BORD_H, BORD_B = (22, 28, 44, 255), (74, 88, 118, 255), (12, 15, 26, 255)

# Runes de 5x5 pixels (# = trait doré)
RUNES = [
    ["#...#", "##..#", "#.#.#", "#..##", "#...#"],
    ["..#..", ".##..", "#.#..", "..##.", "..#.."],
    ["#.#.#", ".###.", "..#..", ".#.#.", "#...#"],
    ["###..", "#..#.", "###..", "#..#.", "#..##"],
    ["..#..", "#.#.#", ".###.", "..#..", "..#.."],
    [".##.#", "#..##", "#...#", "#..#.", ".##.."],
]
# Chaque tuile = 2 runes (indices)
COMBOS = [(0, 3), (1, 4), (2, 5), (4, 0)]

def tuile(a, b):
    im = Image.new("RGBA", (16, 7), BANDE)
    for x in range(16):
        im.putpixel((x, 0), BORD_H)
        im.putpixel((x, 6), BORD_B)
    for rune, x0 in ((a, 2), (b, 9)):
        for j, ligne in enumerate(RUNES[rune]):
            for i, c in enumerate(ligne):
                if c == "#":
                    im.putpixel((x0 + i, 1 + j), OR_CLAIR if j == 0 else OR)
    return im

for k, (a, b) in enumerate(COMBOS, 1):
    tuile(a, b).save(os.path.join(T, "frise_runes_%d.png" % k))

# --- Plume de pierre gravée (16x21) : panneau sombre + plume à nervure et barbes
W, H = 16, 21
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
FOND, LISERE, PIERRE, CLAIR, OMBRE, NERV = (24, 30, 46, 255), (70, 84, 112, 255), (108, 130, 166, 255), (146, 168, 202, 255), (64, 80, 110, 255), (34, 44, 66, 255)
for y in range(H):
    for x in range(W):
        bord = x in (0, W - 1) or y in (0, H - 1)
        if (x, y) in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)):
            continue
        im.putpixel((x, y), LISERE if bord else FOND)
# profil de la plume : longue et étroite, pointe en haut, légèrement penchée ; demi-largeur selon la hauteur
haut, bas = 1, 19
def centre_de(y):
    return 8.2 + (1 - (y - haut) / (bas - haut)) * 1.6
for y in range(haut, bas + 1):
    t = (y - haut) / (bas - haut)            # 0 = pointe, 1 = base
    demi = 4.6 * math.sin(math.pi * min(1.0, t / 0.92)) ** 0.75 if t < 0.92 else 0.6
    c = centre_de(y)
    for x in range(W):
        d = x + 0.5 - c
        if abs(d) <= demi:
            im.putpixel((x, y), CLAIR if d < -demi + 1.0 else (OMBRE if d > demi - 1.0 else PIERRE))
    if t < 0.97: im.putpixel((int(c), y), NERV)
# barbes : un trait oblique de 3 pixels tous les 3 rangs, de part et d'autre de la nervure
for y in range(haut + 5, bas, 3):
    c = int(centre_de(y))
    for s in (-1, 1):
        for k in (1, 2, 3):
            x, yy = c + s * k, y - k
            if 0 < x < W - 1 and im.getpixel((x, yy))[:3] in (PIERRE[:3], OMBRE[:3]):
                im.putpixel((x, yy), NERV)
im.save(os.path.join(T, "plume_pierre.png"))
print("frise_runes_1..4 et plume_pierre écrites")
