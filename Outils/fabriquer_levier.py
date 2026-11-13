"""Redessine le LEVIER (levier_1..5.png, 16x24) en plus gros, dans la pierre du donjon.
À lancer APRÈS traiter_pack_donjon.py. Poignée penchée de gauche (1) à droite (5), pommeau rouge.
Le sprite dépasse de 8 px au-dessus de sa case (levier.gd le décale de -8)."""
import math, os
from PIL import Image, ImageDraw
D = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR = (19, 18, 28); P_SOMBRE = (52, 52, 70); P_MOY = (72, 72, 93); P_CLAIRE = (105, 101, 132)
ACIER = (150, 165, 200); ACIER_S = (92, 104, 140); ROUGE = (214, 56, 48); ROUGE_C = (255, 150, 120)

def levier(angle):
    """Levier MURAL : plaque de pierre rivetée sur le mur (haut de l'image) + petit rebord au sol (bas)."""
    im = Image.new("RGBA", (16, 24), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle((1, 1, 14, 14), fill=CONTOUR)                          # plaque
    d.rectangle((2, 2, 13, 13), fill=P_MOY); d.rectangle((2, 2, 13, 2), fill=P_CLAIRE); d.rectangle((2, 2, 2, 13), fill=P_CLAIRE)
    d.rectangle((2, 13, 13, 13), fill=P_SOMBRE); d.rectangle((13, 3, 13, 13), fill=P_SOMBRE)
    for (rx, ry) in ((3, 3), (12, 3)): d.point((rx, ry), fill=ACIER)   # rivets
    d.rectangle((7, 4, 9, 11), fill=CONTOUR)                           # rainure
    d.rectangle((1, 15, 14, 19), fill=CONTOUR)                         # rebord de pierre au sol
    d.rectangle((2, 15, 13, 18), fill=P_CLAIRE); d.rectangle((2, 18, 13, 18), fill=P_SOMBRE)
    px, py = 8, 11; L = 8
    ex = px + L * math.sin(math.radians(angle)); ey = py - L * math.cos(math.radians(angle))
    d.line((px, py, ex, ey), fill=CONTOUR, width=5)
    d.line((px, py, ex, ey), fill=ACIER_S, width=3)
    d.line((px - 0.5, py, ex - 0.5, ey), fill=ACIER, width=1)
    r = 3
    d.ellipse((ex - r - 1, ey - r - 1, ex + r + 1, ey + r + 1), fill=CONTOUR)
    d.ellipse((ex - r, ey - r, ex + r, ey + r), fill=ROUGE)
    d.rectangle((ex - 1.5, ey - 1.5, ex - 0.5, ey - 0.5), fill=ROUGE_C)
    d.rectangle((7, 10, 9, 12), fill=CONTOUR); d.point((8, 11), fill=ACIER)   # pivot
    return im

for i, a in enumerate((-27, -14, 0, 14, 27)):
    levier(a).save(os.path.join(D, "levier_%d.png" % (i + 1)))
print("levier_1..5 écrits")
