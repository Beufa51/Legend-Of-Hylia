"""Outil de développement : découpe les 4 planches Gemini du village
(Assets/Gemini/originaux/village_*.jpg) en sprites -> Assets/Gemini/tuiles/v_*.png.
Chaque objet : (planche, boîte source, nom, largeur max px, hauteur max px, mode)
  mode 'fit'   : fond retiré (magenta ou ardoise), réduit en gardant les proportions
  mode 'tuile' : image opaque, redimensionnée EXACTEMENT à w x h
  mode 'maison': comme fit, dans un canevas 64x64 ; la porte (x source) est calée au centre d'une case
Usage : python3 Outils/traiter_village.py [contact.png]"""
import os, sys, json
import numpy as np
from PIL import Image, ImageFilter

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini")
SORTIE = os.path.join(RACINE, "tuiles")

ARDOISE = True   # faux pour la planche des maisons (fond magenta seulement)

def source(n): return Image.open(os.path.join(RACINE, "originaux", "village_%s.jpg" % n)).convert("RGB")

def fond(a):
    """Masque du fond : magenta, ou ardoise sombre bleutée (grille des planches)."""
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    magenta = (r > 120) & (b > 120) & (g < 0.62 * np.minimum(r, b))
    ardoise = ((r - 50) ** 2 + (g - 65) ** 2 + (b - 72) ** 2) < 18 ** 2 if ARDOISE else False
    return magenta | ardoise

def retirer_fond(img):
    a = np.array(img)
    bg = fond(a)
    # on ne retire que le fond relié au bord (remplissage depuis les bords), pas l'intérieur des objets
    h, w = bg.shape
    masque = np.zeros_like(bg)
    pile = [(y, x) for y in (0, h - 1) for x in range(w)] + [(y, x) for x in (0, w - 1) for y in range(h)]
    while pile:
        y, x = pile.pop()
        if 0 <= y < h and 0 <= x < w and bg[y, x] and not masque[y, x]:
            masque[y, x] = True
            pile += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    # on mange la frange d'un pixel
    m2 = masque.copy()
    m2[1:] |= masque[:-1]; m2[:-1] |= masque[1:]; m2[:, 1:] |= masque[:, :-1]; m2[:, :-1] |= masque[:, 1:]
    masque = m2
    if ARDOISE:   # le fond ardoise ENFERMÉ (entre tronc et feuillage...) part aussi, mais avec une tolérance plus stricte
        masque |= ((a[..., 0].astype(int) - 50) ** 2 + (a[..., 1].astype(int) - 65) ** 2 + (a[..., 2].astype(int) - 72) ** 2) < 11 ** 2
    alpha = np.where(masque, 0, 255).astype(np.uint8)
    return np.dstack([a, alpha])

def reduire(rgba, w, h, exact=False):
    im = Image.fromarray(rgba, "RGBA")
    if exact:
        nw, nh = w, h
    else:
        s = min(w / im.width, h / im.height)
        nw, nh = max(1, round(im.width * s)), max(1, round(im.height * s))
    a = np.array(im).astype(float)
    op = a[..., 3] / 255.0
    pre = Image.fromarray((a[..., :3] * op[..., None]).astype(np.uint8)).resize((nw, nh), Image.LANCZOS)
    po = np.array(Image.fromarray((op * 255).astype(np.uint8)).resize((nw, nh), Image.LANCZOS)).astype(float) / 255
    rgb = np.clip(np.array(pre).astype(float) / np.maximum(po[..., None], 1e-3), 0, 255)
    out = Image.fromarray(np.dstack([rgb, (po > 0.5) * 255]).astype(np.uint8), "RGBA")
    return out

