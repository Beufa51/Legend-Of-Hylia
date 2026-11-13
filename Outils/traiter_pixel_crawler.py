"""Outil de développement : habille le VILLAGE avec le pack Pixel Crawler (Anokolisa) en remplaçant les images `v_*.png` de la nature,
sans toucher à exterieur.gd (mêmes noms de fichiers que traiter_pack_aesthetic.py). À lancer APRÈS traiter_pack_aesthetic.py et AVANT generer_village.py.
Remplace : sol (herbe + chemin de terre aux couleurs du pack), arbres (2 feuillus), sapin, buissons, fleurs, touffes d'herbe, roche.
Ne touche pas : maisons, clôtures, puits, panneau, tonneau, caisse, bannière, étal (restes d'autres packs).
Usage : python3 Outils/traiter_pixel_crawler.py [apercu.png]"""
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import traiter_village2 as t2

RACINE = os.path.join(os.path.dirname(__file__), "..")
PACK = os.path.join(RACINE, "Assets", "Pixel Crawler - Free Pack", "Environment")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
t2.SORTIE = SORTIE


def planche(chemin):
    return Image.open(os.path.join(PACK, chemin)).convert("RGBA")


def rogner(im):
    return im.crop(im.getchannel("A").getbbox())


def ecrire(im, nom):
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im


def mediane(im, boite):
    a = np.array(im.crop(boite)).reshape(-1, 4)
    a = a[a[:, 3] > 0]
    return tuple(int(v) for v in np.median(a[:, :3], axis=0))


def sombre(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


# --- SOL : couleurs du pack (herbe franche, terre brune)
sols = planche("Tilesets/Floors_Tiles.png")
herbe = mediane(sols, (16, 0, 32, 16))
terre = mediane(sols, (176, 0, 192, 16))
t2.HERBE, t2.HERBE_FONCEE, t2.HERBE_CLAIRE = herbe, sombre(herbe, 0.86), sombre(herbe, 1.18)
t2.CHEMIN, t2.CHEMIN_FONCE, t2.CHEMIN_CLAIR = terre, sombre(terre, 0.86), sombre(terre, 1.15)
t2.fabriquer_sol()

# --- ARBRES (Trees/Model_01/Size_02 : 4 colonnes de 64 px = vert, jaune-vert, nu, givré ; 2 rangées = été, automne)
arbres = planche("Props/Static/Trees/Model_01/Size_02.png")
ecrire(rogner(arbres.crop((32, 0, 64, 64))), "v_arbre_a")         # feuillu vert
ecrire(rogner(arbres.crop((96, 0, 128, 64))), "v_arbre_b")        # feuillu jaune-vert
pins = planche("Props/Static/Trees/Model_02/Size_02.png")
ecrire(rogner(pins.crop((0, 0, 30, 48))), "v_sapin")                  # sapin sombre (le petit à côté est exclu)

# --- BUISSONS, FLEURS, HERBES (Vegetation.png)
veg = planche("Props/Static/Vegetation.png")
ecrire(rogner(veg.crop((194, 51, 222, 77))), "v_buisson")        # buisson vert
ecrire(rogner(veg.crop((342, 6, 377, 39))).resize((28, 26), Image.NEAREST), "v_buisson_baies")   # buisson d'automne (rouge)
ecrire(rogner(veg.crop((100, 405, 108, 412))), "v_marguerite")    # bleue (marguerite)
ecrire(rogner(veg.crop((100, 421, 108, 428))), "v_tournesol")     # jaune
ecrire(rogner(veg.crop((100, 373, 108, 380))), "v_fleur_rouge")   # orange
ecrire(rogner(veg.crop((5, 165, 12, 174))), "v_herbe_1")
ecrire(rogner(veg.crop((21, 164, 28, 174))), "v_herbe_2")

# --- ROCHE (Rocks.png : le gros rocher gris)
roc = planche("Props/Static/Rocks.png")
ecrire(rogner(roc.crop((130, 18, 158, 47))), "v_roche")

print("village habillé avec Pixel Crawler : herbe", herbe, "terre", terre)

if len(sys.argv) > 1:   # petit aperçu : sol, arbres, buissons, fleurs, héros pour l'échelle
    prev = Image.new("RGBA", (200, 90))
    for y in range(0, 90, 16):
        for x in range(0, 200, 16):
            prev.alpha_composite(Image.open(os.path.join(SORTIE, "v_herbe_sol.png")), (x, y))
    for y in range(40, 56, 16):
        for x in range(0, 200, 16):
            prev.alpha_composite(Image.open(os.path.join(SORTIE, "v_chemin_%d.png" % (12 if x else 8))), (x, y))
    x = 6
    for n in ("v_arbre_a", "v_arbre_b", "v_sapin", "v_buisson", "v_buisson_baies", "v_roche", "v_marguerite", "v_tournesol", "v_fleur_rouge", "v_herbe_1"):
        im = Image.open(os.path.join(SORTIE, n + ".png")).convert("RGBA")
        prev.alpha_composite(im, (x, 86 - im.height)); x += im.width + 4
    h = Image.open(os.path.join(RACINE, "Assets/Heros/heros_marche.png")).convert("RGBA").crop((0, 0, 32, 32))
    prev.alpha_composite(h, (165, 58))
    prev.resize((800, 360), Image.NEAREST).save(sys.argv[1])
