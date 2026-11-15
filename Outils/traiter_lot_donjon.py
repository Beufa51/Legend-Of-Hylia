"""Lot de planches Gemini du donjon (2026-11-15) -> Assets/Gemini/tuiles/ (mêmes noms qu'avant, sauf indication).
À lancer APRÈS traiter_pack_donjon.py, fabriquer_levier.py, fabriquer_objets.py, fabriquer_runes_sol.py et fabriquer_porte_basse.py
(qui écrivent les anciennes versions).

- originaux/levier_pilier.jpg : levier levé / baissé, pilier      -> levier_1..5 (16x24), pilier (16xH, H variable)
- originaux/sentinelle.jpg    : garde de pierre face / dos / profil -> sentinelle_bas|haut|droite.png (gauche = miroir)
- originaux/portes_arches.jpg  : arche herse fermée / à moitié / ouverte, porte de bois, grille basse
                                -> arche_herse_1..5, arche_bois_1..5 (48x32), arche_basse_1..5 (48x16 : la grille s'enfonce dans le sol)
- originaux/coffre.jpg        : coffre fermé / entrouvert / ouvert, clé, cadenas -> coffre_1..5 (20x22), cle (12x8), cadenas (10x12)
- originaux/miroirs.jpg       : miroir sur pied, soleil dans le mur, réceptacle éteint / allumé
                                -> miroir_m / miroir_n (16x16, ovale penché « / » et « \\ »), source_soleil, cible, cible_allumee (16x16)
"""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

O = "Assets/Gemini/originaux/"
S = "Assets/Gemini/tuiles/"


def charger(nom):
    return np.array(Image.open(O + nom).convert("RGB")).astype(int)


def detourer(a, boite, garder_tout=False):
    """Découpe une boîte, retire le magenta (plus grande composante, trous bouchés). Renvoie une image RGBA."""
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    if garder_tout:
        m = ~fond
    else:
        lab, n = ndimage.label(~fond)               # la pièce + ses morceaux détachés (pas les trous magenta : ils restent transparents)
        tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.02])
        m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)   # liseré rosé autour des trous
    c[~m] = (16, 16, 22)                        # le magenta ne déteint pas sur les bords
    al = (m * 255).astype(np.uint8)
    return Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al)))


def reduire(im, w, h):
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.7)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = im.split()[3].resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*rgb.split(), al))


def poser(toile, im, x, y):
    toile.alpha_composite(im, (int(x), int(y)))
    return toile


