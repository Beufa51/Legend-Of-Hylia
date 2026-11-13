"""Outil de développement : refait les MAISONS du village avec le pack Pixel Crawler (murs à colombages, grands toits, vraies portes et fenêtres).
Écrit les mêmes images que les autres outils : v_maison_orange / bleue / chaume / rouge / pierre / bois / caserne (exterieur.gd ne change pas).
Chaque maison = un mur de face (5 pièces : poteau, panneau, poteau, panneau, poteau = 112 px, la largeur de l'emprise 7x4) + une porte au milieu
(colonne 3 = x 48..64 de l'emprise) + une fenêtre par panneau + le grand toit du pack (126 px) posé dessus. Les couleurs du toit varient par recoloration.
À lancer APRÈS traiter_pack_aesthetic.py / traiter_pixel_crawler.py, AVANT generer_village.py.
Usage : python3 Outils/fabriquer_maisons_pixelcrawler.py [apercu.png]"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
BAT = os.path.join(RACINE, "Assets", "Pixel Crawler - Free Pack", "Environment", "Structures", "Buildings")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")

murs = Image.open(os.path.join(BAT, "Walls.png")).convert("RGBA")
toits = Image.open(os.path.join(BAT, "Roofs.png")).convert("RGBA")
accessoires = Image.open(os.path.join(BAT, "Props.png")).convert("RGBA")

# Y de la rangée de murs « bandes » (haut, bas) et début de chaque type : 4 pièces = panneau 32, poteau 16, panneau 32, poteau 16
Y_HAUT, Y_BAS = 189, 241
TYPES = {"fenetres": 288, "plein": 384, "brique": 480, "planches": 192, "rondins": 0}


def piece(type_, i):
    """Les 4 pièces d'un type de mur : 0 panneau, 1 poteau, 2 panneau, 3 poteau."""
    x = TYPES[type_]
    bornes = [(0, 32), (32, 48), (48, 80), (80, 96)][i]
    return murs.crop((x + bornes[0], Y_HAUT, x + bornes[1], Y_BAS))


def rogner(im):
    return im.crop(im.getchannel("A").getbbox())


PORTE = rogner(accessoires.crop((134, 24, 156, 66)))       # porte arrondie à ferrures
FENETRE = rogner(accessoires.crop((132, 99, 156, 125)))    # fenêtre à 4 carreaux
FENETRE_VOLETS = rogner(accessoires.crop((128, 62, 160, 97)))   # fenêtre arrondie à volets verts
def plus_grand_morceau(im):
    """Ne garde que le plus grand morceau d'une image (le grand toit), sans les débuts des autres pièces de la planche qui dépassent."""
    a = np.array(im.getchannel("A")) > 0
    h, l = a.shape
    vu = np.zeros_like(a)
    meilleur = []
    for y0 in range(h):
        for x0 in range(l):
            if a[y0, x0] and not vu[y0, x0]:
                pile, zone = [(y0, x0)], []
                vu[y0, x0] = True
                while pile:
                    y, x = pile.pop()
                    zone.append((y, x))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < l and a[ny, nx] and not vu[ny, nx]:
                            vu[ny, nx] = True
                            pile.append((ny, nx))
                if len(zone) > len(meilleur):
                    meilleur = zone
    masque = np.zeros_like(a)
    for y, x in meilleur:
        masque[y, x] = True
    sortie = np.array(im).copy()
    sortie[~masque] = 0
    return rogner(Image.fromarray(sortie, "RGBA"))


TOIT = {"brun": plus_grand_morceau(toits.crop((0, 0, 128, 100))), "vert": plus_grand_morceau(toits.crop((128, 0, 256, 100)))}


