"""Outil de développement : transforme les planches Gemini (Assets/Gemini/originaux)
en petites images prêtes pour Godot (Assets/Gemini/tuiles), fond magenta -> transparent.
Usage : python3 Outils/traiter_gemini.py [taille_tuile]   (16 par défaut)"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
from decouper import cases

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini")
T = int(sys.argv[1]) if len(sys.argv) > 1 else 16
# Petites tuiles : réduction plus nette (Lanczos) + léger renforcement des contours
REDUC = Image.LANCZOS if T < 24 else Image.BOX
SORTIE = os.path.join(RACINE, "tuiles")
os.makedirs(SORTIE, exist_ok=True)


def ouvrir(nom):
    return Image.open(os.path.join(RACINE, "originaux", nom + ".jpg")).convert("RGB")


def reduire(img, boite, w, h, transparent):
    """Découpe `boite`, réduit à w x h pixels (moyenne par blocs). Option : fond magenta -> transparent."""
    c = img.crop(boite)
    if not transparent:
        return c.resize((w, h), REDUC)
    a = np.array(c).astype(int)
    magenta = (a[..., 0] > 170) & (a[..., 2] > 170) & (a[..., 1] < 130)
    # on grossit un peu le magenta pour manger la frange de compression JPG
    m = Image.fromarray((magenta * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))
    opaque = (np.array(m) == 0).astype(float)
    rgb = a * opaque[..., None]
    # moyenne pondérée par l'opacité (pas de bord rose)
    pr = Image.fromarray(rgb.astype(np.uint8)).resize((w, h), REDUC)
    po = Image.fromarray((opaque * 255).astype(np.uint8)).resize((w, h), REDUC)
    po_a = np.array(po).astype(float) / 255
    rgb_r = np.array(pr).astype(float) / np.maximum(po_a[..., None], 1e-3)
    alpha = (po_a > 0.5) * 255
    out = np.dstack([np.clip(rgb_r, 0, 255), alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def nettoyer(img):
    """Enlève les pixels violets/rosés restants (frange du fond magenta après compression JPG)."""
    a = np.array(img.convert("RGBA")).astype(int)
    rose = ((a[..., 0] - a[..., 1]) > 28) & ((a[..., 2] - a[..., 1]) > 28)
    if img.mode == "RGBA":
        a[rose, 3] = 0
    else:
        # image opaque : on remplace le pixel rose par la médiane de ses voisins
        med = np.array(img.convert("RGB").filter(ImageFilter.MedianFilter(5))).astype(int)
        a[rose, :3] = med[rose]
    return Image.fromarray(a.astype(np.uint8), "RGBA" if img.mode == "RGBA" else "RGBA").convert(img.mode)


def enregistrer(img, nom):
    img = nettoyer(img)
    if T < 24 and img.mode in ("RGB", "RGBA"):
        rgb = img.convert("RGB").filter(ImageFilter.UnsharpMask(radius=0.8, percent=140, threshold=2))
        if img.mode == "RGBA":
            rgb.putalpha(img.getchannel("A"))
        img = rgb
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
for nom, boite, w, h in [("mur_plein", (52, 52, 358, 722), T, T * 2),
                         ("dalle_unie", (381, 56, 689, 370), T, T),
                         ("dalle_fleches", (719, 56, 1035, 370), T, T),
                         ("bloc_casse", (1065, 56, 1352, 370), T, T)]:
    enregistrer(reduire(im, boite, w, h, False), nom)
for nom, boite in [("dalle_orange", (381, 404, 689, 718)), ("dalle_fleches2", (719, 404, 1035, 718))]:
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
# --- Murs (planche murs.jpg) : un liseré de pierre (le "bord") du côté du sol + un fond sombre ---
# Chaque pièce est une tuile T x T RGBA : seul le liseré est opaque, le reste est transparent
# (on pose donc `mur_fond` dessous, puis les liserés par-dessus selon les voisins).
im = ouvrir("murs")
A = np.array(im).astype(int)
fond = A[130:230, 100:300].reshape(-1, 3).mean(axis=0)  # couleur du fond sombre
FOND = tuple(int(v) for v in fond)
# Sol plat (style Zelda SNES) : couleur moyenne de la dalle + fin quadrillage
dalle = np.array(Image.open(os.path.join(SORTIE, "sol_b_dalle.png")).convert("RGB")).astype(float)
base = dalle.reshape(-1, 3).mean(axis=0) * 0.92
plat = np.tile(base, (T, T, 1))
plat[:, T - 1] *= 0.86   # trait sombre à droite
plat[T - 1, :] *= 0.86   # trait sombre en bas
plat[0, :] = np.minimum(plat[0, :] * 1.08, 255)  # trait clair en haut
plat[:, 0] = np.minimum(plat[:, 0] * 1.08, 255)  # trait clair à gauche
enregistrer(Image.fromarray(plat.astype(np.uint8), "RGB"), "sol_plat")
# Fond de mur : briques de la planche des sols, assombries
brique = Image.open(os.path.join(SORTIE, "sol_a_brique.png")).convert("RGB")
enregistrer(Image.fromarray((np.array(brique).astype(float) * 0.72).astype(np.uint8), "RGB"), "mur_fond")


def piece(boite, efface):
    """Découpe `boite` (cellule de 340x352), rend transparent les rectangles `efface` (coord. relatives)."""
    x0, y0, x1, y1 = boite
    rgba = np.dstack([A[y0:y1, x0:x1], np.full((y1 - y0, x1 - x0), 255)]).astype(np.uint8)
    for (a, b, c, d) in efface:
        rgba[b:d, a:c, 3] = 0
    # le magenta du séparateur (bords de cellule) devient transparent aussi
    r, g, bl = rgba[..., 0].astype(int), rgba[..., 1].astype(int), rgba[..., 2].astype(int)
    rgba[(r > 170) & (bl > 170) & (g < 130), 3] = 0
    pr = Image.fromarray(rgba[..., :3]).resize((T, T), REDUC)
    pa = Image.fromarray(rgba[..., 3]).resize((T, T), REDUC)
    out = np.dstack([np.array(pr), (np.array(pa) > 127) * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


W, H = 340, 352
# (boite de la cellule, zones à effacer) ; liseré en haut / bas / gauche / droite, puis 4 coins
pieces = {
    "mur_bord_n": ((18, 30, 358, 382), [(0, 100, W, H)]),
    "mur_bord_s": ((363, 30, 703, 382), [(0, 0, W, 262)]),
    "mur_bord_o": ((710, 30, 1050, 382), [(88, 0, W, H)]),
    "mur_bord_e": ((1050, 30, 1390, 382), [(0, 0, 252, H)]),
    "mur_coin_no": ((18, 388, 358, 740), [(88, 88, W, H)]),
    "mur_coin_ne": ((363, 388, 703, 740), [(0, 88, 252, H)]),
    "mur_coin_so": ((710, 388, 1050, 740), [(88, 0, W, 272)]),
    "mur_coin_se": ((1050, 388, 1390, 740), [(0, 0, 252, 272)]),
}
for nom, (boite, efface) in pieces.items():
    enregistrer(piece(boite, efface), nom)
# "dot" : angle rentrant (le sol n'est qu'en diagonale). On prend le petit carré d'angle d'un coin.
for nom, source, coin in [("mur_dot_se", "mur_coin_se", (T - 9, T - 9)), ("mur_dot_so", "mur_coin_so", (0, T - 9)),
                          ("mur_dot_ne", "mur_coin_ne", (T - 9, 0)), ("mur_dot_no", "mur_coin_no", (0, 0))]:
    src = Image.open(os.path.join(SORTIE, source + ".png"))
    dot = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    dot.paste(src.crop((coin[0], coin[1], coin[0] + 9, coin[1] + 9)), coin)
    enregistrer(dot, nom)
print("OK ->", os.path.abspath(SORTIE), len(os.listdir(SORTIE)), "fichiers")
