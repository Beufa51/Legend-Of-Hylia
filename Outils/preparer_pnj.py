"""Outil de développement : fabrique les HABITANTS dans le style du héros (Assets/Heros/pnj_<Nom>.png) en RECOLORANT la planche du héros.
Chaque habitant = les 4 poses debout (bas, haut, gauche, droite), cases de 32 px. `pnj.gd` utilise ces fichiers quand ils existent
(sinon l'ancien habitant du pack Ninja Adventure du même nom). Pour un vrai nouveau personnage : mettre sa planche ici sous le même nom.
Usage : python3 Outils/preparer_pnj.py   (après preparer_heros.py)"""
import os, colorsys
import numpy as np
from PIL import Image

HEROS = os.path.join(os.path.dirname(__file__), "..", "Assets", "Heros")
# nom : (couleur des parties grises, force 0-1, luminosité, hauteur en pixels de la case 32 : 32 = taille normale, plus petit = enfant)
HABITANTS = {
    "Woman": ((205, 105, 150), 0.60, 1.10, 32),
    "OldMan": ((225, 220, 205), 0.55, 1.45, 32),
    "Boy": ((95, 175, 105), 0.60, 1.15, 25),
    "KnightGold": ((235, 195, 70), 0.65, 1.30, 32),
    "Villager": ((85, 165, 175), 0.60, 1.15, 32),
    "Villager2": ((165, 115, 75), 0.60, 1.10, 32),
    "Villager3": ((90, 125, 195), 0.60, 1.15, 32),
    "Villager4": ((195, 85, 75), 0.60, 1.15, 32),
    "Villager5": ((185, 185, 80), 0.60, 1.20, 32),
}


def recolorer(case, teinte, force, lum):
    a = np.array(case).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            r, g, b = a[y, x, :3] / 255.0
            h, s, v = colorsys.rgb_to_hsv(r, g, b)
            if s < 0.22 and 0.12 < v < 0.9:   # parties grises (armure, casque) : on les teinte en gardant les ombres
                cible = np.array(teinte) / 255.0 * min(1.0, v * 1.7)
                nouv = (1 - force) * np.array([r, g, b]) + force * cible
            else:
                nouv = np.array([r, g, b])
            a[y, x, :3] = np.clip(nouv * lum, 0, 1) * 255
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def main():
    marche = Image.open(os.path.join(HEROS, "heros_marche.png")).convert("RGBA")
    for nom, (teinte, force, lum, hauteur) in HABITANTS.items():
        sortie = Image.new("RGBA", (4 * 32, 32), (0, 0, 0, 0))
        for d in range(4):   # ligne d = direction ; colonne 0 = debout
            case = recolorer(marche.crop((0, d * 32, 32, d * 32 + 32)), teinte, force, lum)
            if hauteur != 32:   # enfant : plus petit, les pieds restent en bas de la case
                bb = case.getchannel("A").getbbox()
                corps = case.crop(bb)
                f = hauteur / (bb[3] - bb[1])
                corps = corps.resize((max(1, round(corps.width * f)), hauteur), Image.NEAREST)
                case = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
                case.alpha_composite(corps, ((32 - corps.width) // 2, bb[3] - hauteur))
            sortie.alpha_composite(case, (d * 32, 0))
        sortie.save(os.path.join(HEROS, "pnj_%s.png" % nom))
        print("pnj_%s.png" % nom)


if __name__ == "__main__":
    main()