def teinter(im, h0, h1, nouvelle, sat=1.0, lum=1.0):
    """Change la teinte des pixels colorés dont la teinte est dans [h0, h1] (le relief est gardé)."""
    a = np.array(im).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.18 and h0 <= h <= h1:
                r, g, b = colorsys.hsv_to_rgb(nouvelle, min(1.0, s * sat), min(1.0, v * lum))
                a[y, x, :3] = (r * 255, g * 255, b * 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


PIGNON = {"brun": rogner(toits.crop((32, 158, 98, 210))), "vert": rogner(toits.crop((158, 158, 226, 210)))}   # face de bois/briques sous le toit (le triangle derrière la crête)


def maison(toit, type_mur, volets=False, pignon=None):
    mur_h = Y_BAS - Y_HAUT
    larg = 112
    mur = Image.new("RGBA", (larg, mur_h))
    x = 0
    for i in (1, 0, 1, 2, 3):          # poteau, panneau, poteau (porte), panneau, poteau
        p = piece(type_mur, i)
        mur.alpha_composite(p, (x, 0))
        x += p.width
    # fenêtres : au milieu de chaque panneau (x 16..48 et 64..96)
    for cx in (32, 80):
        fen = FENETRE_VOLETS if volets else FENETRE
        mur.alpha_composite(fen, (cx - fen.width // 2, 6))
    # porte au milieu (colonne 3 : x 48..64), posée sur le bas du mur
    mur.alpha_composite(PORTE, (56 - PORTE.width // 2, mur_h - PORTE.height))
    # le toit déborde de chaque côté et recouvre le haut du mur
    haut_toit = toit.height
    recouvre = 14
    total_l = max(toit.width, larg)
    img = Image.new("RGBA", (total_l, haut_toit + mur_h - recouvre))
    img.alpha_composite(mur, ((total_l - larg) // 2, haut_toit - recouvre))
    if pignon is not None:   # le mur du pignon remplit le creux du toit (sinon on verrait l'herbe à travers)
        py = haut_toit - recouvre - pignon.height + 12
        img.alpha_composite(pignon, ((total_l - pignon.width) // 2, py))
    img.alpha_composite(toit, ((total_l - toit.width) // 2, 0))
    return img


def main(apercu=None):
    brun, vert = TOIT["brun"], TOIT["vert"]
    pb, pv = PIGNON["brun"], PIGNON["vert"]
    t = lambda im, *args: teinter(im, *args)
    maisons = {
        "v_maison_orange": maison(brun, "fenetres", pignon=pb),
        "v_maison_bleue": maison(t(vert, 0.40, 0.50, 0.58, 1.0, 0.95), "plein", volets=True, pignon=t(pv, 0.40, 0.50, 0.58, 1.0, 0.95)),
        "v_maison_chaume": maison(t(brun, 0.0, 0.2, 0.12, 0.8, 1.25), "plein", pignon=t(pb, 0.0, 0.2, 0.12, 0.8, 1.25)),
        "v_maison_rouge": maison(t(brun, 0.0, 0.2, 0.02, 1.35, 0.95), "fenetres", pignon=t(pb, 0.0, 0.2, 0.02, 1.35, 0.95)),
        "v_maison_pierre": maison(t(vert, 0.40, 0.50, 0.55, 0.35, 0.85), "brique", pignon=t(pv, 0.40, 0.50, 0.55, 0.35, 0.85)),
        "v_maison_bois": maison(t(brun, 0.0, 0.2, 0.07, 0.9, 0.7), "planches", pignon=t(pb, 0.0, 0.2, 0.07, 0.9, 0.7)),
        "v_maison_caserne": maison(vert, "brique", volets=True, pignon=pv),
    }
    for nom, im in maisons.items():
        im.save(os.path.join(SORTIE, nom + ".png"))
    print("maisons Pixel Crawler écrites :", {n: im.size for n, im in maisons.items()})
    if apercu:
        noms = list(maisons)
        W = sum(m.width for m in maisons.values()) + 8 * len(noms)
        H = max(m.height for m in maisons.values()) + 8
        toile = Image.new("RGBA", (W, H), (51, 118, 3, 255))
        x = 4
        for n in noms:
            toile.alpha_composite(maisons[n], (x, H - 4 - maisons[n].height)); x += maisons[n].width + 8
        h = Image.open(os.path.join(RACINE, "Assets/Heros/heros_marche.png")).convert("RGBA").crop((0, 0, 32, 32))
        toile.alpha_composite(h, (4 + 56 - 16, H - 36))
        toile.resize((toile.width * 2, toile.height * 2), Image.NEAREST).save(apercu)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