# --- Levier et pilier -----------------------------------------------------------------------
a = charger("levier_pilier.jpg")
haut, bas = detourer(a, (58, 29, 364, 382)), detourer(a, (481, 88, 816, 440))
e = 16 / 300                                       # la plaque (~300 px) fait 16 px
images = []
for im, dy in ((haut, 0), (bas, 4)):               # plaque toujours à la même place : y 4..20 dans 16x24
    p = reduire(im, round(im.width * e), round(im.height * e))
    t = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    images.append(poser(t, p, (16 - p.width) // 2, 24 - p.height if dy else 0))
for k, i in enumerate([0, 0, 1, 1, 1]):
    images[i].save(S + "levier_%d.png" % (k + 1))
pil = detourer(a, (997, 82, 1255, 640))
p = reduire(pil, 16, round(pil.height * 16 / pil.width * 0.85))   # un peu tassé : il ne dépasse pas trop
p.save(S + "pilier.png")
print("levier_1..5, pilier", p.size)

# --- Sentinelle -----------------------------------------------------------------------------
a = charger("sentinelle.jpg")
for nom, boite in (("bas", (52, 45, 353, 728)), ("haut", (410, 45, 716, 728)), ("droite", (803, 51, 1038, 728))):
    im = detourer(a, boite)
    H = 34
    reduire(im, max(1, round(im.width * H / im.height)), H).save(S + "sentinelle_%s.png" % nom)
print("sentinelle_bas|haut|droite (H 34)")

# --- Portes ---------------------------------------------------------------------------------
a = charger("portes_arches.jpg")
fermee, moitie, ouverte = (reduire(detourer(a, b, True), 48, 32) for b in ((35, 29, 458, 358), (492, 29, 915, 358), (950, 29, 1373, 358)))
bois = reduire(detourer(a, (492, 404, 915, 739), True), 48, 32)
for k, im in enumerate([fermee, moitie, moitie, ouverte, ouverte]):
    im.save(S + "arche_herse_%d.png" % (k + 1))
for k, im in enumerate([bois, bois, ouverte, ouverte, ouverte]):
    im.save(S + "arche_bois_%d.png" % (k + 1))
grille = reduire(detourer(a, (35, 585, 458, 739), True), 48, 16)
for k in range(5):                                 # la grille s'enfonce dans le sol en s'effaçant
    t = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    g = grille.crop((0, 0, 48, 16 - k * 4))
    if g.height > 0:
        al = g.split()[3].point(lambda v, k=k: int(v * (1 - k * 0.2)))
        g.putalpha(al)
        t.alpha_composite(g, (0, k * 4))
    t.save(S + "arche_basse_%d.png" % (k + 1))
print("arche_herse/bois (48x32), arche_basse (48x16)")

# --- Coffre, clé, cadenas -------------------------------------------------------------------
a = charger("coffre.jpg")
ferme, demi, ouvert = detourer(a, (47, 70, 434, 487)), detourer(a, (504, 58, 915, 493)), detourer(a, (991, 41, 1361, 528))
e = min(20 / max(i.width for i in (ferme, demi, ouvert)), 22 / max(i.height for i in (ferme, demi, ouvert)))
etats = []
for im in (ferme, demi, ouvert):
    p = reduire(im, round(im.width * e), round(im.height * e))
    etats.append(poser(Image.new("RGBA", (20, 22), (0, 0, 0, 0)), p, (20 - p.width) // 2, 22 - p.height))
for k, i in enumerate([0, 0, 1, 2, 2]):
    etats[i].save(S + "coffre_%d.png" % (k + 1))
reduire(detourer(a, (487, 586, 704, 686)), 12, 6).save(S + "cle_tmp.png")
cle = Image.new("RGBA", (12, 8), (0, 0, 0, 0)); cle.alpha_composite(Image.open(S + "cle_tmp.png"), (0, 1)); cle.save(S + "cle.png")
import os; os.remove(S + "cle_tmp.png")
reduire(detourer(a, (873, 539, 1009, 733)), 9, 12).save(S + "cadenas.png")
print("coffre_1..5, cle, cadenas")

# --- Miroirs, soleil, réceptacle ------------------------------------------------------------
a = charger("miroirs.jpg")
m = detourer(a, (94, 70, 241, 311))
ovale = m.crop((0, 0, m.width, round(m.height * 0.72)))       # l'ovale sans le pied
pied = m.crop((0, round(m.height * 0.72), m.width, m.height))
ov = reduire(ovale, 9, 14)
pd = reduire(pied, 10, 4)
for nom, angle in (("miroir_m", -45), ("miroir_n", 45)):
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ombre = Image.new("RGBA", (12, 4), (0, 0, 0, 0))
    for x in range(12):
        for y in range(4):
            if ((x - 5.5) / 6) ** 2 + ((y - 1.5) / 2) ** 2 <= 1: ombre.putpixel((x, y), (0, 0, 0, 90))
    t.alpha_composite(ombre, (2, 12))
    t.alpha_composite(pd, (3, 11))
    o = ov.rotate(angle, resample=Image.NEAREST, expand=True)
    t.alpha_composite(o, ((16 - o.width) // 2, max(0, 7 - o.height // 2)))
    t.save(S + nom + ".png")
sol = a[150:600, 330:775]                            # le mur autour du soleil : on garde la pierre
cx, cy = 552 - 330, 368 - 150; R = 175
carre = Image.fromarray(sol[cy - R:cy + R, cx - R:cx + R].astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
carre.resize((16, 16), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2)).convert("RGBA").save(S + "source_soleil.png")
for nom, boite in (("cible", (827, 64, 1044, 346)), ("cible_allumee", (1126, 64, 1338, 346))):
    im = detourer(a, boite)
    p = reduire(im, round(im.width * 16 / im.height), 16)
    poser(Image.new("RGBA", (16, 16), (0, 0, 0, 0)), p, (16 - p.width) // 2, 0).save(S + nom + ".png")
print("miroir_m/n, source_soleil, cible, cible_allumee")
