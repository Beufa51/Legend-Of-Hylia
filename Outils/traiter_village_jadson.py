"""Outil de développement : habille le VILLAGE avec le pack « TILESET VILLAGE TOP DOWN » (Jadson Holanda) : herbe lumineuse, terre, arbres ronds, maisons à toit de couleur,
clôtures, puits, et le RELIEF (terrasses à falaise, escaliers). Remplace les images `v_*.png` de la nature et des maisons, gardant les noms (exterieur.gd les lit).
À lancer APRÈS traiter_pack_aesthetic.py / traiter_pixel_crawler.py / fabriquer_maisons_pixelcrawler.py, AVANT fabriquer_riviere.py puis generer_village.py.
Écrit aussi : v_ter_<rangée><colonne> (12 morceaux de terrasse : 0..3 x 0..2) et v_escalier (32x64).
Usage : python3 Outils/traiter_village_jadson.py [apercu.png]"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import traiter_village2 as t2

RACINE = os.path.join(os.path.dirname(__file__), "..")
PACK = os.path.join(RACINE, "Assets", "TILESET VILLAGE TOP DOWN")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
t2.SORTIE = SORTIE


def charger(nom):
    return Image.open(os.path.join(PACK, nom + " - DAY.png")).convert("RGBA")


def rogner(im):
    return im.crop(im.getchannel("A").getbbox())


def ecrire(im, nom):
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im


def sombre(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


HERBE = (169, 204, 82)
TERRE = (158, 99, 59)

# --- SOL : herbe franche, détails du pack (fleurs, touffes, cailloux) comme variantes de la case d'herbe ; chemin de terre en autotile
t2.HERBE, t2.HERBE_FONCEE, t2.HERBE_CLAIRE = HERBE, sombre(HERBE, 0.72), sombre(HERBE, 1.08)
t2.CHEMIN, t2.CHEMIN_FONCE, t2.CHEMIN_CLAIR = TERRE, sombre(TERRE, 0.84), sombre(TERRE, 1.12)
t2.fabriquer_sol()
ecrire(charger("GRASS TILE"), "v_herbe_sol")
for i in range(1, 7):
    ecrire(charger("GRASS DETAIL %d" % i), "v_herbe_sol_%d" % i)    # 6 variantes avec détails (l'ancien v_herbe_sol_1/_2 sont remplacés)


def detail_transparent(nom):
    """Un détail du pack (posé sur de l'herbe) -> image transparente : on retire les pixels qui sont ceux de l'herbe unie."""
    a = np.array(charger(nom)).copy()
    herbe = np.array(HERBE + (255,))
    fond = (a == herbe).all(axis=2)
    a[fond] = 0
    return rogner(Image.fromarray(a, "RGBA"))


def teinter(im, h0, h1, nouvelle, sat=1.0, lum=1.0):
    a = np.array(im).astype(float)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x, 3] == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(*(a[y, x, :3] / 255.0))
            if s > 0.18 and h0 <= h <= h1:
                r, g, b = colorsys.hsv_to_rgb(nouvelle, min(1.0, s * sat), min(1.0, v * lum))
                a[y, x, :3] = (r * 255, g * 255, b * 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


# --- FLEURS, TOUFFES, ROCHES, SOUCHE
fleur_jaune = detail_transparent("GRASS DETAIL 2")
ecrire(fleur_jaune, "v_tournesol")
ecrire(detail_transparent("GRASS DETAIL 5"), "v_marguerite")                 # fleurs bleues
ecrire(teinter(fleur_jaune, 0.05, 0.2, 0.98, 1.1, 0.95), "v_fleur_rouge")    # la même, en rouge
ecrire(detail_transparent("GRASS DETAIL 3"), "v_herbe_1")
ecrire(detail_transparent("GRASS DETAIL 6"), "v_herbe_2")
ecrire(detail_transparent("GRASS DETAIL 4"), "v_roche")
ecrire(detail_transparent("FENCE 2"), "v_souche")
ecrire(detail_transparent("FENCE 2"), "v_poteau")
clo = Image.new("RGBA", (32, 16))
for i in range(2):
    clo.alpha_composite(charger("FENCE 1"), (i * 16, 0))
ecrire(clo, "v_cloture")
ecrire(rogner(charger("PIT")), "v_puits")

# --- ARBRES (48x48 : 3x3 cases) et buissons (les mêmes, réduits)
arbre_vert, arbre_roux, arbre_fleuri = rogner(charger("TREE 1")), rogner(charger("TREE 2")), rogner(charger("TREE 3"))
ecrire(arbre_vert, "v_arbre_a")
ecrire(arbre_roux, "v_arbre_b")
ecrire(arbre_fleuri, "v_sapin")
petit = lambda im: im.resize((round(im.width * 0.5), round(im.height * 0.5)), Image.LANCZOS)
ecrire(petit(arbre_vert), "v_buisson")
ecrire(petit(arbre_roux), "v_buisson_baies")

# --- MAISONS : HOUSE 1 (80x112), HOUSE 2 (128x112, avec annexe), CHURCH (128x112) ; toits recolorés. Les sprites sont posés bas-centre sur l'emprise.
maison1, maison2, eglise = rogner(charger("HOUSE 1")), rogner(charger("HOUSE 2")), rogner(charger("CHURCH"))
ecrire(maison1, "v_maison_bleue")
ecrire(teinter(maison1, 0.5, 0.72, 0.0, 1.0, 1.0), "v_maison_rouge")        # toit bleu -> rouge
ecrire(teinter(maison1, 0.5, 0.72, 0.30, 0.55, 0.85), "v_maison_chaume")     # -> vert
ecrire(maison2, "v_maison_orange")
ecrire(teinter(maison2, 0.04, 0.14, 0.62, 0.9, 0.9), "v_maison_pierre")     # toit orange -> bleu ardoise
ecrire(teinter(maison2, 0.04, 0.14, 0.07, 0.8, 0.62), "v_maison_bois")      # -> brun (grange)
ecrire(teinter(maison2, 0.04, 0.14, 0.99, 1.2, 0.85), "v_maison_caserne")   # -> rouge sombre (caserne)
ecrire(eglise, "v_temple_entree")                                           # le temple : l'église du pack, grande porte à croisillons

# --- RELIEF : terrasse (TERRAIN SET 3 : 3 colonnes x 4 rangées de 16 px). L'extérieur (terre) est rendu transparent pour que la terrasse se pose sur l'herbe.
t3 = np.array(charger("TERRAIN SET 3")).copy()
terre = np.array(TERRE + (255,))
dehors = np.zeros(t3.shape[:2], bool)
pile = [(y, x) for y in range(t3.shape[0]) for x in range(t3.shape[1]) if y in (0, t3.shape[0] - 1) or x in (0, t3.shape[1] - 1)]
while pile:
    y, x = pile.pop()
    if 0 <= y < t3.shape[0] and 0 <= x < t3.shape[1] and not dehors[y, x] and (t3[y, x] == terre).all():
        dehors[y, x] = True
        pile += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
t3[dehors] = 0
terrasse = Image.fromarray(t3, "RGBA")
for r in range(4):
    for c in range(3):
        ecrire(terrasse.crop((c * 16, r * 16, c * 16 + 16, r * 16 + 16)), "v_ter_%d%d" % (r, c))
ecrire(charger("GRASS TILE"), "v_ter_11")      # le centre du pack porte des fleurs : on le remplace par de l'herbe unie (les détails viennent du sol)
ecrire(charger("STAIRS"), "v_escalier")
print("village habillé avec TILESET VILLAGE TOP DOWN")

if len(sys.argv) > 1:   # aperçu : une terrasse 8x6 + escalier + maisons + arbres
    img = Image.new("RGBA", (420, 230), HERBE + (255,))
    def tile(n): return Image.open(os.path.join(SORTIE, n + ".png")).convert("RGBA")
    w, h = 8, 6
    for j in range(h):
        for i in range(w):
            r = 0 if j == 0 else 2 if j == h - 2 else 3 if j == h - 1 else 1
            c = 0 if i == 0 else 2 if i == w - 1 else 1
            img.alpha_composite(tile("v_ter_%d%d" % (r, c)), (10 + i * 16, 10 + j * 16))
    img.alpha_composite(tile("v_escalier"), (10 + 3 * 16, 10 + (h - 3) * 16))
    x = 150
    for n in ("v_maison_bleue", "v_maison_orange", "v_arbre_a", "v_arbre_b", "v_puits"):
        im = tile(n); img.alpha_composite(im, (x, 220 - im.height)); x += im.width + 4
    img.resize((img.width * 3, img.height * 3), Image.NEAREST).save(sys.argv[1])
