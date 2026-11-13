"""Outil de développement : fabrique l'ENTRÉE DU TEMPLE du donjon (Assets/Gemini/tuiles/v_temple_entree.png, 112 x 96, porte en colonne 3).
Une façade de pierre, la grande arche du pack Aesthetic (pierre verte à frise grecque) et son ouverture SOMBRE, avec 3 marches devant.
Usage : python3 Outils/fabriquer_temple.py   (à lancer APRÈS traiter_pack_aesthetic.py)"""
import os
import numpy as np
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets")
PACK = os.path.join(RACINE, "Aesthetic pack base set (Free)", "Grassland Tileset.png")
SORTIE = os.path.join(RACINE, "Gemini", "tuiles", "v_temple_entree.png")
L, H = 112, 96


def arche():
    im = Image.open(PACK).convert("RGBA").crop((240, 264, 337, 337))
    bb = im.getchannel("A").getbbox()
    return im.crop(bb)


def main():
    a = arche()                                   # ~97 x 73
    img = Image.new("RGBA", (L, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # façade de pierre sombre derrière l'arche (avec joints de briques)
    d.rectangle((6, 12, 105, 80), fill=(78, 84, 104, 255), outline=(40, 44, 58, 255))
    for y in range(16, 80, 8):
        d.line((7, y, 104, y), fill=(60, 66, 84, 255))
        for x in range(7 + (y // 8 % 2) * 7, 104, 14):
            d.line((x, y, x, y + 7), fill=(60, 66, 84, 255))
    d.rectangle((6, 12, 105, 15), fill=(112, 120, 144, 255))   # corniche éclairée
    # ouverture sombre : on remplit ce qui est transparent entre les piliers de l'arche (sous le linteau)
    ax, ay = (L - a.width) // 2, 80 - a.height
    img.alpha_composite(a, (ax, ay))
    px = img.load(); ap = np.array(a)
    haut_linteau = int(a.height * 0.46)           # sous le linteau : l'ouverture
    for y in range(haut_linteau, a.height):
        xs = [x for x in range(a.width) if ap[y, x, 3] > 0]
        # trous = pixels transparents entre le pilier gauche et le pilier droit
        gauche = [x for x in range(a.width // 2) if ap[y, x, 3] > 0]
        droite = [x for x in range(a.width // 2, a.width) if ap[y, x, 3] > 0]
        if not gauche or not droite:
            continue
        for x in range(max(gauche) + 1, min(droite)):
            if ap[y, x, 3] == 0:
                t = (y - haut_linteau) / max(1, a.height - haut_linteau)
                c = int(26 - 10 * t)
                px[ax + x, ay + y] = (c, c - 2, c + 12, 255)
    # trois marches devant l'ouverture (trapèzes de pierre claire)
    for i, (y0, marge) in enumerate([(80, 22), (86, 14), (92, 6)]):
        col = (176 - i * 14, 182 - i * 14, 196 - i * 14, 255)
        d.rectangle((marge, y0, L - marge, y0 + 5), fill=col, outline=(70, 76, 92, 255))
    img.save(SORTIE)
    print("ok", img.size)


if __name__ == "__main__":
    main()
