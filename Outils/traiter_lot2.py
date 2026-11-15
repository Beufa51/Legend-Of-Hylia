"""Lot 2 de planches Gemini (2026-11-15) -> Assets/Gemini/tuiles/ et Assets/Heros/.
À lancer APRÈS traiter_lot_donjon.py (sentinelles), fabriquer_escalier.py (escalier) et preparer_pnj / habiller_pnj (garde).

- originaux/sentinelle2.jpg : 4 poses (bas, haut, droite, ALERTE) sur socle -> sentinelle_bas|haut|droite|alerte.png (même échelle, textes de la planche exclus)
- originaux/escalier.jpg    : escalier sombre (-> escalier_donjon.png 48x48) et éclairé (-> escalier_lumiere.png, non utilisé)
- originaux/icones.jpg      : plume (vide / pleine / éclat), clé, cadenas, coeurs, insigne, coq, aile de pierre
                              -> icone_*.png, fragment_aile.png (aile de pierre aux plumes dorées)
- originaux/garde_pnj.jpg   : garde du village (bas, haut, côté, bras croisés) -> Assets/Heros/pnj_Villager3_repos.png / _marche.png
Non traités ici : heros.jpg (héros, toutes ses animations) et gardien.jpg (boss) : à intégrer à part.
"""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

O = "Assets/Gemini/originaux/"
S = "Assets/Gemini/tuiles/"


def charger(nom):
    return np.array(Image.open(O + nom).convert("RGB")).astype(int)


def detourer(a, boite):
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.02])
    m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)
    c[~m] = (16, 16, 22)
    al = (m * 255).astype(np.uint8)
    return Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al)))


def reduire(im, w, h):
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.6)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = im.split()[3].resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*rgb.split(), al))


def a_hauteur(im, h):
    return reduire(im, max(1, round(im.width * h / im.height)), h)


def a_largeur(im, w):
    return reduire(im, w, max(1, round(im.height * w / im.width)))


# --- Sentinelles : même échelle pour les 4 poses (celle de la pose « bas ») ----------------------
a = charger("sentinelle2.jpg")
boites = {"bas": (40, 85, 350, 650), "haut": (385, 75, 695, 650), "droite": (770, 60, 1015, 650), "alerte": (1035, 105, 1380, 650)}
ims = {n: detourer(a, b) for n, b in boites.items()}
bas = ims["bas"].getbbox()
echelle = 34 / (bas[3] - bas[1])
for n, im in ims.items():
    bb = im.getbbox()
    im = im.crop(bb)
    reduire(im, max(1, round(im.width * echelle)), max(1, round(im.height * echelle))).save(S + "sentinelle_%s.png" % n)
print("sentinelle_bas|haut|droite|alerte")

# --- Escalier ---------------------------------------------------------------------------------
a = charger("escalier.jpg")
for nom, boite in (("escalier_donjon", (55, 40, 675, 722)), ("escalier_lumiere", (735, 40, 1355, 722))):
    im = detourer(a, boite)
    im = im.crop(im.getbbox())
    reduire(im, 48, 48).save(S + nom + ".png")
print("escalier_donjon (48x48), escalier_lumiere")

# --- Icônes -----------------------------------------------------------------------------------
a = charger("icones.jpg")
icones = {
    "icone_plume_vide": ((50, 75, 270, 300), 16, "h"), "icone_plume_pleine": ((280, 70, 480, 300), 16, "h"), "icone_plume_eclat": ((530, 55, 710, 300), 16, "h"),
    "cle": ((90, 330, 200, 530), 12, "h"), "cadenas": ((290, 335, 445, 530), 12, "h"),
    "icone_coeur_plein": ((55, 565, 235, 740), 14, "w"), "icone_coeur_demi": ((270, 565, 450, 740), 14, "w"), "icone_coeur_vide": ((490, 565, 670, 740), 14, "w"),
    "icone_insigne": ((955, 495, 1170, 700), 16, "w"), "icone_coq": ((1200, 540, 1365, 735), 14, "h"),
}
for nom, (boite, taille, axe) in icones.items():
    im = detourer(a, boite)
    im = im.crop(im.getbbox())
    (a_hauteur if axe == "h" else a_largeur)(im, taille).save(S + nom + ".png")
aile = detourer(a, (770, 50, 1360, 450))
aile = aile.crop(aile.getbbox())
a_largeur(aile, 26).save(S + "fragment_aile.png")
Image.open(S + "icone_plume_pleine.png").save(S + "plume_doree_icone.png")
print("icones + fragment_aile", Image.open(S + "fragment_aile.png").size)

# --- Garde du village (PNJ) : planches 32x32, 3 rangées (bas, haut, côté), 4 images au repos / 6 à la marche ----
a = charger("garde_pnj.jpg")
poses = {"bas": (60, 80, 355, 700), "haut": (410, 75, 700, 700), "cote": (790, 85, 1015, 700)}
gardes = {n: detourer(a, b) for n, b in poses.items()}
ref = gardes["bas"].getbbox()
ech = 27 / (ref[3] - ref[1])
petits = {}
for n, im in gardes.items():
    im = im.crop(im.getbbox())
    petits[n] = reduire(im, max(1, round(im.width * ech)), max(1, round(im.height * ech)))


def planche(images, rebond):
    feuille = Image.new("RGBA", (32 * images, 96), (0, 0, 0, 0))
    for r, n in enumerate(("bas", "haut", "cote")):
        p = petits[n]
        for i in range(images):
            feuille.alpha_composite(p, (i * 32 + (32 - p.width) // 2, r * 32 + 31 - p.height + rebond[i % len(rebond)]))
    return feuille


planche(4, [0, 0, 1, 0]).save("Assets/Heros/pnj_Villager3_repos.png")
planche(6, [0, -1, 0, 0, -1, 0]).save("Assets/Heros/pnj_Villager3_marche.png")
print("garde du village : repos 128x96, marche 192x96")
