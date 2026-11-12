"""Outil de développement : 2e génération des sprites du village (style vu de dessus, couleurs JOYEUSES façon Link's Awakening DX).
Sources : Assets/Gemini/originaux/village2_{maisons,nature,sol}.jpg  ->  Assets/Gemini/tuiles/v_*.png (remplace les anciens).
Les planches Gemini sont sombres : `joyeux()` éclaircit et sature (réglable : SAT, LUM). Les tuiles de sol (herbe, chemin) sont fabriquées ici en code.
Usage : python3 Outils/traiter_village2.py [contact.png]   (lancer APRÈS traiter_village.py)"""
import os, sys, colorsys
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import traiter_village as t1

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini")
SORTIE = os.path.join(RACINE, "tuiles")
SAT, LUM = 1.5, 1.6      # saturation et luminosité (1 = comme Gemini)
GAMME_VERT = 0.045         # décale les verts vers le jaune-vert, plus joyeux

def charger(n): return Image.open(os.path.join(RACINE, "originaux", "village2_%s.jpg" % n)).convert("RGB")

def joyeux(im):
    """Éclaircit et sature une image RGBA (les pixels transparents ne bougent pas)."""
    a = np.array(im.convert("RGBA")).astype(float) / 255
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    v = mx; s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    # teinte
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6
    vert = (h > 0.18) & (h < 0.5)
    h = np.where(vert, h - GAMME_VERT, h) % 1.0
    s = np.clip(s * SAT, 0, 1)
    # la lumière : les tons sombres sont relevés plus que les clairs (contours gardés assez foncés)
    v = np.clip(v * LUM + 0.06 * (1 - v), 0, 1)
    i = np.floor(h * 6).astype(int) % 6; f = h * 6 - np.floor(h * 6)
    p, q, tt = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    out = np.zeros_like(a)
    for k, (R, G, B) in enumerate([(v, tt, p), (q, v, p), (p, v, tt), (p, q, v), (tt, p, v), (v, p, q)]):
        m = i == k
        out[..., 0][m], out[..., 1][m], out[..., 2][m] = R[m], G[m], B[m]
    out[..., 3] = a[..., 3]
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")

def sprite(img, boite, w, h, ardoise=False):
    """Découpe `boite`, retire le magenta, réduit en gardant les proportions, palette limitée, couleurs joyeuses."""
    t1.ARDOISE = ardoise
    crop = img.crop(boite)
    rgba = t1.retirer_fond(crop)
    ys, xs = np.where(rgba[..., 3] > 0)
    rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy()
    r_, g_, b_ = (rgba[..., k].astype(int) for k in range(3))
    rgba[(r_ - g_ > 22) & (b_ - g_ > 22) & (r_ < 190), 3] = 0   # frange violette des séparateurs de la planche
    return joyeux(t1.nette(t1.reduire(rgba, w, h), 30)), rgba.shape

def enregistrer(im, nom):
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im

# --- MAISONS : (cellule, porte x source, nom, largeur max, hauteur max, nb de cases de large)
MAISONS = [
    ((8, 8, 346, 380), 178, "v_maison_orange", 64, 62, 4),
    ((360, 8, 698, 380), 527, "v_maison_bleue", 64, 62, 4),
    ((712, 8, 1048, 380), 878, "v_maison_chaume", 64, 62, 4),
    ((1062, 8, 1400, 380), 1230, "v_maison_rouge", 64, 62, 4),
    ((8, 392, 346, 765), 183, "v_maison_pierre", 64, 62, 4),
    ((388, 392, 1020, 765), 590, "v_maison_caserne", 96, 62, 6),
    ((1045, 392, 1400, 765), 1215, "v_maison_bois", 64, 62, 4),
]

