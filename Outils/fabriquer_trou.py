"""Outil de développement (APRÈS traiter_gemini.py) : fabrique `trou_0..15.png` (16x16) = un GOUFFRE dans le sol du donjon (énigme du pont, Plume 3b).
Bits : 1 = gouffre (ou mur) au nord, 2 = au sud, 4 = à l'ouest, 8 = à l'est. Les côtés SANS voisin ont une lèvre de pierre ; les autres se prolongent."""
import os, random
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR, LEVRE, LEVRE_OMBRE = (26, 28, 40), (112, 124, 148), (84, 94, 118)
VIDE, VIDE2, VIDE3, OMBRE = (9, 11, 20), (16, 19, 32), (22, 26, 42), (3, 4, 9)

def trou(bits):
    n, s, o, e = bool(bits & 1), bool(bits & 2), bool(bits & 4), bool(bits & 8)
    t = Image.new("RGBA", (16, 16), VIDE + (255,))
    d = ImageDraw.Draw(t)
    rnd = random.Random(bits * 7 + 1)
    for _ in range(14):                         # un peu de matière au fond (roches, strates)
        x, y = rnd.randrange(16), rnd.randrange(16)
        d.point((x, y), fill=rnd.choice((VIDE2, VIDE3)) + (255,))
    if not n: d.rectangle((0, 2, 15, 4), fill=OMBRE + (255,))      # l'ombre du bord nord : on devine la profondeur
    if not o: d.rectangle((2, 0, 3, 15), fill=OMBRE + (255,))
    # lèvres de pierre (2 px) + contour sombre vers le vide, sur les côtés sans voisin
    if not n:
        d.rectangle((0, 0, 15, 0), fill=LEVRE + (255,)); d.rectangle((0, 1, 15, 1), fill=LEVRE_OMBRE + (255,))
        d.rectangle((0, 2, 15, 2), fill=CONTOUR + (255,))
    if not s:
        d.rectangle((0, 15, 15, 15), fill=LEVRE + (255,)); d.rectangle((0, 14, 15, 14), fill=LEVRE_OMBRE + (255,))
        d.rectangle((0, 13, 15, 13), fill=CONTOUR + (255,))
    if not o:
        d.rectangle((0, 0, 0, 15), fill=LEVRE + (255,)); d.rectangle((1, 0, 1, 15), fill=LEVRE_OMBRE + (255,))
        d.rectangle((2, 0, 2, 15), fill=CONTOUR + (255,))
    if not e:
        d.rectangle((15, 0, 15, 15), fill=LEVRE + (255,)); d.rectangle((14, 0, 14, 15), fill=LEVRE_OMBRE + (255,))
        d.rectangle((13, 0, 13, 15), fill=CONTOUR + (255,))
    return t

for b in range(16):
    trou(b).save(os.path.join(SORTIE, "trou_%d.png" % b))
for ancien in range(4):
    pass
print("gouffres fabriqués (16 formes)")
