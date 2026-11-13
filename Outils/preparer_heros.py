"""Outil de développement : prépare les planches du HÉROS à partir de Assets/character-spritesheet.png
(planche de type LPC : cases de 64 px, lignes dans l'ordre haut / gauche / bas / droite).
  - lignes 4 à 7  = coup d'estoc (8 images)      -> Assets/Heros/heros_coup.png
  - lignes 8 à 11 = marche (9 images, la 1re = debout) -> Assets/Heros/heros_marche.png
Sortie : cases de 32 px (réduites de moitié, bords nets), lignes dans l'ordre du jeu : bas, haut, gauche, droite.
Usage : python3 Outils/preparer_heros.py"""
import os
import numpy as np
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets")
SOURCE = os.path.join(RACINE, "character-spritesheet.png")
# ordre des lignes dans la planche d'origine : haut(0), gauche(1), bas(2), droite(3)  ->  ordre du jeu : bas, haut, gauche, droite
ORDRE_JEU = [2, 0, 1, 3]


def reduire(case):
    im = case.resize((32, 32), Image.LANCZOS)
    a = np.array(im)
    a[:, :, 3] = np.where(a[:, :, 3] >= 110, 255, 0)
    return Image.fromarray(a, "RGBA")


def bande(planche, ligne0, n, sortie):
    out = Image.new("RGBA", (n * 32, 4 * 32), (0, 0, 0, 0))
    for r, d in enumerate(ORDRE_JEU):
        for c in range(n):
            case = planche.crop((c * 64, (ligne0 + d) * 64, c * 64 + 64, (ligne0 + d) * 64 + 64))
            out.alpha_composite(reduire(case), (c * 32, r * 32))
    out.save(os.path.join(RACINE, "Heros", sortie))
    return out


if __name__ == "__main__":
    planche = Image.open(SOURCE).convert("RGBA")
    os.makedirs(os.path.join(RACINE, "Heros"), exist_ok=True)
    bande(planche, 8, 9, "heros_marche.png")
    c = bande(planche, 4, 8, "heros_coup.png")
    print("ok")
