"""Outil de développement (APRÈS fabriquer_objets.py) : dessine les DEUX STÈLES en forme de PATTES de coq (parvis du village).
Chaque stèle = une dalle de pierre surmontée de TROIS GRIFFES (les orteils du coq) et d'une niche où l'on dépose le symbole d'une aile.
  v_stele_g_vide / v_stele_g_pleine : stèle de l'aile gauche (symbole de l'aile gauche, vide = gravure sombre, pleine = symbole doré qui brille)
  v_stele_d_vide / v_stele_d_pleine : stèle de l'aile droite (symbole retourné)
Images 32x48, posées sur une case (emprise 1x1, le haut dépasse). Usage : python3 Outils/fabriquer_steles_pattes.py"""
import os
from PIL import Image, ImageDraw, ImageFilter

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR = (16, 20, 32, 255)
CLAIR = (156, 170, 198, 255)
MOYEN = (104, 118, 150, 255)
SOMBRE = (66, 76, 106, 255)
NICHE = (22, 26, 42, 255)
OR = (244, 194, 74, 255)
OR_CLAIR = (255, 234, 150, 255)
OR_SOMBRE = (150, 110, 40, 255)


def symbole(droite, couleur, taille=(12, 12)):
    """Le symbole d'une AILE : 4 plumes qui s'allongent (la plus courte près de la racine), dessinées d'une seule couleur (aile gauche ; `droite` = retournée)."""
    w, h = taille
    img = Image.new("RGBA", taille, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    racine = (1, h - 2)
    for (x_pointe, y_pointe) in ((w - 1, h - 4), (w - 2, h - 7), (w - 4, h - 10), (w - 7, h - 11)):   # 4 plumes en éventail
        d.line([racine, (x_pointe, y_pointe)], fill=couleur, width=1)
        d.line([(racine[0] + 1, racine[1] + 1), (x_pointe, y_pointe + 1)], fill=couleur, width=1)
        d.point((x_pointe, y_pointe), fill=couleur)
    d.rectangle((0, h - 3, 3, h - 1), fill=couleur)    # la racine de l'aile
    if droite:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def griffe(d, pointe, base_g, base_d, y_base):
    """Une griffe : un triangle effilé de pierre, plus clair sur le bord gauche."""
    d.polygon([(base_g, y_base), (pointe[0], pointe[1]), (base_d, y_base)], fill=MOYEN, outline=CONTOUR)
    d.line([(base_g + 1, y_base - 1), (pointe[0], pointe[1] + 1)], fill=CLAIR)
    d.line([(base_d - 1, y_base - 1), (pointe[0] + 1, pointe[1] + 2)], fill=SOMBRE)
    for k in (0.35, 0.62):                                   # articulations de l'orteil
        y = int(y_base + (pointe[1] - y_base) * k)
        x = int((base_g + base_d) / 2 + (pointe[0] - (base_g + base_d) / 2) * k)
        d.line([(x - 2, y), (x + 2, y)], fill=SOMBRE)


def stele(droite, pleine):
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # socle
    d.rectangle((1, 42, 30, 47), fill=SOMBRE, outline=CONTOUR)
    d.line((2, 43, 29, 43), fill=CLAIR)
    # trois griffes (les orteils du coq) : celle du milieu plus longue
    griffe(d, (4, 5), 5, 12, 22)
    griffe(d, (16, 0), 12, 20, 22)
    griffe(d, (28, 5), 20, 27, 22)
    # dalle
    d.rectangle((5, 19, 26, 42), fill=MOYEN, outline=CONTOUR)
    d.line((6, 20, 25, 20), fill=CLAIR)
    d.line((6, 20, 6, 41), fill=CLAIR)
    d.line((25, 21, 25, 41), fill=SOMBRE)
    d.line((6, 41, 25, 41), fill=SOMBRE)
    # niche
    d.rectangle((8, 23, 23, 38), fill=NICHE, outline=CONTOUR)
    d.line((10, 38, 21, 38), fill=(92, 104, 136, 255))                       # rebord éclairé en bas
    sym = symbole(droite, OR if pleine else (54, 64, 98, 255))
    img.alpha_composite(sym, (10, 26))
    if pleine:
        lueur = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
        lueur.alpha_composite(symbole(droite, OR_CLAIR, (14, 14)), (9, 25))
        lueur = lueur.filter(ImageFilter.GaussianBlur(2.2))
        halo = Image.new("RGBA", (32, 48), (255, 214, 110, 0))
        halo.putalpha(lueur.split()[3].point(lambda v: min(150, v * 2)))
        out = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
        out.alpha_composite(img)
        # le halo n'éclaire que l'intérieur de la niche
        cache = Image.new("L", (32, 48), 0)
        ImageDraw.Draw(cache).rectangle((9, 24, 22, 37), fill=255)
        halo.putalpha(Image.composite(halo.split()[3], Image.new("L", (32, 48), 0), cache))
        out.alpha_composite(halo)
        out.alpha_composite(sym, (10, 26))
        # griffes qui brillent légèrement
        for (x, y) in ((4, 5), (16, 0), (28, 5)):
            out.putpixel((x, y), OR_CLAIR)
        img = out
    return img


if __name__ == "__main__":
    for cote, droite in (("g", False), ("d", True)):
        for etat, pleine in (("vide", False), ("pleine", True)):
            stele(droite, pleine).save(os.path.join(SORTIE, "v_stele_%s_%s.png" % (cote, etat)))
    print("stèles-pattes fabriquées")
