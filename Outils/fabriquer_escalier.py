"""Outil de développement : fabrique `escalier_donjon.png` (48x48 = 3x3 cases) : un ESCALIER DE PIERRE qui descend, vu de dessus, posé dans le vestibule du donjon.
Marches de plus en plus sombres vers le nord (on s'enfonce sous terre), avec rampes de pierre de chaque côté. Utilisé par room.gd (export `escaliers_descente`).
Usage : python3 Outils/fabriquer_escalier.py"""
import os
from PIL import Image, ImageDraw

T = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
img = Image.new("RGBA", (48, 48))
d = ImageDraw.Draw(img)
CONTOUR = (24, 24, 36, 255)
nb = 6
for i in range(nb):                       # i = 0 : marche du haut (nord, la plus sombre) ... nb-1 : la plus proche de l'entrée (claire)
    y0 = i * 8
    v = 0.40 + 0.60 * i / (nb - 1)
    dalle = tuple(int(c * v) for c in (150, 152, 178)) + (255,)
    front = tuple(int(c * v) for c in (192, 194, 216)) + (255,)
    contre = tuple(int(c * v * 0.55) for c in (120, 122, 150)) + (255,)
    d.rectangle((6, y0, 41, y0 + 7), fill=dalle)
    d.line((6, y0 + 7, 41, y0 + 7), fill=front)                     # arête éclairée du devant de la marche
    d.line((6, y0, 41, y0), fill=contre)                            # ombre sous la marche du dessus
    d.line((23, y0 + 1, 23, y0 + 6), fill=contre)                   # joint central
for x0, x1 in ((0, 5), (42, 47)):                                    # rampes de pierre
    d.rectangle((x0, 0, x1, 47), fill=(96, 98, 124, 255), outline=CONTOUR)
    d.line((x0 + 1, 1, x0 + 1, 46), fill=(160, 162, 188, 255))
d.rectangle((6, 0, 41, 47), outline=CONTOUR)
img.save(os.path.join(T, "escalier_donjon.png"))
print("escalier_donjon écrit")
