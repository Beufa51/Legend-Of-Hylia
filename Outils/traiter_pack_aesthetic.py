"""Outil de développement : remplace le décor EXTÉRIEUR par le pack « Aesthetic pack base set (Free) » (cases de 24 px, réduites aux cases de 16 px du jeu).
Sources : Assets/Aesthetic pack base set (Free)/*.png  ->  Assets/Gemini/tuiles/v_*.png (mêmes noms que l'ancien décor : exterieur.gd n'a pas besoin de changer).
Usage : python3 Outils/traiter_pack_aesthetic.py [contact.png]
Ordre des outils : traiter_village.py -> traiter_village2.py -> fabriquer_maisons.py -> traiter_pack_aesthetic.py -> generer_village.py
Réglage : ECHELLE (2/3 = case 24 px -> 16 px). Les coordonnées sont des pixels de la planche d'origine (x0, y0, x1, y1)."""
import os, sys, colorsys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import traiter_village2 as t2   # on réutilise sa fabrication du sol (herbe + chemin) en changeant seulement les couleurs

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets")
PACK = os.path.join(RACINE, "Aesthetic pack base set (Free)")
SORTIE = os.path.join(RACINE, "Gemini", "tuiles")
ECHELLE = 2.0 / 3.0

_cache = {}
def planche(nom):
    if nom not in _cache:
        _cache[nom] = Image.open(os.path.join(PACK, nom + ".png")).convert("RGBA")
    return _cache[nom]

def reduire(im, echelle=ECHELLE):
    """Réduit en gardant des bords nets (alpha tout ou rien)."""
    w, h = max(1, round(im.width * echelle)), max(1, round(im.height * echelle))
    r = im.resize((w, h), Image.LANCZOS)
    a = np.array(r)
    a[:, :, 3] = np.where(a[:, :, 3] >= 128, 255, 0)
    return Image.fromarray(a, "RGBA")

def decouper(nom, boite, echelle=ECHELLE, efface=None):
    im = planche(nom).crop(boite)
    if efface:   # rectangles (relatifs à la boîte) à rendre transparents : décor voisin qui déborde
        px = im.load()
        for (x0, y0, x1, y1) in efface:
            for y in range(y0, y1):
                for x in range(x0, x1):
                    px[x, y] = (0, 0, 0, 0)
    bb = im.getchannel("A").getbbox()
    if bb: im = im.crop(bb)
    return reduire(im, echelle)

def enregistrer(im, nom):
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im

def teinter(im, decalage, saturation=1.0, y_max=46):
    """Décale la teinte (0..1) du TOIT seulement (lignes < y_max) : un toit bleu/vert à partir du toit rouge, murs inchangés."""
    a = np.array(im).astype(float)
    out = a.copy()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0 or y >= y_max: continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.18:   # on ne touche pas aux gris (pierre) ni au bois très pâle
                h = (h + decalage) % 1.0; s = min(1.0, s * saturation)
            out[y, x, :3] = np.array(colorsys.hsv_to_rgb(h, s, v)) * 255
    return Image.fromarray(out.astype(np.uint8), "RGBA")

def couleur(nom, case):
    """Couleur médiane d'une case 24x24 (col, ligne) de la planche d'herbe."""
    c = planche(nom).crop((case[0] * 24, case[1] * 24, case[0] * 24 + 24, case[1] * 24 + 24))
    a = np.array(c).reshape(-1, 4)[:, :3]
    return tuple(int(v) for v in np.median(a, axis=0))

def assombrir(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)

# ---------------------------------------------------------------- SOL
def sol():
    herbe = couleur("Grassland Tileset", (0, 0))
    terre = couleur("Grassland Tileset", (3, 0))
    t2.HERBE, t2.HERBE_FONCEE, t2.HERBE_CLAIRE = herbe, assombrir(herbe, 0.88), assombrir(herbe, 1.1)
    t2.CHEMIN, t2.CHEMIN_FONCE, t2.CHEMIN_CLAIR = terre, assombrir(terre, 0.88), assombrir(terre, 1.12)
    t2.SORTIE = SORTIE
    t2.fabriquer_sol()
    # petites touffes d'herbe posées sur l'herbe (3 brins), couleurs de l'herbe du pack
    fonce, clair = assombrir(herbe, 0.72), assombrir(herbe, 1.2)
    for n, brins in (("v_herbe_1", [(2, 6), (3, 4), (4, 6), (5, 3), (6, 6)]), ("v_herbe_2", [(1, 5), (3, 3), (4, 5), (6, 4)])):
        im = Image.new("RGBA", (9, 8), (0, 0, 0, 0)); px = im.load()
        for x, h in brins:
            for k in range(h):
                px[x, 7 - k] = (fonce if k < h - 1 else clair) + (255,)
        enregistrer(im, n)
    return herbe, terre

