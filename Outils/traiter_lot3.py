"""Lot 3 de planches Gemini (2026-11-15) -> Assets/Gemini/tuiles/.
À lancer APRÈS tous les autres traiter_* / fabriquer_* du village et du donjon (il remplace des images qu'ils écrivent), AVANT generer_village.py.

- originaux/village_objets.jpg : tonneau, caisse, étal de marché, panneau, clôture, poteau, banc, puits, bannière au coq, seau, foin, pot de fleurs
    -> v_tonneau, v_caisse, v_etal (NOUVEAU : lettre E), v_panneau, v_cloture, v_poteau, v_puits, v_banniere
       + disponibles non placés : v_banc, v_seau, v_foin, v_pot_fleurs, v_tonneau2, v_caisse2
- originaux/glace.jpg : 4 dalles de glace fissurées + 2 à étincelle -> glace_1..4 (communes), glace_5/6 (étincelle, rares)
- originaux/frise.jpg : 4 bandeaux de symboles dorés (plume, coq, losange, zigzag) -> frise_<bandeau 1..4>_<colonne 0..6> (16x12 chacune, 7 colonnes qui se suivent)
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
    im = Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al)))
    return im.crop(im.getbbox())


def reduire(im, w, h):
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.6)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = im.split()[3].resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*rgb.split(), al))


def a_hauteur(im, h):
    return reduire(im, max(1, round(im.width * h / im.height)), h)


def a_largeur(im, w):
    return reduire(im, w, max(1, round(im.height * w / im.width)))


# --- Objets du village --------------------------------------------------------------------------
a = charger("village_objets.jpg")
objets = {
    "v_tonneau": ((30, 28, 192, 258), "h", 22), "v_caisse": ((228, 28, 395, 258), "h", 19), "v_etal": ((428, 28, 758, 382), "w", 40),
    "v_panneau": ((786, 28, 968, 252), "h", 20), "v_cloture": ((1003, 50, 1292, 222), "w", 32), "v_poteau": ((1333, 52, 1382, 222), "h", 15),
    "v_banc": ((62, 342, 332, 532), "w", 20), "v_puits": ((428, 412, 698, 742), "w", 32), "v_banniere": ((715, 420, 893, 695), "h", 28),
    "v_tonneau2": ((32, 560, 172, 742), "h", 18), "v_caisse2": ((204, 562, 362, 738), "h", 17),
    "v_seau": ((902, 572, 1022, 738), "h", 13), "v_foin": ((1048, 558, 1222, 738), "w", 16), "v_pot_fleurs": ((1252, 552, 1378, 738), "h", 14),
}
for nom, (boite, axe, taille) in objets.items():
    im = detourer(a, boite)
    (a_hauteur if axe == "h" else a_largeur)(im, taille).save(S + nom + ".png")
    print(nom, Image.open(S + nom + ".png").size)

# --- Glace -----------------------------------------------------------------------------------
a = charger("glace.jpg")
dalles = [(35, 30, 355, 360), (375, 30, 695, 360), (715, 30, 1035, 360), (1057, 30, 1380, 360), (368, 408, 698, 740), (710, 408, 1042, 740)]
for k, boite in enumerate(dalles):
    im = detourer(a, boite)
    reduire(im, 16, 16).save(S + "glace_%d.png" % (k + 1))
print("glace_1..6")

# --- Frise de runes ----------------------------------------------------------------------------
a = charger("frise.jpg")
bandeaux = [(30, 30, 1380, 188), (30, 215, 1380, 372), (30, 398, 1380, 552), (30, 585, 1380, 740)]
for k, boite in enumerate(bandeaux):
    im = detourer(a, boite)
    bande = reduire(im, 16 * 7, 12)
    for c in range(7):
        bande.crop((c * 16, 0, c * 16 + 16, 12)).save(S + "frise_%d_%d.png" % (k + 1, c))
print("frise_1..4_0..6")
