"""Outil de développement : fabrique les images de la RIVIÈRE et du PONT du village (écran Rivière).
Usage : python3 Outils/fabriquer_riviere.py   (à lancer avant generer_village.py ; écrit dans Assets/Gemini/tuiles/)
L'eau vient du pack Pixel Crawler (Environment/Tilesets/Water_tiles.png) : 2 nuances = 2 images qui alternent (eau qui scintille).
  v_eau_1/2   eau pleine          v_eau_h_1/2  rive du HAUT (herbe au nord)   v_eau_b_1/2  rive du BAS (herbe au sud)
  v_pont_g/m/d   pont de bois (planches en travers, rambarde à gauche / sans / à droite)
"""
import os
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
SORTIE = os.path.join(RACINE, "Assets/Gemini/tuiles/")
PACK = os.path.join(RACINE, "Assets/Pixel Crawler - Free Pack/Environment/Tilesets/Water_tiles.png")

planche = Image.open(PACK).convert("RGBA")
# cases d'eau pleine (le centre des deux grandes croix du bas de la planche)
EAU = [planche.crop((48, 192, 64, 208)), planche.crop((208, 192, 224, 208))]

TERRE = (122, 84, 48, 255)
TERRE_CLAIRE = (170, 128, 78, 255)
ECUME = (214, 236, 248, 255)


def eau(i, rive=None):
    t = EAU[i].copy()
    d = ImageDraw.Draw(t)
    if rive == "h":      # herbe au nord : bord de terre en haut, une ligne d'écume en dessous
        d.rectangle((0, 0, 15, 1), fill=TERRE)
        d.rectangle((0, 2, 15, 2), fill=TERRE_CLAIRE)
        for x in range(1 + i, 16, 4): d.point((x, 4), fill=ECUME)
    if rive == "b":      # herbe au sud
        d.rectangle((0, 14, 15, 15), fill=TERRE)
        d.rectangle((0, 13, 15, 13), fill=TERRE_CLAIRE)
        for x in range(2 - i, 16, 4): d.point((x, 11), fill=ECUME)
    return t


def pont(cote):
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    bois = [(150, 104, 56, 255), (132, 90, 46, 255)]
    for y in range(0, 16, 4):       # planches en travers (traverser le pont = monter ou descendre)
        d.rectangle((0, y, 15, y + 2), fill=bois[(y // 4) % 2])
        d.line((0, y + 3, 15, y + 3), fill=(84, 54, 28, 255))
    if cote in ("g", "d"):          # rambarde (poteau + lisse) du côté de l'eau
        x0, x1 = (0, 3) if cote == "g" else (12, 15)
        d.rectangle((x0, 0, x1, 15), fill=(96, 62, 32, 255))
        d.rectangle((x0 + (1 if cote == "g" else 0), 0, x0 + (2 if cote == "g" else 1), 15), fill=(170, 122, 70, 255))
        for y in (0, 8): d.rectangle((x0, y, x1, y + 2), fill=(60, 38, 18, 255))
    return t


for i in (0, 1):
    eau(i).save(SORTIE + "v_eau_%d.png" % (i + 1))
    eau(i, "h").save(SORTIE + "v_eau_h_%d.png" % (i + 1))
    eau(i, "b").save(SORTIE + "v_eau_b_%d.png" % (i + 1))
for c in "gmd":
    pont(c).save(SORTIE + "v_pont_%s.png" % c)
print("rivière et pont écrits dans", SORTIE)
