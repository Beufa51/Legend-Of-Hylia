"""Outil de développement : fabrique les HABITANTS à partir des personnages du pack Pixel Crawler (Assets/Pixel Crawler - Free Pack/Entities/Npc's).
Écrit Assets/Heros/pnj_<Nom>.png (4 cases de 32 px : bas, haut, gauche, droite), pnj_<Nom>_repos.png (4 images) et pnj_<Nom>_marche.png (6 images) ; `pnj.gd` les utilise automatiquement.
À lancer APRÈS preparer_pnj.py (il remplace les noms qu'il connaît, les autres restent des recolorations du héros).
Les personnages du pack sont vus de PROFIL (regard à droite) : « droite » = tel quel, « gauche » = miroir, « bas » et « haut » reprennent le profil.
Usage : python3 Outils/preparer_pnj_pixelcrawler.py"""
import colorsys
import os
import numpy as np
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
PACK = os.path.join(RACINE, "Assets", "Pixel Crawler - Free Pack", "Entities", "Npc's")
SORTIE = os.path.join(RACINE, "Assets", "Heros")

# nom du fichier pnj_<nom>.png : (planche « repos », case, planche « marche », décalage de teinte (h0, h1, nouvelle teinte, saturation x) ou None, hauteur voulue ou None)
CIT = "Citizen_F/%s/"
HABITANTS = {
    "Woman":      (CIT % "Peasant_A" + "Idle/Idle-Sheet.png", 64, CIT % "Peasant_A" + "Walk/Walk-Sheet.png", None, None),
    "Villager":   (CIT % "Tavern_A" + "Idle/Idle_Side-Sheet.png", 64, CIT % "Tavern_A" + "Walk/Walk_Side-Sheet.png", None, None),
    "Villager5":  (CIT % "Tavern_B" + "Idle/Idle_Side-Sheet.png", 64, CIT % "Tavern_B" + "Walk/Walk_Side-Sheet.png", (0.85, 1.0, 0.50, 1.0), None),   # corsage prune -> turquoise
    "Villager4":  ("Rogue/Idle/Idle-Sheet.png", 32, "Rogue/Run/Run-Sheet.png", None, None),
    "OldMan":     ("Wizzard/Idle/Idle-Sheet.png", 32, "Wizzard/Run/Run-Sheet.png", (0.70, 0.90, 0.30, 0.5, 0.78), None),                  # robe violette -> vert sauge (sobre)
    "KnightGold": ("Knight/Idle/Idle-Sheet.png", 32, "Knight/Run/Run-Sheet.png", (0.45, 0.70, 0.12, 1.6), None),                   # acier bleu -> or
    "Villager3":  ("Knight/Idle/Idle-Sheet.png", 32, "Knight/Run/Run-Sheet.png", None, None),
    "Boy":        (CIT % "Tavern_A" + "Idle/Idle_Side-Sheet.png", 64, CIT % "Tavern_A" + "Walk/Walk_Side-Sheet.png", (0.80, 1.0, 0.58, 1.1), 23),   # plus petit (enfant)
}


def decaler_teinte(img, h0, h1, nouv, sat, lum=1.0):
    a = np.array(img).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.18 and h0 <= h <= h1:
                r, g, b = colorsys.hsv_to_rgb(nouv + (h - (h0 + h1) / 2) * 0.3, min(1.0, s * sat), min(1.0, v * lum))
                a[y, x, :3] = (r * 255, g * 255, b * 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def bande(planche, case, teinte, hauteur):
    """Toutes les images d'une animation (regard à DROITE), chacune posée dans une case de 32 px, pieds en bas.
    Toutes les images sont rognées avec la MÊME boîte (celle de l'ensemble) : le balancement de la marche est conservé."""
    feuille = Image.open(os.path.join(PACK, planche)).convert("RGBA")
    images = [feuille.crop((i * case, 0, i * case + case, feuille.height)) for i in range(feuille.width // case)]
    if teinte:
        images = [decaler_teinte(im, *teinte) for im in images]
    boites = [im.getchannel("A").getbbox() for im in images]
    x0, y0 = min(b[0] for b in boites), min(b[1] for b in boites)
    x1, y1 = max(b[2] for b in boites), max(b[3] for b in boites)
    sortie = []
    for im in images:
        perso = im.crop((x0, y0, x1, y1))
        if hauteur and perso.height > hauteur:
            perso = perso.resize((max(1, round(perso.width * hauteur / perso.height)), hauteur), Image.NEAREST)
        case32 = Image.new("RGBA", (32, 32))
        case32.alpha_composite(perso, ((32 - perso.width) // 2, 32 - perso.height))   # centré, les pieds en bas de la case
        sortie.append(case32)
    return sortie


def planche_horizontale(images):
    s = Image.new("RGBA", (32 * len(images), 32))
    for i, c in enumerate(images):
        s.alpha_composite(c, (i * 32, 0))
    return s


def fabriquer(nom, repos, case, marche, teinte, hauteur):
    images_repos = bande(repos, case, teinte, hauteur)
    droite = images_repos[0]
    gauche = droite.transpose(Image.FLIP_LEFT_RIGHT)
    planche_horizontale([droite, gauche, gauche, droite]).save(os.path.join(SORTIE, "pnj_%s.png" % nom))   # bas, haut, gauche, droite
    planche_horizontale(images_repos).save(os.path.join(SORTIE, "pnj_%s_repos.png" % nom))                # animation « au repos » (regard à droite)
    planche_horizontale(bande(marche, 64, teinte, hauteur)).save(os.path.join(SORTIE, "pnj_%s_marche.png" % nom))   # animation de marche (6 images, regard à droite)


if __name__ == "__main__":
    for nom, (repos, case, marche, teinte, hauteur) in HABITANTS.items():
        fabriquer(nom, repos, case, marche, teinte, hauteur)
    print("habitants écrits :", ", ".join(HABITANTS))
