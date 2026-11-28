"""Fabrique les PNJ du village à partir du pack « Super Retro World — Character Pack » (style RPG Maker MV).

Source : Assets/PNG/SuperRetroWorld_CharacterPack_Full/rpgmaker/MV/characters/_srw_character_1-8.png
(8 personnages, 4 par ligne, 2 lignes ; chaque personnage = 3 images de marche x 4 directions, cases de 48 x 60).
Ordre des directions dans la planche MV : 0 bas, 1 gauche, 2 droite, 3 haut.

Sortie (Assets/Heros, cases de 32 px, comme pnj.gd l'attend) :
  pnj_<Nom>.png        4 poses fixes : bas, haut, gauche, droite
  pnj_<Nom>_repos.png  4 images x 3 vues (bas, haut, côté)
  pnj_<Nom>_marche.png 6 images x 3 vues (bas, haut, côté)
Crédit obligatoire des auteurs (voir LICENCE.txt du pack) : @gif_not_jif, @Noiracide, @DessRomaric.
Usage : python3 Outils/preparer_pnj_superretro.py
"""
from PIL import Image

PLANCHE = "Assets/PNG/SuperRetroWorld_CharacterPack_Full/rpgmaker/MV/characters/_srw_character_1-8.png"
DOSSIER = "Assets/Heros/"
CASE_W, CASE_H = 48, 60
CASE = 32
HAUTEUR_VISIBLE = 27   # le personnage fait environ 27 px de haut, comme les anciens PNJ
MV_DIR = {"bas": 0, "gauche": 1, "droite": 2, "haut": 3}
# Personnage du pack (numéro 1 à 8, dans l'ordre de la planche) pour chaque PNJ du village
CHOIX = {"OldMan": 4, "Woman": 5, "Villager5": 2, "Villager4": 7, "Villager": 6, "Villager2": 3, "Boy": 1}

planche = Image.open(PLANCHE).convert("RGBA")


def personnage(numero):
    """Renvoie {direction: [3 images 48x60]} pour le personnage n (1 à 8)."""
    k = numero - 1
    x0 = (k % 4) * 3 * CASE_W
    y0 = (k // 4) * 4 * CASE_H
    return {d: [planche.crop((x0 + c * CASE_W, y0 + r * CASE_H, x0 + (c + 1) * CASE_W, y0 + (r + 1) * CASE_H))
                for c in range(3)] for d, r in MV_DIR.items()}


def mise_a_echelle(images):
    """Même échelle et même cadrage pour toutes les images d'un personnage (les pieds restent à la même hauteur)."""
    boites = [im.getbbox() for fr in images.values() for im in fr if im.getbbox()]
    gauche = min(b[0] for b in boites); haut = min(b[1] for b in boites)
    droite = max(b[2] for b in boites); bas = max(b[3] for b in boites)
    hauteur = bas - haut
    echelle = min(1.0, HAUTEUR_VISIBLE / hauteur)
    sortie = {}
    for d, fr in images.items():
        sortie[d] = []
        for im in fr:
            rogne = im.crop((gauche, haut, droite, bas))
            if echelle < 1:
                rogne = rogne.resize((round(rogne.width * echelle), round(rogne.height * echelle)), Image.LANCZOS)
            sortie[d].append(rogne)
    return sortie


def case_32(im):
    """Une image dans une case de 32 px : centrée horizontalement, pieds posés au bas de la case."""
    c = Image.new("RGBA", (CASE, CASE), (0, 0, 0, 0))
    c.paste(im, ((CASE - im.width) // 2, CASE - 2 - im.height), im)
    return c


for nom, numero in CHOIX.items():
    p = mise_a_echelle(personnage(numero))
    # pose fixe : bas, haut, gauche, droite (image 2 de la marche = debout)
    fixes = Image.new("RGBA", (4 * CASE, CASE), (0, 0, 0, 0))
    for i, d in enumerate(["bas", "haut", "gauche", "droite"]):
        fixes.paste(case_32(p[d][1]), (i * CASE, 0), case_32(p[d][1]))
    fixes.save(DOSSIER + "pnj_%s.png" % nom)
    vues = ["bas", "haut", "droite"]   # gauche = miroir côté droite (pnj.gd)
    repos = Image.new("RGBA", (4 * CASE, 3 * CASE), (0, 0, 0, 0))
    marche = Image.new("RGBA", (6 * CASE, 3 * CASE), (0, 0, 0, 0))
    for r, d in enumerate(vues):
        for c, k in enumerate([1, 0, 1, 2]):
            repos.paste(case_32(p[d][k]), (c * CASE, r * CASE), case_32(p[d][k]))
        for c, k in enumerate([0, 1, 2, 1, 0, 1]):
            marche.paste(case_32(p[d][k]), (c * CASE, r * CASE), case_32(p[d][k]))
    repos.save(DOSSIER + "pnj_%s_repos.png" % nom)
    marche.save(DOSSIER + "pnj_%s_marche.png" % nom)
    print("ok", nom, "<- personnage", numero)
