"""Outil de développement : fabrique les HABITANTS à partir des personnages du pack Pixel Crawler (Assets/Pixel Crawler - Free Pack/Entities/Npc's).
Écrit Assets/Heros/pnj_<Nom>.png (4 cases de 32 px : bas, haut, gauche, droite) ; `pnj.gd` les utilise automatiquement.
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

# nom du fichier pnj_<nom>.png : (planche, taille d'une case, décalage de teinte (h0, h1, nouvelle teinte, saturation x) ou None, hauteur voulue ou None)
HABITANTS = {
    "Woman":      ("Citizen_F/Peasant_A/Idle/Idle-Sheet.png", 64, None, None),
    "Villager":   ("Citizen_F/Tavern_A/Idle/Idle_Side-Sheet.png", 64, None, None),
    "Villager5":  ("Citizen_F/Tavern_B/Idle/Idle_Side-Sheet.png", 64, (0.85, 1.0, 0.50, 1.0), None),   # corsage prune -> turquoise
    "Villager4":  ("Rogue/Idle/Idle-Sheet.png", 32, None, None),
    "OldMan":     ("Wizzard/Idle/Idle-Sheet.png", 32, (0.70, 0.90, 0.30, 0.9), None),                  # robe violette -> verte
    "KnightGold": ("Knight/Idle/Idle-Sheet.png", 32, (0.45, 0.70, 0.12, 1.6), None),                   # acier bleu -> or
    "Villager3":  ("Knight/Idle/Idle-Sheet.png", 32, None, None),
    "Boy":        ("Citizen_F/Tavern_A/Idle/Idle_Side-Sheet.png", 64, (0.80, 1.0, 0.58, 1.1), 23),     # plus petit (enfant), corsage bleu
}


def decaler_teinte(img, h0, h1, nouv, sat):
    a = np.array(img).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.18 and h0 <= h <= h1:
                r, g, b = colorsys.hsv_to_rgb(nouv + (h - (h0 + h1) / 2) * 0.3, min(1.0, s * sat), v)
                a[y, x, :3] = (r * 255, g * 255, b * 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def fabriquer(nom, planche, case, teinte, hauteur):
    feuille = Image.open(os.path.join(PACK, planche)).convert("RGBA")
    perso = feuille.crop((0, 0, case, feuille.height))    # première image de l'animation « au repos »
    if teinte:
        perso = decaler_teinte(perso, *teinte)
    perso = perso.crop(perso.getchannel("A").getbbox())    # on ne garde que le personnage
    if hauteur and perso.height > hauteur:
        perso = perso.resize((max(1, round(perso.width * hauteur / perso.height)), hauteur), Image.NEAREST)
    droite = Image.new("RGBA", (32, 32))
    droite.alpha_composite(perso, ((32 - perso.width) // 2, 32 - perso.height))   # centré, les pieds en bas de la case
    gauche = droite.transpose(Image.FLIP_LEFT_RIGHT)
    sortie = Image.new("RGBA", (128, 32))
    for i, c in enumerate((droite, gauche, gauche, droite)):   # bas, haut, gauche, droite
        sortie.alpha_composite(c, (i * 32, 0))
    sortie.save(os.path.join(SORTIE, "pnj_%s.png" % nom))


if __name__ == "__main__":
    for nom, (planche, case, teinte, hauteur) in HABITANTS.items():
        fabriquer(nom, planche, case, teinte, hauteur)
    print("habitants écrits :", ", ".join(HABITANTS))
