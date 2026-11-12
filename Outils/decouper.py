"""Outil de développement (pas du jeu) : découpe les planches Gemini en tuiles.
Usage : python3 Outils/decouper.py <image> <dossier_sortie> <prefixe>
Détecte les zones non magenta (fond #FF00FF) par projection lignes/colonnes."""
import sys
import numpy as np
from PIL import Image


def masque_non_magenta(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    magenta = (r > 190) & (b > 190) & (g < 110)
    return ~magenta


def segments(profil, minimum):
    """Liste des (debut, fin) où le profil dépasse `minimum`."""
    res, debut = [], None
    for i, v in enumerate(profil):
        if v > minimum and debut is None:
            debut = i
        elif v <= minimum and debut is not None:
            res.append((debut, i))
            debut = None
    if debut is not None:
        res.append((debut, len(profil)))
    return [s for s in res if s[1] - s[0] > 30]


def cases(img):
    rgb = np.array(img.convert("RGB"))
    m = masque_non_magenta(rgb)
    out = []
    for (y0, y1) in segments(m.sum(axis=1), 25):
        for (x0, x1) in segments(m[y0:y1].sum(axis=0), 25):
            out.append((x0, y0, x1, y1))
    return out, m


if __name__ == "__main__":
    chemin, sortie, prefixe = sys.argv[1:4]
    img = Image.open(chemin)
    boites, m = cases(img)
    print(len(boites), "cases :", boites)
