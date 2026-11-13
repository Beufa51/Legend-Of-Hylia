"""Outil de développement : refait les INTÉRIEURS (maisons, caserne, stand) avec les meubles et murs du pack Pixel Crawler.
Écrit les mêmes noms d'images que Scripts/interieur.gd attend (v_sol_*, v_mur_*, v_lit_*, v_table*, v_etagere...) dans Assets/Gemini/tuiles/.
Les emprises (en cases) des meubles sont dans la table MEUBLES de interieur.gd : elles ont été adaptées à la taille de ces images.
À lancer APRÈS traiter_village.py (qui crée les anciens meubles que ce script remplace), AVANT generer_village.py.
Usage : python3 Outils/traiter_interieur_pixelcrawler.py"""
import colorsys
import os

import numpy as np
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
BAT = os.path.join(RACINE, "Assets", "Pixel Crawler - Free Pack", "Environment", "Structures", "Buildings", "Interior")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
murs = Image.open(os.path.join(BAT, "Interior_Walls_01.png")).convert("RGBA")
props = Image.open(os.path.join(BAT, "Interior_Props_01.png")).convert("RGBA")


def rogner(im):
    return im.crop(im.getchannel("A").getbbox())


def ecrire(im, nom):
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im


def teinter(im, h0, h1, nouvelle, sat=1.0, lum=1.0):
    a = np.array(im).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.15 and h0 <= h <= h1:
                r, g, b = colorsys.hsv_to_rgb(nouvelle, min(1.0, s * sat), min(1.0, v * lum))
                a[y, x, :3] = (r * 255, g * 255, b * 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


# --- SOLS : parquet du pack (3 variantes) et dalles de pierre
for nom, base in (("v_sol_bois", (24, 600)), ("v_sol_bois_b", (40, 616)), ("v_sol_bois_c", (24, 616))):
    ecrire(murs.crop((base[0], base[1], base[0] + 16, base[1] + 16)), nom)
ecrire(murs.crop((110, 600, 126, 616)), "v_sol_pierre")

# --- MURS : pan de 32x32 = planches (en haut) + soubassement foncé (en bas) ; pierre pour la caserne
planches = murs.crop((407, 98, 439, 114))
soubassement = murs.crop((407, 128, 439, 144))
pan_bois = Image.new("RGBA", (32, 32))
pan_bois.alpha_composite(planches, (0, 0))
pan_bois.alpha_composite(soubassement, (0, 16))
pan_pierre = murs.crop((118, 98, 150, 130)).copy()
ecrire(murs.crop((407, 130, 423, 146)), "v_mur_bois")          # mur plein (côtés et bas) : le soubassement foncé
ecrire(murs.crop((120, 100, 136, 116)), "v_mur_pierre_16")

fenetre = rogner(props.crop((68, 177, 93, 208)))
tableau = rogner(props.crop((81, 320, 98, 336)))
ecrire(pan_bois, "v_mur_a")
ecrire(pan_bois.transpose(Image.FLIP_LEFT_RIGHT), "v_mur_b")
fen = pan_bois.copy(); fen.alpha_composite(fenetre, ((32 - fenetre.width) // 2, 1))
ecrire(fen, "v_mur_fenetre")
tab = pan_bois.copy(); tab.alpha_composite(tableau, ((32 - tableau.width) // 2, 5))
ecrire(tab, "v_mur_tableau")
foyer = rogner(props.crop((383, 98, 434, 144)))      # le four en briques (bouche à grille) sert de cheminée
foyer = foyer.crop(((foyer.width - 32) // 2, max(0, foyer.height - 32), (foyer.width + 32) // 2, foyer.height))
chem = pan_bois.copy(); chem.alpha_composite(foyer, (0, 32 - foyer.height))
ecrire(chem, "v_cheminee")
ecrire(pan_pierre, "v_mur_pierre")
chem2 = pan_pierre.copy(); chem2.alpha_composite(foyer, (0, 32 - foyer.height))
ecrire(chem2, "v_mur_pierre_cheminee")

# --- MEUBLES (images rognées ; posées bas-centre sur leur emprise)
lit = rogner(props.crop((0, 292, 32, 350)))
ecrire(teinter(lit, 0.5, 0.7, 0.0, 1.1, 1.0), "v_lit_rouge")
ecrire(lit, "v_lit_bleu")
ecrire(teinter(lit, 0.5, 0.7, 0.33, 0.45, 0.9), "v_lit_caserne")
ecrire(rogner(props.crop((175, 144, 224, 176))), "v_etagere")
ecrire(rogner(props.crop((2, 33, 31, 91))), "v_armoire")
ecrire(rogner(props.crop((79, 6, 113, 43))), "v_table_ronde")
ecrire(rogner(props.crop((1, 1, 64, 26))), "v_table")
ecrire(rogner(props.crop((1, 1, 64, 26))), "v_table_carte")
ecrire(rogner(props.crop((65, 2, 80, 28))), "v_chaise")
ecrire(rogner(props.crop((180, 74, 206, 98))), "v_coffre")
ecrire(rogner(props.crop((64, 257, 97, 289))), "v_coffre_armes")
ecrire(rogner(props.crop((223, 121, 241, 144))), "v_tonneau")
ecrire(rogner(props.crop((146, 130, 158, 144))), "v_pot")
ecrire(rogner(props.crop((130, 130, 142, 144))), "v_marmite")
ecrire(rogner(props.crop((128, 295, 176, 316))), "v_banc")
rack = rogner(props.crop((48, 150, 112, 173)))
ecrire(rack, "v_ratelier_lances")
ecrire(rack, "v_ratelier_armes")
bouclier = rogner(props.crop((129, 272, 143, 288)))
boucliers = Image.new("RGBA", (30, 16))
boucliers.alpha_composite(bouclier, (0, 0)); boucliers.alpha_composite(bouclier, (16, 0))
ecrire(boucliers, "v_boucliers")

# --- TAPIS et paillasson, dessinés (le pack n'en a pas)
def tapis(w, h, rond=False):
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    rouge, or_, fonce = (150, 40, 48, 255), (222, 176, 70, 255), (96, 22, 32, 255)
    forme = d.ellipse if rond else d.rectangle
    forme((0, 0, w - 1, h - 1), fill=fonce)
    forme((1, 1, w - 2, h - 2), fill=or_)
    forme((3, 3, w - 4, h - 4), fill=rouge)
    forme((6, 6, w - 7, h - 7), outline=or_)
    return im
ecrire(tapis(48, 30), "v_tapis_rouge")
ecrire(tapis(48, 48, True), "v_tapis_rond")
pail = Image.new("RGBA", (16, 16))
ImageDraw.Draw(pail).rectangle((1, 4, 14, 12), fill=(188, 150, 92, 255), outline=(96, 66, 36, 255))
ecrire(pail, "v_paillasson")
print("intérieurs Pixel Crawler écrits")
