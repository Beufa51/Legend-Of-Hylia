"""Outil de développement : refait le REBORD des murs épais des salles de donjon (mur_bord_n/s/e/o, mur_coin_*, mur_dot_*) :
une dalle de couvertine en pierre claire (biseau lumineux, joints, ombre) sur 6 px le long du sol, au-dessus des briques sombres de `mur_fond`.
Les murs paraissent ainsi des blocs maçonnés épais, comme dans un vrai donjon. À lancer APRÈS traiter_pack_donjon.py et fabriquer_niches.py.
Usage : python3 Outils/fabriquer_murs_donjon.py"""
import os
from PIL import Image, ImageDraw

T = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR = (26, 26, 40, 255)
LUMIERE = (168, 170, 194, 255)
DALLE = (112, 114, 140, 255)
DALLE_B = (96, 98, 124, 255)
JOINT = (70, 72, 96, 255)
OMBRE = (52, 52, 70, 255)
L = 6   # largeur de la bande (px)


def bande(cote):
    """Une bande de dalle de L px le long du côté `cote` (n, s, e, o) d'une tuile 16x16, dessinée comme si elle était au NORD puis tournée."""
    b = Image.new("RGBA", (16, L + 2))
    d = ImageDraw.Draw(b)
    d.rectangle((0, 0, 15, 0), fill=CONTOUR)              # bord côté sol
    d.rectangle((0, 1, 15, 1), fill=LUMIERE)              # arête éclairée
    d.rectangle((0, 2, 15, L - 1), fill=DALLE)
    d.rectangle((0, L - 2, 15, L - 1), fill=DALLE_B)
    d.line((0, L, 15, L), fill=OMBRE)                      # ombre sur les briques
    d.line((7, 2, 7, L - 1), fill=JOINT)                   # joint entre deux dalles
    d.line((15, 2, 15, L - 1), fill=JOINT)
    rot = {"n": 0, "e": 270, "s": 180, "o": 90}[cote]
    carre = Image.new("RGBA", (16, 16))
    carre.alpha_composite(b, (0, 0))
    return carre.rotate(rot)


def composer(*cotes):
    t = Image.new("RGBA", (16, 16))
    for c in cotes:
        t.alpha_composite(bande(c))
    return t


for c in "nsoe":
    composer(c).save(os.path.join(T, "mur_bord_%s.png" % c))
for coin in ("no", "ne", "so", "se"):
    t = composer(coin[0], coin[1])
    d = ImageDraw.Draw(t)
    # coin extérieur arrondi : on efface le pixel du sommet et on adoucit
    x = 0 if coin[1] == "o" else 15
    y = 0 if coin[0] == "n" else 15
    t.putpixel((x, y), (0, 0, 0, 0))
    t.save(os.path.join(T, "mur_coin_%s.png" % coin))
for dot in ("ne", "no", "se", "so"):   # angle rentrant : un petit bloc de dalle dans le coin
    t = Image.new("RGBA", (16, 16))
    d = ImageDraw.Draw(t)
    x0, x1 = (16 - L, 15) if dot[1] == "e" else (0, L - 1)
    y0, y1 = (0, L - 1) if dot[0] == "n" else (16 - L, 15)
    d.rectangle((x0, y0, x1, y1), fill=DALLE, outline=CONTOUR)
    d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=LUMIERE)
    t.save(os.path.join(T, "mur_dot_%s.png" % dot))
print("rebords de mur refaits (couvertine en dalles)")
