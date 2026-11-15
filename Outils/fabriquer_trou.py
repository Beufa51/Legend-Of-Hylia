"""Outil de développement (APRÈS traiter_gemini.py) : fabrique `trou_0..3.png` (16x16) = un TROU dans le sol du donjon (énigme du pont, Plume 3b).
Bits : 1 = un autre trou au nord, 2 = un autre trou au sud (les trous alignés se raccordent, sans rebord entre eux)."""
import os
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR, LEVRE, OMBRE, FOND, FOND2 = (26, 28, 40, 255), (126, 138, 162, 255), (4, 5, 10, 255), (12, 14, 24, 255), (22, 25, 40, 255)

def trou(bits):
    haut, bas = bool(bits & 1), bool(bits & 2)
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    d.rectangle((0, 0, 15, 15), fill=CONTOUR)                      # contour sombre
    d.rectangle((1, 0 if haut else 1, 14, 15 if bas else 14), fill=LEVRE)   # lèvre de pierre
    d.rectangle((3, 0 if haut else 3, 12, 15 if bas else 12), fill=FOND)     # le vide
    if not haut:
        d.rectangle((3, 3, 12, 5), fill=OMBRE)                     # l'ombre du rebord nord : le trou est profond
    for y in range(6 if not haut else 0, 13 if not bas else 16):
        for x in range(3, 13):
            if (x + y) % 5 == 0: d.point((x, y), fill=FOND2)         # un peu de relief au fond
    return t

for b in range(4):
    trou(b).save(os.path.join(SORTIE, "trou_%d.png" % b))
print("trous fabriqués")