def nette(im, couleurs=28):
    """Palette limitée (look SNES) + contours un peu renforcés."""
    alpha = im.getchannel("A")
    rgb = im.convert("RGB").filter(ImageFilter.UnsharpMask(radius=0.7, percent=90, threshold=1))
    rgb = rgb.quantize(colors=couleurs, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    rgb.putalpha(alpha)
    return rgb

# --- objets --------------------------------------------------------------------------
# NATURE (planche nature)
OBJ = [
 ("nature", (15, 8, 245, 288), "v_arbre_a", 32, 32, "fit"),
 ("nature", (270, 8, 490, 288), "v_arbre_b", 32, 32, "fit"),
 ("nature", (525, 15, 715, 288), "v_sapin", 32, 32, "fit"),
 ("nature", (755, 28, 905, 150), "v_buisson", 16, 16, "fit"),
 ("nature", (755, 170, 905, 288), "v_buisson_baies", 16, 16, "fit"),
 ("nature", (88, 308, 175, 462), "v_tournesol", 16, 16, "fit"),
 ("nature", (278, 312, 358, 456), "v_fleur_rouge", 16, 16, "fit"),
 ("nature", (394, 312, 484, 458), "v_marguerite", 16, 16, "fit"),
 ("nature", (8, 305, 78, 378), "v_herbe_1", 14, 14, "fit"),
 ("nature", (188, 305, 252, 372), "v_herbe_2", 14, 14, "fit"),
 ("nature", (535, 312, 715, 468), "v_roche", 32, 32, "fit"),
 ("nature", (765, 335, 890, 452), "v_souche", 16, 16, "fit"),
 ("nature", (15, 488, 250, 592), "v_cloture", 32, 16, "fit"),
 ("nature", (278, 488, 308, 592), "v_poteau", 16, 16, "fit"),
 ("nature", (28, 618, 145, 735), "v_panneau", 16, 16, "fit"),
 ("nature", (205, 612, 312, 752), "v_tonneau", 16, 16, "fit"),
 ("nature", (372, 622, 482, 748), "v_caisse", 16, 16, "fit"),
 ("nature", (555, 610, 705, 752), "v_puits", 32, 32, "fit"),
 # CASERNE
 ("caserne", (772, 395, 900, 538), "v_banniere", 16, 32, "fit"),
 ("caserne", (25, 390, 190, 565), "v_ratelier_lances", 32, 32, "fit"),
 ("caserne", (235, 405, 395, 565), "v_ratelier_armes", 32, 32, "fit"),
 ("caserne", (445, 420, 605, 565), "v_boucliers", 32, 32, "fit"),
 ("caserne", (40, 588, 160, 755), "v_mannequin", 16, 32, "fit"),
 ("caserne", (240, 598, 402, 757), "v_coffre_armes", 32, 32, "fit"),
 ("caserne", (438, 600, 552, 760), "v_lit_caserne", 32, 48, "fit"),
 ("caserne", (640, 618, 722, 755), "v_brasero", 16, 32, "fit"),
 ("caserne", (1130, 418, 1375, 575), "v_table_carte", 48, 32, "fit"),
 ("caserne", (1160, 655, 1390, 735), "v_banc_long", 48, 16, "fit"),
 # INTERIEUR (maison)
 ("interieur", (30, 418, 185, 590), "v_lit_rouge", 32, 40, "fit"),
 ("interieur", (240, 418, 392, 590), "v_lit_bleu", 32, 40, "fit"),
 ("interieur", (440, 392, 722, 568), "v_etagere", 48, 32, "fit"),
 ("interieur", (568, 563, 722, 757), "v_armoire", 32, 40, "fit"),
 ("interieur", (765, 430, 908, 565), "v_table_ronde", 32, 32, "fit"),
 ("interieur", (963, 438, 1220, 572), "v_table", 48, 32, "fit"),
 ("interieur", (1272, 405, 1372, 555), "v_chaise", 16, 24, "fit"),
 ("interieur", (757, 620, 915, 752), "v_coffre", 32, 32, "fit"),
 ("interieur", (1125, 615, 1215, 750), "v_pot", 16, 20, "fit"),
 ("interieur", (1265, 628, 1385, 745), "v_marmite", 16, 16, "fit"),
 ("interieur", (232, 658, 522, 745), "v_banc", 48, 16, "fit"),
 ("interieur", (962, 36, 1172, 158), "v_tapis_rouge", 48, 32, "fit"),
 ("interieur", (1205, 10, 1392, 180), "v_tapis_rond", 48, 48, "fit"),
 ("interieur", (758, 46, 915, 142), "v_paillasson", 32, 16, "fit"),
 ("interieur", (1015, 195, 1150, 385), "v_cheminee", 32, 32, "fit"),
 # SOLS ET MURS (tuiles opaques)
 ("interieur", (10, 8, 205, 190), "v_sol_bois", 16, 16, "tuile"),
 ("interieur", (218, 8, 415, 190), "v_sol_bois_b", 16, 16, "tuile"),
 ("interieur", (430, 8, 630, 190), "v_sol_bois_c", 16, 16, "tuile"),
 ("interieur", (8, 205, 205, 380), "v_mur_a", 32, 32, "tuile"),
 ("interieur", (218, 205, 400, 380), "v_mur_b", 32, 32, "tuile"),
 ("interieur", (440, 205, 612, 380), "v_mur_fenetre", 32, 32, "tuile"),
 ("interieur", (1215, 205, 1395, 380), "v_mur_tableau", 32, 32, "tuile"),
 ("caserne", (10, 8, 205, 190), "v_sol_pierre", 16, 16, "tuile"),
 ("caserne", (8, 202, 205, 380), "v_mur_pierre", 32, 32, "tuile"),
 ("caserne", (218, 198, 408, 380), "v_mur_pierre_cheminee", 32, 32, "tuile"),
]
# MAISONS : (cellule source, centre de la porte en x source, nom)
CELLULES = [(8, 8, 466, 380), (476, 8, 932, 380), (942, 8, 1402, 380), (8, 392, 466, 762), (476, 392, 932, 762), (942, 392, 1402, 762)]
PORTES = [188, 650, 1118, 187, 705, 1118]
NOMS_MAISONS = ["v_maison_orange", "v_maison_bleue", "v_maison_chaume", "v_maison_rouge", "v_maison_caserne", "v_maison_bois"]


def fabriquer_maison(i, img):
    c = CELLULES[i]
    sub = img.crop(c)
    rgba = retirer_fond(sub)
    ys, xs = np.where(rgba[..., 3] > 0)
    # on ignore les petits points parasites : boîte du plus gros morceau
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgba = rgba[y0:y1, x0:x1]
    porte_x = PORTES[i] - c[0] - x0
    petite = reduire(rgba, 64, 62)
    s = petite.width / rgba.shape[1]
    dx = porte_x * s
    col = int(min(3, max(0, round(dx / 16 - 0.5))))
    decal = int(round((col + 0.5) * 16 - dx))
    toile = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    x = max(0, min(64 - petite.width, (64 - petite.width) // 2 + decal))
    toile.alpha_composite(nette(petite), (x, 64 - petite.height))
    # colonne réelle de la porte après décalage
    dx2 = dx + (x - 0)
    col = int(min(3, max(0, round(dx2 / 16 - 0.5))))
    return toile, col


if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    planches = {n: source(n) for n in ("nature", "caserne", "interieur", "maisons")}
    produits = []
    for (p, boite, nom, w, h, mode) in OBJ:
        crop = planches[p].crop(boite)
        if mode == "tuile":
            im = crop.resize((w, h), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=0.7, percent=90, threshold=1))
            im = im.quantize(colors=24, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
        else:
            im = nette(reduire(retirer_fond(crop), w, h))
        im.save(os.path.join(SORTIE, nom + ".png"))
        produits.append((nom, im))
    portes = {}
    for i, nom in enumerate(NOMS_MAISONS):
        ARDOISE = False
        im, col = fabriquer_maison(i, planches["maisons"])
        im.save(os.path.join(SORTIE, nom + ".png"))
        portes[nom] = col
        produits.append((nom, im))
    # murs pleins 16x16 (côtés et bas des pièces) : bois sombre (sol assombri + liseré clair) et pierre
    sol = Image.open(os.path.join(SORTIE, "v_sol_bois.png")).convert("RGB")
    sombre = Image.eval(sol, lambda v: int(v * 0.42))
    sombre.paste(Image.new("RGB", (16, 2), (150, 100, 60)), (0, 0))
    sombre.save(os.path.join(SORTIE, "v_mur_bois.png"))
    Image.open(os.path.join(SORTIE, "v_mur_pierre.png")).convert("RGB").crop((0, 0, 16, 16)).save(os.path.join(SORTIE, "v_mur_pierre_16.png"))
    print("portes (colonne de la porte, 0..3) :", portes)
    if len(sys.argv) > 1:   # planche-contact (x3) pour vérifier à l'œil
        fond_c = Image.new("RGBA", (1000, 700), (60, 110, 60, 255))
        x = y = 4; hmax = 0
        for nom, im in produits:
            if x + im.width > 330: x = 4; y += hmax + 4; hmax = 0
            fond_c.alpha_composite(im, (x, y)); x += im.width + 4; hmax = max(hmax, im.height)
        fond_c.crop((0, 0, 340, y + hmax + 4)).resize((340 * 3, (y + hmax + 4) * 3), Image.NEAREST).save(sys.argv[1])
