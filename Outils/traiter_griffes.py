"""Outil de développement : fabrique les STÈLES-GRIFFES du village EXACTEMENT comme les griffes de pierre de l'image du coq-forteresse
(Assets/Gemini/originaux/Coq_forteresse.jpg : les deux pieds du coq SONT les deux stèles). On découpe chaque griffe dans l'image, on retire le sol,
on réduit à la taille du village, on GRAVE le symbole de l'aile dans la paume (creux dans la pierre, sans cadre : il fait partie de la patte) et on fait 2 états : vide (gravure sombre) / pleine (gravure dorée, pierre qui rougeoie).
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


def masque_symbole(droite, taille=(13, 11)):
    """Le symbole d'une AILE (4 plumes en éventail, traits de 2 px) sous forme de masque L : c'est lui qu'on GRAVE dans la pierre de la paume."""
    w, h = taille
    m = Image.new("L", taille, 0)
    d = ImageDraw.Draw(m)
    racine = (1, h - 3)
    for (xp, yp) in ((w - 2, h - 5), (w - 3, h - 8), (w - 5, h - 11), (w - 8, h - 12)):
        d.line([racine, (xp, yp)], fill=255, width=2)
    d.rectangle((0, h - 4, 4, h - 1), fill=255)
    if droite:
        m = m.transpose(Image.FLIP_LEFT_RIGHT)
    return m


def eclaircir(pix, f):
    return tuple(max(0, min(255, int(v * f))) for v in pix[:3]) + (pix[3],)


def graver(base, droite, pleine, centre):
    """GRAVE le symbole dans la paume : un creux (pierre assombrie) avec un reflet sur le bord bas-droit, sans cadre ni boîte (rien ne dépasse de la patte).
    Allumé : les gravures se remplissent d'or et la pierre voisine rougeoie."""
    img = base.copy()
    px = img.load()
    cx, cy = centre
    m = masque_symbole(droite)
    mw, mh = m.size
    x0, y0 = cx - mw // 2, cy - mh // 2
    glyphe = {(x0 + x, y0 + y) for y in range(mh) for x in range(mw) if m.getpixel((x, y)) > 128}
    def pierre(x, y):
        return 0 <= x < img.width and 0 <= y < img.height and px[x, y][3] > 0
    if not pleine:
        for (x, y) in glyphe:
            if pierre(x, y):
                px[x, y] = eclaircir(px[x, y], 0.34)                      # le creux
        for (x, y) in {(x + 1, y + 1) for (x, y) in glyphe} - glyphe:     # reflet sur la lèvre bas-droite du creux
            if pierre(x, y):
                px[x, y] = eclaircir(px[x, y], 1.6)
        for (x, y) in {(x - 1, y - 1) for (x, y) in glyphe} - glyphe:     # ombre sur la lèvre haut-gauche
            if pierre(x, y):
                px[x, y] = eclaircir(px[x, y], 0.72)
    else:
        # rougeoiement de la pierre autour des gravures
        halo = Image.new("L", img.size, 0)
        for (x, y) in glyphe:
            halo.putpixel((x, y), 255)
        halo = halo.filter(ImageFilter.GaussianBlur(3.2))
        for y in range(img.height):
            for x in range(img.width):
                if pierre(x, y):
                    k = halo.getpixel((x, y)) / 255.0
                    if k > 0.04:
                        r, g, b, a = px[x, y]
                        px[x, y] = (min(255, int(r + 190 * k * 0.55)), min(255, int(g + 130 * k * 0.5)), min(255, int(b + 20 * k * 0.2)), a)
        for (x, y) in glyphe:
            if pierre(x, y):
                px[x, y] = OR_CLAIR + (255,) if (x + y) % 5 == 0 else OR + (255,)
        for (x, y) in {(x + 1, y + 1) for (x, y) in glyphe} - glyphe:     # le bord du creux garde un liseré sombre
            if pierre(x, y):
                px[x, y] = eclaircir(px[x, y], 0.7)
    return img


if __name__ == "__main__":
    largeur = int(sys.argv[1]) if len(sys.argv) > 1 else 72
    for cote, zone, miroir in (("g", ZONE_G, False), ("d", ZONE_D, True)):
        griffe = decouper(zone, POLY_G, miroir)
        petit = reduire(griffe, largeur)
        # centre de la paume : environ à 55 % de la largeur et 38 % de la hauteur (griffe gauche) ; symétrique pour la droite
        cx = round(petit.width * (0.69 if cote == "g" else 0.31))   # la paume (surface plate claire) : en haut, côté jambe
        cy = round(petit.height * 0.27)
        for etat, pleine in (("vide", False), ("pleine", True)):
            graver(petit, cote == "d", pleine, (cx, cy)).save(os.path.join(SORTIE, "v_stele_%s_%s.png" % (cote, etat)))
        print("griffe %s : %dx%d px, niche en (%d, %d)" % (cote, petit.width, petit.height, cx, cy))
