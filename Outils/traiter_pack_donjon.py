"""Outil de développement : prend des sprites du pack donjon Craftpix (Assets/PNG/, licence craftpix.net : usage dans un jeu OK)
et les écrit dans Assets/Gemini/tuiles/ sous les noms que room.gd utilise déjà.
Usage : python3 Outils/traiter_pack_donjon.py [apercu.png]
ORDRE : à lancer APRÈS traiter_gemini.py (qui réécrit les anciennes images vase_1, brasero_*, torche_*).

Images produites :
  brasero_1..6.png  (20x26 : la case de 16x16 est en BAS au centre -> décalage (-2,-10) dans room.gd / brasero.gd)
  brasero_eteint.png (même taille : la flamme est retirée, il reste des braises)
  torche_1..6.png   (12x24 : torche murale animée)
  vase_1.png (bleu), vase_2.png (brun) (16x16, posés au fond de la case)
"""
import os
import sys
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
PACK = os.path.join(RACINE, "Assets", "PNG")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
OPAQUE = 200   # on ne garde que les pixels presque opaques (le halo du pack est remplacé par nos propres lueurs)


def nettoyer(im):
    """Supprime le halo semi-transparent."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] < OPAQUE:
                px[x, y] = (0, 0, 0, 0)
    return im


def animation(fichier, x0, x1, nb, taille):
    """Découpe `nb` images (une par rangée de 48 px) dans la colonne x0..x1 ; toutes alignées pareil
    (même boîte englobante), posées en bas au centre d'une image de `taille`."""
    planche = nettoyer(Image.open(os.path.join(PACK, fichier)))
    images = [planche.crop((x0, r * 48, x1, r * 48 + 48)) for r in range(nb)]
    boite = None
    for im in images:
        b = im.getbbox()
        boite = b if boite is None else (min(boite[0], b[0]), min(boite[1], b[1]), max(boite[2], b[2]), max(boite[3], b[3]))
    sortie = []
    for im in images:
        morceau = im.crop(boite)
        toile = Image.new("RGBA", taille, (0, 0, 0, 0))
        toile.alpha_composite(morceau, ((taille[0] - morceau.width) // 2, taille[1] - morceau.height))
        sortie.append(toile)
    return sortie


def sans_flamme(im):
    """Brasero éteint : les pixels de flamme (clairs, jaunes/orangés) deviennent un fond de cuve sombre,
    avec quelques braises rouges."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r > 140 and r > b + 60:   # flamme
                px[x, y] = (0, 0, 0, 0)
    # la cuve : sous la ligne où commence le métal, on remplit le creux d'un brun très sombre
    haut_metal = None
    for y in range(im.height):
        if any(px[x, y][3] for x in range(im.width)):
            haut_metal = y
            break
    if haut_metal is not None:
        for y in range(haut_metal, im.height):
            ligne = [x for x in range(im.width) if px[x, y][3]]
            if len(ligne) >= 2:
                for x in range(ligne[0], ligne[-1] + 1):
                    if not px[x, y][3]:
                        px[x, y] = (40, 30, 30, 255)
    for (x, y) in [(8, 13), (11, 14), (10, 12)]:   # braises
        if 0 <= x < im.width and 0 <= y < im.height and px[x, y][3]:
            px[x, y] = (200, 70, 30, 255)
    return im


def vase(boite):
    planche = Image.open(os.path.join(PACK, "Objects.png")).convert("RGBA")
    morceau = planche.crop((boite[0], boite[1], boite[2] + 1, boite[3] + 1))
    toile = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    toile.alpha_composite(morceau, ((16 - morceau.width) // 2, 16 - morceau.height))
    return toile


def main():
    images = {}
    braseros = animation("fire_animation.png", 130, 172, 6, (20, 26))
    for i, im in enumerate(braseros):
        images["brasero_%d" % (i + 1)] = im
    images["brasero_eteint"] = sans_flamme(braseros[0])
    for i, im in enumerate(animation("fire_animation.png", 40, 70, 6, (12, 24))):
        images["torche_%d" % (i + 1)] = im
    images["vase_1"] = vase((210, 67, 220, 82))   # vase bleu moyen (11x16)
    images["vase_2"] = vase((258, 67, 268, 82))   # vase brun moyen
    for nom, im in images.items():
        im.save(os.path.join(SORTIE, nom + ".png"))
    print("écrit :", sorted(images))
    if len(sys.argv) > 1:   # aperçu : toutes les images côte à côte, agrandies x4, sur un sol gris
        largeur = sum(im.width + 4 for im in images.values())
        apercu = Image.new("RGBA", (largeur, 30), (110, 112, 130, 255))
        x = 0
        for im in images.values():
            apercu.alpha_composite(im, (x, 30 - im.height))
            x += im.width + 4
        apercu.resize((apercu.width * 4, apercu.height * 4), Image.NEAREST).save(sys.argv[1])


main()
