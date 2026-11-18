"""Planche Gemini du décor de glace (2026-11-18) -> Assets/Gemini/tuiles/.
Source : Assets/Gemini/originaux/glace_decor.jpg (rocher pris dans la glace, colonne brisée givrée, congère + stalactites sur un mur,
congère seule, dalle de glace lisse sans / avec reflet). À lancer APRÈS traiter_lot3.py.

Écrit :
- rocher_glace.png (16x16)       : rocher pris dans un bloc de glace (lettre `k` du donjon, solide)
- colonne_givree.png (~13x30)    : colonne de pierre brisée et givrée (lettre `c`, solide, dépasse vers le haut)
- glace_lisse_1.png / _2.png     : dalle de glace UNIE (on prend l'intérieur de la dalle : pas de bordure, les cases se raccordent
                                   sans quadrillage) ; _2 = avec reflet (rare)
- stalactites.png (48 px de large) : rangée de stalactites qui pend sous le mur du haut des salles de glace
- congere.png (48 px de large)   : petit tas de neige posé contre un mur (décor sans collision)
"""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

os.chdir(os.path.join(os.path.dirname(__file__), ".."))
O = "Assets/Gemini/originaux/"
S = "Assets/Gemini/tuiles/"
a = np.array(Image.open(O + "glace_decor.jpg").convert("RGB")).astype(int)


def detourer(boite):
    """Découpe une boîte et retire le fond magenta (garde les morceaux assez gros)."""
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.02])
    m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)
    c[~m] = (200, 220, 235)
    al = (m * 255).astype(np.uint8)
    im = Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al)))
    return im.crop(im.getbbox())


def reduire(im, w, h):
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.6)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = im.split()[3].resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*rgb.split(), al))


def a_largeur(im, w):
    return reduire(im, w, max(1, round(im.height * w / im.width)))


def a_hauteur(im, h):
    return reduire(im, max(1, round(im.width * h / im.height)), h)


# Rocher pris dans la glace : le bloc entier remplit la case
reduire(detourer((40, 80, 240, 280)), 16, 16).save(S + "rocher_glace.png")
# Colonne brisée givrée : 30 px de haut (elle dépasse d'environ une case vers le haut, comme les statues)
a_hauteur(detourer((440, 80, 610, 460)), 30).save(S + "colonne_givree.png")

# Glace lisse : l'intérieur des dalles (sans leur cadre), carré, réduit en 16x16 opaque
for k, boite in enumerate([(800, 520, 990, 665), (1110, 515, 1300, 665)]):
    x0, y0, x1, y1 = boite
    im = Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)).resize((16, 16), Image.LANCZOS)
    px = np.array(im).astype(float) * np.array([0.74, 0.82, 0.90])   # un peu plus sombre et plus bleu : moins éblouissant à côté des murs
    Image.fromarray(px.clip(0, 255).astype(np.uint8)).convert("RGBA").save(S + "glace_lisse_%d.png" % (k + 1))

# Stalactites : la rangée de glaçons sous le mur (à gauche de la congère), sans les briques
st = detourer((742, 226, 905, 302))
px = np.array(st)                     # le fond sombre (briques) entre les glaçons devient transparent : on ne garde que la glace
px[..., 3] = np.where(px[..., :3].sum(axis=2) < 230, 0, px[..., 3])
st = Image.fromarray(px)
a_largeur(st, 48).save(S + "stalactites.png")
# Congère seule : 48 px de large
a_largeur(detourer((30, 530, 710, 700)), 48).save(S + "congere.png")

for n in ["rocher_glace", "colonne_givree", "glace_lisse_1", "glace_lisse_2", "stalactites", "congere"]:
    print(n, Image.open(S + n + ".png").size)

# --- 2e planche (2026-11-18) : originaux/glace_decor2.jpg -------------------------------------------------------
# GIVRE sur le haut des murs (remplace les stalactites), congère de coin, statue prise dans la glace, pilier givré, dalle de sol enneigée.
a = np.array(Image.open(O + "glace_decor2.jpg").convert("RGB")).astype(int)
# Givre : la bande de neige + petits glaçons du morceau du milieu, sans les briques (pixels sombres -> transparents)
g = detourer((345, 32, 680, 112))
px = np.array(g)
px[..., 3] = np.where(px[..., :3].sum(axis=2) < 260, 0, px[..., 3])
a_largeur(Image.fromarray(px), 48).save(S + "givre_mur.png")
# Congère (sans le coin de mur)
a_largeur(detourer((255, 372, 515, 562)), 30).save(S + "congere_coin.png")
# Statue de chevalier prise dans la glace (lettre c) et pilier givré (lettre k)
a_hauteur(detourer((710, 286, 908, 688)), 30).save(S + "statue_glace.png")
a_hauteur(detourer((450, 710, 576, 920)), 22).save(S + "pilier_givre.png")
# Dalle de sol enneigée (îlots de sol au milieu de la glace, quai) : opaque 16x16
d = Image.fromarray(a[770:960, 700:916].astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)).resize((16, 16), Image.LANCZOS)
d.convert("RGBA").save(S + "sol_neige.png")
for n in ["givre_mur", "congere_coin", "statue_glace", "pilier_givre", "sol_neige"]:
    print(n, Image.open(S + n + ".png").size)
