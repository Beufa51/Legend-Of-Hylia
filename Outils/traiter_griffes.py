"""Outil de développement : fabrique les STÈLES-GRIFFES du village EXACTEMENT comme les griffes de pierre de l'image du coq-forteresse
(Assets/Gemini/originaux/Coq_forteresse.jpg : les deux pieds du coq SONT les deux stèles). On découpe chaque griffe dans l'image, on retire le sol,
on réduit à la taille du village, on creuse une NICHE dans la paume (là où se pose le symbole de l'aile) et on fait 2 états : vide / pleine (symbole doré qui brille).
  griffe GAUCHE (pied gauche de l'image) = stèle de l'aile gauche : v_stele_g_vide.png / v_stele_g_pleine.png
  griffe DROITE = stèle de l'aile droite : v_stele_d_vide.png / v_stele_d_pleine.png
Usage : python3 Outils/traiter_griffes.py [largeur_px]    (défaut 72)"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

RACINE = os.path.join(os.path.dirname(__file__), "..")
SOURCE = os.path.join(RACINE, "Assets", "Gemini", "originaux", "Coq_forteresse.jpg")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
ZONE_G = (400, 580, 600, 735)        # griffe gauche dans l'image 1408x768
ZONE_D = (808, 580, 1008, 735)       # griffe droite
# contour de la griffe dans la zone (coordonnées de la zone, griffe gauche) : le pied seulement, sans la tour de la patte
POLY_G = [(8, 105), (18, 80), (80, 52), (112, 38), (132, 36), (146, 48), (158, 46), (176, 50), (176, 60), (166, 66), (168, 112), (162, 140), (154, 142), (146, 112), (120, 100), (84, 110), (68, 140), (54, 138), (56, 110), (26, 112), (12, 114)]
OR = (244, 194, 74)
OR_CLAIR = (255, 234, 150)
NICHE = (18, 22, 38)


def sol(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (g > b + 6) & (g > r + 10)


def decouper(zone, poly, miroir=False):
    im = Image.open(SOURCE).convert("RGB").crop(zone)
    w, h = im.size
    if miroir:
        poly = [(w - x, y) for x, y in poly]
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    masque = (np.array(m) > 0) & ~sol(np.array(im))
    alpha = Image.fromarray((masque * 255).astype("uint8")).filter(ImageFilter.MedianFilter(3))
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba.crop(rgba.getbbox())


def reduire(img, largeur):
    h = round(img.height * largeur / img.width)
    petit = img.resize((largeur, h), Image.LANCZOS)
    # renforcement + alpha net (pixel-art : pas de bords flous)
    rgb = petit.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1, percent=90, threshold=2))
    rgb = ImageEnhance.Brightness(rgb).enhance(1.22)   # un peu plus claires : sur l'herbe du village elles doivent bien se lire
    alpha = petit.split()[3].point(lambda v: 255 if v > 110 else 0)
    q = rgb.quantize(colors=28, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    out = q.convert("RGBA")
    out.putalpha(alpha)
    return out


def symbole(droite, couleur, taille):
    """Symbole d'aile : 4 plumes en éventail (même dessin que sur les icônes du HUD)."""
    w, h = taille
    img = Image.new("RGBA", taille, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    racine = (1, h - 2)
    for (xp, yp) in ((w - 1, h - 4), (w - 2, h - 7), (w - 4, h - 10), (w - 7, h - 11)):
        d.line([racine, (xp, yp)], fill=couleur, width=1)
        d.line([(racine[0] + 1, racine[1] + 1), (xp, yp + 1)], fill=couleur, width=1)
    d.rectangle((0, h - 3, 3, h - 1), fill=couleur)
    if droite:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def avec_niche(base, droite, pleine, centre):
    """Creuse la niche dans la paume (centre = (x, y) dans l'image) et y met le symbole."""
    img = base.copy()
    d = ImageDraw.Draw(img)
    cx, cy = centre
    x0, y0, x1, y1 = cx - 8, cy - 6, cx + 8, cy + 6
    d.rounded_rectangle((x0 - 1, y0 - 1, x1 + 1, y1 + 1), radius=3, fill=(150, 164, 192, 255))     # rebord de pierre éclairé
    d.rounded_rectangle((x0, y0, x1, y1), radius=3, fill=NICHE + (255,))
    d.line((x0 + 2, y1, x1 - 2, y1), fill=(96, 108, 140, 255))
    sym = symbole(droite, OR if pleine else (52, 62, 96, 255), (13, 11))
    if pleine:
        halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
        halo.alpha_composite(symbole(droite, OR_CLAIR, (15, 13)), (cx - 7, cy - 6))
        halo = halo.filter(ImageFilter.GaussianBlur(2.4))
        lueur = Image.new("RGBA", img.size, (255, 214, 110, 0))
        lueur.putalpha(halo.split()[3].point(lambda v: min(170, v * 2)))
        cache = Image.new("L", img.size, 0)
        ImageDraw.Draw(cache).rounded_rectangle((x0, y0, x1, y1), radius=3, fill=255)
        lueur.putalpha(Image.composite(lueur.split()[3], Image.new("L", img.size, 0), cache))
        img.alpha_composite(lueur)
    img.alpha_composite(sym, (cx - 6, cy - 5))
    return img


if __name__ == "__main__":
    largeur = int(sys.argv[1]) if len(sys.argv) > 1 else 72
    for cote, zone, miroir in (("g", ZONE_G, False), ("d", ZONE_D, True)):
        griffe = decouper(zone, POLY_G, miroir)
        petit = reduire(griffe, largeur)
        # centre de la paume : environ à 55 % de la largeur et 38 % de la hauteur (griffe gauche) ; symétrique pour la droite
        cx = round(petit.width * (0.50 if cote == "g" else 0.50))
        cy = round(petit.height * 0.40)
        for etat, pleine in (("vide", False), ("pleine", True)):
            avec_niche(petit, cote == "d", pleine, (cx, cy)).save(os.path.join(SORTIE, "v_stele_%s_%s.png" % (cote, etat)))
        print("griffe %s : %dx%d px, niche en (%d, %d)" % (cote, petit.width, petit.height, cx, cy))