def maison(img, cellule, porte_x, nom, w, h, cases):
    spr, forme = sprite(img, cellule, w, h)
    s = spr.width / forme[1]
    # position de la porte dans le sprite : on repère le bord gauche réel de la boîte
    crop = img.crop(cellule)
    rgba = t1.retirer_fond(crop)
    ys, xs = np.where(rgba[..., 3] > 0)
    x0 = xs.min()
    dx = (porte_x - cellule[0] - x0) * s
    col = int(min(cases - 1, max(0, round(dx / 16 - 0.5))))
    decal = int(round((col + 0.5) * 16 - dx))
    toile = Image.new("RGBA", (cases * 16, 64), (0, 0, 0, 0))
    x = max(0, min(cases * 16 - spr.width, (cases * 16 - spr.width) // 2 + decal))
    toile.alpha_composite(spr, (x, 64 - spr.height))
    col = int(min(cases - 1, max(0, round((dx + x) / 16 - 0.5))))
    return enregistrer(toile, nom), col

# --- NATURE : (boîte, nom, w, h)
NATURE = [
    ((8, 198, 178, 380), "v_arbre_a", 40, 40),
    ((188, 198, 358, 380), "v_arbre_b", 40, 40),
    ((368, 208, 523, 305), "v_sapin", 28, 36),
    ((372, 312, 440, 380), "v_buisson", 16, 16),
    ((448, 312, 523, 380), "v_buisson_baies", 16, 16),
    ((530, 8, 610, 95), "v_roche", 26, 22),
    ((618, 8, 700, 95), "v_souche", 16, 16),
    ((535, 105, 605, 185), "v_herbe_1", 14, 14),
    ((620, 205, 700, 285), "v_herbe_2", 14, 14),
    ((535, 300, 605, 380), "v_tournesol", 16, 16),
    ((620, 300, 700, 380), "v_marguerite", 16, 16),
    ((535, 205, 605, 290), "v_fleur_rouge", 16, 16),
]

# --- SOL : couleurs joyeuses (fabriqué en code)
HERBE = (112, 190, 64)
HERBE_FONCEE = (88, 164, 56)
HERBE_CLAIRE = (140, 212, 84)
CHEMIN = (236, 206, 150)
CHEMIN_FONCE = (212, 178, 120)
CHEMIN_CLAIR = (248, 228, 176)

def bruit(x, y, graine):
    v = (x * 374761393 + y * 668265263 + graine * 2147483647) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return (v & 0xFFFF) / 65535.0

def tuile_herbe(variante):
    im = Image.new("RGBA", (16, 16), HERBE + (255,))
    px = im.load()
    for y in range(16):
        for x in range(16):
            n = bruit(x, y, 11 + variante)
            if n < 0.045: px[x, y] = HERBE_FONCEE + (255,)
            elif n > 0.985: px[x, y] = HERBE_CLAIRE + (255,)
    if variante:   # une touffe : 3 brins
        bx, by = (4, 9) if variante == 1 else (10, 5)
        for dx, dy in [(0, 0), (0, -1), (-1, -1), (1, -1), (1, -2), (0, -2)]:
            px[bx + dx, by + dy] = HERBE_FONCEE + (255,)
        px[bx, by] = HERBE_CLAIRE + (255,)
    return im

def tuile_chemin(n, s, o, e, diag):
    """Tuile de chemin (n, s, o, e = voisin de chemin ?) ; `diag` = 4 bits des coins en herbe (ne, no, se, so) pour la tuile pleine."""
    im = Image.new("RGBA", (16, 16), HERBE + (255,))
    px = im.load()
    for y in range(16):
        for x in range(16):
            # distance (en pixels) au bord ouvert le plus proche ; bords irréguliers
            marge = 3.0
            d = 99.0
            if not n: d = min(d, y - marge + (bruit(x, y, 3) - 0.5) * 2.2)
            if not s: d = min(d, 15 - y - marge + (bruit(x, y, 4) - 0.5) * 2.2)
            if not o: d = min(d, x - marge + (bruit(x, y, 5) - 0.5) * 2.2)
            if not e: d = min(d, 15 - x - marge + (bruit(x, y, 6) - 0.5) * 2.2)
            # coins arrondis du bord extérieur
            for cond, cx, cy in [(not n and not o, 0, 0), (not n and not e, 15, 0), (not s and not o, 0, 15), (not s and not e, 15, 15)]:
                if cond:
                    r = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                    d = min(d, r - 5.0 + (bruit(x, y, 7) - 0.5) * 1.6)
            # coins intérieurs (case pleine avec une diagonale en herbe)
            if n and s and o and e:
                for bit, cx, cy in [(1, 15, 0), (2, 0, 0), (4, 15, 15), (8, 0, 15)]:
                    if diag & bit:
                        r = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                        d = min(d, r - 4.0 + (bruit(x, y, 8) - 0.5) * 1.6)
            if d >= 0:
                c = CHEMIN
                r = bruit(x, y, 9)
                if r < 0.07: c = CHEMIN_FONCE
                elif r > 0.95: c = CHEMIN_CLAIR
                if d < 1.2: c = CHEMIN_CLAIR if d > 0.4 else c   # liseré clair au bord
                px[x, y] = c + (255,)
            elif d > -1.4:
                px[x, y] = HERBE_FONCEE + (255,)   # petite ombre d'herbe au bord
    return im

def fabriquer_sol():
    for v in range(3):
        enregistrer(tuile_herbe(v), "v_herbe_sol" if v == 0 else "v_herbe_sol_%d" % v)
    for bits in range(16):
        n, s, o, e = bits & 1, bits & 2, bits & 4, bits & 8
        if n and s and o and e:
            for diag in range(16):
                enregistrer(tuile_chemin(True, True, True, True, diag), "v_chemin_f%d" % diag)
        else:
            enregistrer(tuile_chemin(bool(n), bool(s), bool(o), bool(e), 0), "v_chemin_%d" % bits)

# --- CLÔTURES
def cloture(img):
    spr, _ = sprite(img, (10, 436, 172, 520), 32, 16, ardoise=False)
    enregistrer(spr, "v_cloture")
    poteau, _ = sprite(img, (14, 436, 50, 520), 16, 16)
    enregistrer(poteau, "v_poteau")

if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    cm, cn, cs = charger("maisons"), charger("nature"), charger("sol")
    produits, portes = [], {}
    for (cell, px_, nom, w, h, cases) in MAISONS:
        im, col = maison(cm, cell, px_, nom, w, h, cases)
        produits.append((nom, im)); portes[nom] = (col, cases)
    for (boite, nom, w, h) in NATURE:
        im, _ = sprite(cn, boite, w, h)
        produits.append((nom, enregistrer(im, nom)))
    fabriquer_sol()
    cloture(cs)
    print("portes (colonne, largeur en cases) :", portes)
    if len(sys.argv) > 1:
        c = Image.new("RGBA", (420, 300), (112, 190, 64, 255))
        x = y = 4; hm = 0
        for nom, im in produits:
            if x + im.width > 410: x = 4; y += hm + 4; hm = 0
            c.alpha_composite(im, (x, y)); x += im.width + 4; hm = max(hm, im.height)
        # le sol
        x = 4; y += hm + 8
        for nom in ["v_herbe_sol", "v_herbe_sol_1", "v_chemin_f0", "v_chemin_3", "v_chemin_12", "v_chemin_5", "v_chemin_9", "v_chemin_6", "v_chemin_10", "v_chemin_f1", "v_cloture", "v_poteau"]:
            im = Image.open(os.path.join(SORTIE, nom + ".png")).convert("RGBA"); c.alpha_composite(im, (x, y)); x += im.width + 4
        c.crop((0, 0, 420, y + 24)).resize((420 * 3, (y + 24) * 3), Image.NEAREST).save(sys.argv[1])
