"""Prépare le HÉROS (garde au casque à cimier rouge, fait avec un générateur LPC) à partir de la planche complète
exportée par le générateur (« Feuille de Sprite (PNG) ») : Assets/Heros/garde_lpc.png (13 colonnes x 54 lignes de cases carrées,
864x3456 en général ; la taille d'une case est lue dans l'image). Crédits obligatoires (licence LPC) : Assets/Heros/garde_lpc_credits.txt.
Ordre des lignes dans une planche LPC : haut, gauche, bas, droite (pour chaque animation).
  lignes 4-7   estoc (lance)  8 images       lignes 8-11  marche  9 images (la 1re = debout)
  ligne  20    touché         6 images       lignes 22-25 repos   2 images
  lignes 38-41 course         8 images
Sortie : Assets/Heros/heros_lpc.png, cases de 32 px (réduites de MOITIÉ : un pixel du jeu = 2x2 pixels de la planche, bords nets),
lignes dans l'ordre du jeu (bas, haut, gauche, droite) :
  0-3 marche (8)   4-7 repos (2)   8-11 estoc (8)   12-15 course (8)   16 touché (6, une seule direction)
Usage : python3 Outils/preparer_garde_lpc.py [planche.png] [sortie.png]"""
import os, sys
import numpy as np
from PIL import Image

SOURCE = sys.argv[1] if len(sys.argv) > 1 else "Assets/Heros/garde_lpc.png"
SORTIE = sys.argv[2] if len(sys.argv) > 2 else "Assets/Heros/heros_lpc.png"
CASE = 32
ORDRE_JEU = [2, 0, 1, 3]
ANIMS = [  # (nom, 1re ligne LPC, colonne de départ, nombre d'images, 4 directions ?)
    ("marche", 8, 1, 8, True),
    ("repos", 22, 0, 2, True),
    ("estoc", 4, 0, 8, True),
    ("course", 38, 0, 8, True),
    ("touche", 20, 0, 6, False),
]


def reduire(case):
    """Moitié de la taille, sans flou : chaque pixel du jeu = le pixel opaque le plus présent de son bloc 2x2."""
    a = np.array(case.resize((CASE * 2, CASE * 2), Image.NEAREST)).astype(int)   # case normalisée à 64x64
    out = np.zeros((CASE, CASE, 4), np.uint8)
    for y in range(CASE):
        for x in range(CASE):
            bloc = a[2 * y:2 * y + 2, 2 * x:2 * x + 2].reshape(-1, 4)
            vis = bloc[bloc[:, 3] > 100]
            if len(vis) < 2:
                continue
            sombre = vis[vis[:, :3].sum(1) < 120]            # garder les contours (traits sombres) : sinon le perso s'efface
            choix = sombre if len(sombre) >= 2 else vis
            out[y, x, :3] = np.median(choix[:, :3], 0)
            out[y, x, 3] = 255
    return Image.fromarray(out)


def main():
    planche = Image.open(SOURCE).convert("RGBA")
    taille = planche.width // 13
    lignes_dispo = planche.height // taille
    print("planche", planche.size, "cases de", taille, "px,", lignes_dispo, "lignes")
    rangees = sum(4 if quatre else 1 for _, _, _, _, quatre in ANIMS)
    out = Image.new("RGBA", (9 * CASE, rangees * CASE), (0, 0, 0, 0))
    r = 0
    for nom, ligne0, col0, n, quatre in ANIMS:
        dirs = ORDRE_JEU if quatre else [0]
        for d in dirs:
            ligne = ligne0 + d
            if ligne >= lignes_dispo:
                print("!! ligne", ligne, "absente pour", nom)
            for c in range(n):
                x0, y0 = (col0 + c) * taille, ligne * taille
                out.alpha_composite(reduire(planche.crop((x0, y0, x0 + taille, y0 + taille))), (c * CASE, r * CASE))
            r += 1
    out.save(SORTIE)
    # pieds = dernière ligne opaque de la marche vers le bas (pour caler le sprite sur la collision du joueur)
    a = np.array(out)[: CASE, : CASE, 3]
    print("écrit", SORTIE, out.size, "; pieds à la ligne", np.where(a.any(1))[0].max(), "d'une case de", CASE)


if __name__ == "__main__":
    main()
