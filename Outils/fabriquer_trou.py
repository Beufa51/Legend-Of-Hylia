"""Outil de développement (APRÈS traiter_gemini.py) : fabrique `trou_<bits>_<variante>.png` (16x16) = un GOUFFRE AVEC UN FOND dans le sol du donjon (énigme du pont, Plume 3b).
On voit le fond (éboulis de pierre) et, sur le bord nord, la PAROI du trou (briques) : un bloc qui tombe dedans le comble vraiment.
Bits : 1 = gouffre (ou mur) au nord, 2 = au sud, 4 = à l'ouest, 8 = à l'est. Les côtés SANS voisin ont une lèvre de pierre.
3 variantes par forme (pour que le fond ne se répète pas)."""
import os, random
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR, LEVRE, LEVRE_OMBRE = (26, 28, 40), (112, 124, 148), (84, 94, 118)
FOND = (38, 44, 66)
FOND_CLAIR, FOND_SOMBRE, VEINE = (52, 60, 86), (28, 32, 50), (70, 108, 176)
BRIQUE, BRIQUE2, JOINT = (60, 68, 94), (48, 55, 78), (30, 34, 52)
HAUT_PAROI = 3
HAUTEUR_PAROI = 9


def assombrir(c, f):
    return tuple(int(v * f) for v in c)


def trou(bits, variante):
    n, s, o, e = bool(bits & 1), bool(bits & 2), bool(bits & 4), bool(bits & 8)
    rnd = random.Random(bits * 31 + variante * 7 + 5)
    t = Image.new("RGBA", (16, 16), FOND + (255,))
    d = ImageDraw.Draw(t)
    # le FOND : éboulis (grains clairs et sombres, quelques cailloux, une veine luminescente)
    for _ in range(46):
        d.point((rnd.randrange(16), rnd.randrange(16)), fill=rnd.choice((FOND_CLAIR, FOND_SOMBRE, FOND_CLAIR)) + (255,))
    for _ in range(3):
        x, y = rnd.randrange(2, 13), rnd.randrange(2, 13)
        d.rectangle((x, y, x + 2, y + 1), fill=(58, 66, 94, 255))
        d.point((x, y), fill=(86, 98, 134, 255))
        d.point((x + 1, y + 2), fill=(22, 25, 40, 255))
    if rnd.random() < 0.7:
        x, y = rnd.randrange(3, 13), rnd.randrange(4, 13)
        d.point((x, y), fill=VEINE + (255,)); d.point((x + 1, y), fill=assombrir(VEINE, 0.6) + (255,))
    # la PAROI nord du trou (briques sombres vues de face) quand il n'y a pas de gouffre au nord
    if not n:
        for y in range(HAUT_PAROI, HAUT_PAROI + HAUTEUR_PAROI):
            ligne = y - HAUT_PAROI
            facteur = 1.0 - 0.38 * ligne / HAUTEUR_PAROI     # de plus en plus sombre vers le bas
            decal = 4 if (ligne // 4) % 2 else 0
            for x in range(16):
                joint = ligne % 4 == 3 or (x + decal) % 8 == 7
                base = JOINT if joint else (BRIQUE if ((x + decal) // 8 + ligne // 4) % 2 == 0 else BRIQUE2)
                d.point((x, y), fill=assombrir(base, facteur) + (255,))
        # l'ombre portée de la paroi sur le fond
        for y in range(HAUT_PAROI + HAUTEUR_PAROI, HAUT_PAROI + HAUTEUR_PAROI + 3):
            for x in range(16):
                base = t.getpixel((x, y))[:3]
                d.point((x, y), fill=assombrir(base, 0.62 + 0.12 * (y - HAUT_PAROI - HAUTEUR_PAROI)) + (255,))
        d.rectangle((0, 0, 15, 0), fill=LEVRE + (255,)); d.rectangle((0, 1, 15, 1), fill=LEVRE_OMBRE + (255,))
        d.rectangle((0, 2, 15, 2), fill=CONTOUR + (255,))
    if not o:
        for x in (3, 4):
            for y in range(HAUT_PAROI if not n else 0, 16):
                base = t.getpixel((x, y))[:3]
                d.point((x, y), fill=assombrir(base, 0.7) + (255,))
        d.rectangle((0, 0, 0, 15), fill=LEVRE + (255,)); d.rectangle((1, 0, 1, 15), fill=LEVRE_OMBRE + (255,)); d.rectangle((2, 0, 2, 15), fill=CONTOUR + (255,))
    if not e:
        for x in (11, 12):
            for y in range(HAUT_PAROI if not n else 0, 16):
                base = t.getpixel((x, y))[:3]
                d.point((x, y), fill=assombrir(base, 0.7) + (255,))
        d.rectangle((15, 0, 15, 15), fill=LEVRE + (255,)); d.rectangle((14, 0, 14, 15), fill=LEVRE_OMBRE + (255,)); d.rectangle((13, 0, 13, 15), fill=CONTOUR + (255,))
    if not s:
        d.rectangle((0, 13, 15, 13), fill=CONTOUR + (255,))
        d.rectangle((0, 14, 15, 14), fill=LEVRE_OMBRE + (255,)); d.rectangle((0, 15, 15, 15), fill=LEVRE + (255,))
    return t


for b in range(16):
    for v in range(3):
        trou(b, v).save(os.path.join(SORTIE, "trou_%d_%d.png" % (b, v)))
print("gouffres à fond fabriqués (16 formes x 3 variantes)")
