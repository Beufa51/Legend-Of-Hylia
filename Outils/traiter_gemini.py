"""Outil de développement : transforme les planches Gemini (Assets/Gemini/originaux)
en petites images prêtes pour Godot (Assets/Gemini/tuiles), fond magenta -> transparent.
Usage : python3 Outils/traiter_gemini.py [taille_tuile]   (32 par défaut)"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from decouper import cases

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini")
T = int(sys.argv[1]) if len(sys.argv) > 1 else 32
SORTIE = os.path.join(RACINE, "tuiles" if T == 32 else f"tuiles{T}")
os.makedirs(SORTIE, exist_ok=True)


def ouvrir(nom):
    return Image.open(os.path.join(RACINE, "originaux", nom + ".jpg")).convert("RGB")


def reduire(img, boite, w, h, transparent):
    """Découpe `boite`, réduit à w x h pixels (moyenne par blocs). Option : fond magenta -> transparent."""
    c = img.crop(boite)
    if not transparent:
        return c.resize((w, h), Image.BOX)
    a = np.array(c).astype(int)
    magenta = (a[..., 0] > 170) & (a[..., 2] > 170) & (a[..., 1] < 130)
    # on grossit un peu le magenta pour manger la frange de compression JPG
    m = Image.fromarray((magenta * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))
    opaque = (np.array(m) == 0).astype(float)
    rgb = a * opaque[..., None]
    # moyenne pondérée par l'opacité (pas de bord rose)
    pr = Image.fromarray(rgb.astype(np.uint8)).resize((w, h), Image.BOX)
    po = Image.fromarray((opaque * 255).astype(np.uint8)).resize((w, h), Image.BOX)
    po_a = np.array(po).astype(float) / 255
    rgb_r = np.array(pr).astype(float) / np.maximum(po_a[..., None], 1e-3)
    alpha = (po_a > 0.5) * 255
    out = np.dstack([np.clip(rgb_r, 0, 255), alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def enregistrer(img, nom):
    img.save(os.path.join(SORTIE, nom + ".png"))


# --- Grilles régulières (cases opaques, 1 tuile T x T chacune) ---
def grille(feuille, noms, inset=4):
    im = ouvrir(feuille)
    boites, _ = cases(im)
    for nom, (x0, y0, x1, y1) in zip(noms, boites):
        enregistrer(reduire(im, (x0 + inset, y0 + inset, x1 - inset, y1 - inset), T, T, False), nom)


grille("sols_a", ["sol_a_brique", "sol_a_fissure", "sol_a_mousse", "sol_a_losanges",
                  "sol_a_sombre", "sol_a_clair", "sol_a_cailloux", "sol_a_rune"])
grille("sols_b", ["sol_b_dalle", "sol_b_fissure", "sol_b_mousse", "sol_b_motif",
                  "sol_b_sombre", "sol_b_clair", "sol_b_cailloux", "sol_b_rune"])
grille("portes", ["porte_fermee", "porte_ouverte", "porte_verrouillee", "porte_scellee",
                  "porte_verrouillee2", "porte_scellee2", "porte_vide"], inset=2)

# --- Blocs (4 cases) ---
im = ouvrir("blocs")
for nom, boite, w, h in [("mur_plein", (46, 46, 364, 728), T, T * 2),
                         ("dalle_unie", (371, 46, 699, 380), T, T),
                         ("dalle_fleches", (709, 46, 1045, 380), T, T),
                         ("bloc_casse", (1055, 46, 1362, 380), T, T)]:
    enregistrer(reduire(im, boite, w, h, False), nom)
for nom, boite in [("dalle_orange", (371, 394, 699, 728)), ("dalle_fleches2", (709, 394, 1045, 728))]:
    enregistrer(reduire(im, boite, T, T, False), nom)

# --- Accessoires (formes libres, fond magenta -> transparent) ---
im = ouvrir("accessoires")
for nom, boite, w, h in [
    ("torche_eteinte", (5, 5, 229, 245), T, T), ("torche_1", (240, 5, 465, 245), T, T),
    ("torche_2", (475, 5, 697, 245), T, T),
    ("brasero_1", (708, 5, 932, 245), T, T), ("brasero_2", (942, 5, 1165, 245), T, T),
    ("brasero_3", (1178, 5, 1400, 245), T, T),
    ("banniere", (5, 250, 229, 668), T, int(T * 1.9)),
    ("statue_chevalier", (250, 310, 470, 768), T, int(T * 1.9)),
    ("statue_oiseau", (480, 310, 695, 768), T, int(T * 1.9)),
    ("tapis_coin", (710, 250, 935, 515), T, T), ("tapis_milieu", (945, 250, 1165, 515), T, T),
    ("tapis_triangle", (945, 540, 1165, 768), T, T),
    ("vase_1", (1215, 295, 1360, 480), int(T * .6), int(T * .8)),
    ("vase_2", (1215, 555, 1360, 730), int(T * .6), int(T * .8)),
]:
    enregistrer(reduire(im, boite, w, h, True), nom)
print("OK ->", os.path.abspath(SORTIE), len(os.listdir(SORTIE)), "fichiers")