# ---------------------------------------------------------------- OBJETS
G = "Grassland Tileset"
OBJETS = {
    # nom : (planche, boîte source, échelle, rectangles à effacer)
    "v_arbre_a": (G, (218, 417, 310, 528), ECHELLE, [(0, 0, 22, 18), (0, 86, 22, 111)]),
    "v_arbre_b": (G, (318, 421, 401, 528), ECHELLE, None),
    "v_sapin": (G, (0, 288, 72, 410), ECHELLE, [(0, 95, 24, 122), (50, 90, 72, 122)]),
    "v_buisson": (G, (313, 344, 359, 385), ECHELLE, None),
    "v_buisson_baies": (G, (410, 455, 454, 482), ECHELLE, None),
    "v_roche": (G, (195, 172, 239, 214), ECHELLE, None),
    "v_souche": (G, (410, 498, 454, 528), 0.5, None),
    "v_puits": (G, (240, 346, 312, 407), ECHELLE, None),
    "v_panneau": (G, (121, 505, 144, 528), ECHELLE, None),
    "v_cloture": (G, (183, 361, 231, 379), ECHELLE, None),
    "v_poteau": (G, (176, 360, 188, 380), ECHELLE, None),
    "v_tournesol": (G, (388, 387, 403, 401), 0.75, None),
    "v_fleur_rouge": (G, (346, 384, 361, 397), 0.75, None),
    "v_marguerite": (G, (335, 394, 350, 408), 0.75, None),
}

def objets():
    sorties = {}
    for nom, (pl, boite, ech, efface) in OBJETS.items():
        sorties[nom] = enregistrer(decouper(pl, boite, ech, efface), nom)
    return sorties

# ---------------------------------------------------------------- MAISONS (emprise 5x4 = 80 px de large, porte en colonne 2 ; caserne 7x4 = 112 px, porte colonne 3)
P1 = "Pack 1 expansion"

def maisons():
    out = {}
    bois = decouper(P1, (215, 0, 335, 122), 80.0 / 120.0)
    # variantes de couleur de toit : orange (M), bleu (N), vert (T), rouge d'origine (R, L)
    out["v_maison_rouge"] = bois
    out["v_maison_bois"] = bois
    out["v_maison_orange"] = teinter(bois, 0.08, 1.0)
    out["v_maison_bleue"] = teinter(bois, -0.42, 1.0)
    out["v_maison_chaume"] = teinter(bois, -0.28, 1.0)
    # maison de pierre (forge) : 'S'
    pierre = decouper(P1, (0, 18, 84, 122), ECHELLE)
    toile = Image.new("RGBA", (80, pierre.height), (0, 0, 0, 0))
    toile.alpha_composite(pierre, ((80 - pierre.width) // 2, 0))
    out["v_maison_pierre"] = toile
    # caserne : la grande maison couverte de végétation, calée pour que sa porte tombe en colonne 3 (48 à 64 px)
    grande = decouper(P1, (82, 0, 216, 160), 0.55)   # plus petite : elle doit tenir sous le bord haut de l'écran
    toile = Image.new("RGBA", (112, grande.height), (0, 0, 0, 0))
    toile.alpha_composite(grande, (20, 0))
    out["v_maison_caserne"] = toile
    for n, im in out.items():
        enregistrer(im, n)
    return out

if __name__ == "__main__":
    herbe, terre = sol()
    o = objets()
    m = maisons()
    print("herbe", herbe, "terre", terre)
    for n, im in {**o, **m}.items():
        print(n, im.size)
    if len(sys.argv) > 1:
        c = Image.new("RGBA", (460, 330), herbe + (255,))
        x = y = 4; hm = 0
        for n, im in list({**m, **o}.items()):
            if x + im.width > 450: x = 4; y += hm + 4; hm = 0
            c.alpha_composite(im, (x, y)); x += im.width + 4; hm = max(hm, im.height)
        x = 4; y += hm + 6
        for n in ["v_herbe_sol", "v_herbe_sol_1", "v_chemin_f0", "v_chemin_3", "v_chemin_12", "v_chemin_5", "v_chemin_9", "v_chemin_6", "v_chemin_10", "v_chemin_f1", "v_herbe_1", "v_herbe_2"]:
            im = Image.open(os.path.join(SORTIE, n + ".png")).convert("RGBA"); c.alpha_composite(im, (x, y)); x += im.width + 4
        c.crop((0, 0, 460, y + 24)).resize((460 * 3, (y + 24) * 3), Image.NEAREST).save(sys.argv[1])
