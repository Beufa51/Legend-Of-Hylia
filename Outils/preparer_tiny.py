"""Fabrique Assets/Heros/heros_tiny.png à partir du pack gratuit « Tiny Questers — Free Warrior » (Bobddadoo).

Usage : python3 Outils/preparer_tiny.py chemin/vers/tiny-questers-warrior-free.zip
Lit les planches horizontales du zip (png/atlas/*.png) et écrit une feuille à cases de 128 px :
une LIGNE par animation (voir LIGNE_TINY dans Scripts/player.gd). Les images de marche et de repos
(64 x 49) sont centrées et leurs pieds alignés sur ceux des attaques (128 x 128), pour que le perso
ne saute pas d'une animation à l'autre. Licence du pack : usage libre (crédit apprécié).
"""
import io
import sys
import zipfile
from PIL import Image

ZIP = sys.argv[1] if len(sys.argv) > 1 else "tiny-questers-warrior-free.zip"
SORTIE = "Assets/Heros/heros_tiny.png"
C = 128
# (animation, nombre d'images, taille de l'image : 'petit' 64x49 ou 'grand' 128x128)
LIGNES = [("idle_down", 5, "petit"), ("idle_up", 5, "petit"), ("walk_down", 4, "petit"), ("walk_up", 4, "petit"),
          ("walk_left", 4, "petit"), ("walk_right", 4, "petit"),
          ("attack_down_stay", 20, "grand"), ("attack_up_stay", 20, "grand"), ("attack_left_stay", 18, "grand"),
          ("attack_right_stay", 18, "grand"), ("hit", 2, "petit")]

z = zipfile.ZipFile(ZIP)


def planche(nom):
    return Image.open(io.BytesIO(z.read("png/atlas/" + nom + ".png"))).convert("RGBA")


feuille = Image.new("RGBA", (max(n for _, n, _ in LIGNES) * C, len(LIGNES) * C), (0, 0, 0, 0))
for r, (nom, n, taille) in enumerate(LIGNES):
    im = planche(nom)
    fw, fh = (C, C) if taille == "grand" else (64, 49)
    for k in range(n):
        f = im.crop((k * fw, 0, (k + 1) * fw, fh))
        if taille == "petit":
            case = Image.new("RGBA", (C, C), (0, 0, 0, 0))
            case.paste(f, (32, 40), f)   # pieds alignés sur ceux des attaques
            f = case
        feuille.paste(f, (k * C, r * C), f)
feuille.save(SORTIE)
print("écrit", SORTIE, feuille.size)
