"""Refait `arche_basse_1..5.png` : porte intérieure 48x16 (mur d'UNE rangée). L'ancienne (bas d'une arche) faisait « demi-porte ».
Nouvelle : portique complet dessiné ici (linteau de briques, 2 montants, ouverture sombre) dont la grille se relève en 5 images.
Mêmes couleurs de pierre que le reste du donjon. Aucune dépendance : pas besoin de traiter_pack_donjon.py."""
import os
from PIL import Image, ImageDraw
D = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
OUT = (19, 18, 28); S = (63, 63, 83); SL = (87, 86, 109); SM = (72, 72, 93); SD = (52, 52, 70)
NUIT = (29, 28, 43); NUIT2 = (22, 21, 33); SOL = (41, 41, 62); FER = (91, 107, 152); FER_S = (58, 68, 104)
LONGUEURS = [10, 7, 4, 2, 0]   # longueur des barreaux sous le linteau, de fermée (1) à ouverte (5)

def porte(barreaux):
    im = Image.new("RGBA", (48, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 47, 15), fill=OUT)
    d.rectangle((6, 6, 41, 15), fill=NUIT)                     # ouverture
    d.rectangle((6, 6, 41, 8), fill=NUIT2)                     # ombre sous le linteau
    d.rectangle((6, 14, 41, 15), fill=SOL)                     # seuil
    # montants de pierre (briques de 5 px de haut, décalées)
    for x0, x1 in ((0, 5), (42, 47)):
        d.rectangle((x0, 0, x1, 15), fill=S)
        for y in (5, 10, 15): d.line((x0, y, x1, y), fill=SD)
        d.line((x0 + (2 if y else 3), 0, x0 + 2, 4), fill=SD)
        d.line((x0, 0, x0, 15), fill=SL if x0 == 0 else SM)
        d.line((x1, 0, x1, 15), fill=SD)
    # linteau : 2 rangées de briques
    d.rectangle((6, 0, 41, 5), fill=S)
    d.line((6, 0, 41, 0), fill=SL); d.line((6, 2, 41, 2), fill=SD); d.line((6, 5, 41, 5), fill=OUT)
    for x in range(8, 42, 8): d.line((x, 0, x, 2), fill=SD)
    for x in range(12, 42, 8): d.line((x, 3, x, 4), fill=SD)
    d.rectangle((6, 3, 41, 4), fill=SM); 
    for x in range(12, 42, 8): d.line((x, 3, x, 4), fill=SD)
    # barreaux qui pendent du linteau
    if barreaux > 0:
        for x in range(9, 41, 5):
            d.rectangle((x, 6, x + 1, 5 + barreaux), fill=FER)
            d.line((x + 1, 6, x + 1, 5 + barreaux), fill=FER_S)
            if barreaux >= 4: d.point((x, 6 + barreaux), fill=FER)   # pointe
        d.line((7, 9, 40, 9), fill=FER_S) if barreaux >= 7 else None   # traverse
    return im

for f, n in enumerate(LONGUEURS, 1):
    porte(n).save(os.path.join(D, "arche_basse_%d.png" % f))
print("arche_basse_1..5 écrits")
