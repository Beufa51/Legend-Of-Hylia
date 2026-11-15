"""Outil de développement (APRÈS fabriquer_bloc.py, qui n'est plus qu'un repli) : découpe la planche Gemini `blocs_pierre.jpg`
(8 pièces : blocs au COQ gravé / doré, blocs enfoncés, plaques au sol ; fond magenta) et écrit dans Assets/Gemini/tuiles/ :
  bloc_pierre.png, bloc_pierre_actif.png, bloc_pierre_enfonce.png (le bloc qui comble un trou), marque.png, marque_active.png  (16x16)."""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/blocs_pierre.jpg"
SRC_PLAQUES = "Assets/Gemini/originaux/blocs_pierre_plaques.jpg"   # 1re planche : ses plaques au sol restent lisibles à 16 px (celles de la 2e sont trop fines)
SORTIE = "Assets/Gemini/tuiles/"
CONTOUR = (14, 16, 24)


def fond(rgb):
    r, g, b = [rgb[..., i].astype(int) for i in range(3)]
    return (r > 120) & (b > 120) & (g < np.minimum(r, b) - 45)


def reduire(img, m, x0, x1, y0, y1):
    rgb = img[y0:y1, x0:x1].copy(); masque = m[y0:y1, x0:x1]
    rgb[~masque] = CONTOUR
    p = Image.fromarray(rgb).resize((16, 16), Image.LANCZOS)
    p = p.filter(ImageFilter.UnsharpMask(radius=0.6, percent=70, threshold=2))
    a = Image.fromarray((masque * 255).astype(np.uint8)).resize((16, 16), Image.LANCZOS).point(lambda v: 255 if v > 100 else 0)
    p = p.quantize(colors=22, dither=Image.NONE).convert("RGBA")
    p.putalpha(a)
    return p


# TÊTE DE COQ de profil dessinée à la main (8x7 px) : la tête de coq de Gemini devient une bouillie à 16 px (trop détaillée).
# c = crête, 1 = tête dorée, 2 = ombre, b = bec, e = oeil.
COQ = ["c.c.....",
       "ccccc...",
       ".c1111..",
       ".11e11bb",
       ".1122bb.",
       "..1cc...",
       "..122..."]
COULEURS = {"c": (222, 58, 46, 255), "1": (255, 214, 90, 255), "2": (206, 154, 48, 255), "b": (236, 150, 40, 255), "e": (52, 28, 10, 255)}
GRAVURE = {"c": (72, 102, 126, 255), "1": (48, 73, 98, 255), "2": (42, 64, 88, 255), "b": (66, 95, 119, 255), "e": (30, 46, 68, 255)}


SRC_COQ = "Assets/Gemini/originaux/coq_pictogramme.jpg"   # planche d'icônes de coq (4 couleurs en haut, 4 gravés en bas)
UTILISER_COQ_GEMINI = False   # essayé : à 9x9 px le pictogramme devient une boule jaune (bec et oeil disparaissent) ; le coq dessiné à la main est plus lisible
CHOIX_COQ = 2        # numéro (0-3) de l'icône colorée utilisée
TAILLE_COQ = (9, 9)  # taille sur le bloc, en pixels


def coq_gemini():
    """Découpe l'icône de coq choisie (couleurs) dans la planche Gemini et la réduit EXACTEMENT par moyenne de blocs (BOX) : les gros pixels de l'icône restent nets."""
    a = np.array(Image.open(SRC_COQ).convert("RGB"))
    cases = [(45, 350), (375, 690), (715, 1030), (1058, 1362)]
    x0, x1 = cases[CHOIX_COQ]
    sub = a[70:350, x0 + 28:x1 - 28]
    masque = ~fond(sub)                                 # sans le fond magenta (le cadre noir est hors de la zone)
    ys, xs = np.where(masque)
    boite = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    couleur = Image.fromarray(np.where(masque[..., None], sub, 0).astype(np.uint8)).crop(boite)
    alpha = Image.fromarray((masque * 255).astype(np.uint8)).crop(boite)
    p = couleur.resize(TAILLE_COQ, Image.BOX).convert("RGBA")
    p.putalpha(alpha.resize(TAILLE_COQ, Image.BOX).point(lambda v: 255 if v > 110 else 0))
    return p


def symbole_coq(im, nom, couleur, rect, origine):
    """Efface le coq de Gemini (illisible une fois réduit : on vide le panneau) et pose notre tête de coq : creusée sur le bloc simple, en couleurs sur les blocs actif / enfoncé."""
    x0, x1, y0, y1 = rect
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            im.putpixel((x, y), couleur)
    if UTILISER_COQ_GEMINI and os.path.exists(SRC_COQ):
        coq = coq_gemini()
        ox, oy = 4 + (8 - TAILLE_COQ[0]) // 2, 1 + (8 - TAILLE_COQ[1]) // 2
        for j in range(coq.height):
            for i in range(coq.width):
                r, g, b, al = coq.getpixel((i, j))
                if not al:
                    continue
                if nom == "bloc_pierre":     # gravé : même forme, en bleu-gris très discret (la luminosité de l'icône donne le relief)
                    lum = (r * 3 + g * 6 + b) / 10 / 255.0
                    im.putpixel((ox + i, oy + j), (int(36 + 40 * lum), int(58 + 52 * lum), int(82 + 50 * lum), 255))
                else:
                    im.putpixel((ox + i, oy + j), (r, g, b, 255))
        return
    ox, oy = origine
    for j, ligne in enumerate(COQ):
        for i, c in enumerate(ligne):
            if c != ".":
                im.putpixel((ox + i, oy + j), GRAVURE[c] if nom == "bloc_pierre" else COULEURS[c])

img = np.array(Image.open(SRC).convert("RGB"))
m = ~fond(img)
lab, n = ndimage.label(m)
tailles = ndimage.sum(m, lab, range(1, n + 1))
gardes = [i + 1 for i, t in enumerate(tailles) if t > 5000]
pieces = []
for i in gardes:
    ys, xs = np.where(lab == i)
    pieces.append((xs.min(), xs.max() + 1, ys.min(), ys.max() + 1))
# 8 pièces, 4 colonnes x 2 rangées :
#   haut : bloc (coq gravé), bloc (coq doré), bloc enfoncé dans son trou (avec le sol autour), plaque inactive
#   bas  : bloc (variante), bloc enfoncé (variante, cadre noir), plaque inactive (variante), plaque active
pieces.sort(key=lambda b: (b[2] // 300, b[0]))
assert len(pieces) == 8, pieces
P = pieces
# le bloc ENFONCÉ : on ne garde que le trou (cadre sombre) et le bloc dedans, sans le sol autour
x0, x1, y0, y1 = P[5]
zone = img[y0:y1, x0:x1]
sombre = zone.max(axis=2) < 34
ys, xs = np.where(sombre)
cadre = (x0 + xs.min(), x0 + xs.max() + 1, y0 + ys.min(), y0 + ys.max() + 1)
m_cadre = m.copy()
m_cadre[:] = False
m_cadre[cadre[2]:cadre[3], cadre[0]:cadre[1]] = True
sources = {"bloc_pierre": (P[0], m), "bloc_pierre_actif": (P[1], m), "bloc_pierre_enfonce": (cadre, m_cadre)}
brut = {}
for nom, (boite, masque) in sources.items():
    x0, x1, y0, y1 = boite
    brut[nom] = reduire(img, masque, x0, x1, y0, y1)
couleur_bloc = (58, 84, 108, 255)       # couleur du panneau vide de la face supérieure (bleu-gris de la pierre)
couleur_enfonce = (60, 88, 112, 255)
for nom, im in brut.items():
    if nom == "bloc_pierre_enfonce":
        symbole_coq(im, nom, couleur_enfonce, (3, 12, 1, 10), (4, 2))
    else:
        symbole_coq(im, nom, couleur_bloc, (3, 12, 1, 9), (4, 2))
    im.save(SORTIE + nom + ".png")
# plaques au sol : planche n°1 (même découpe que la v1 : 5 pièces ; plaques = les 2 dernières)
img1 = np.array(Image.open(SRC_PLAQUES).convert("RGB"))
m1 = ~fond(img1)
lab1, n1 = ndimage.label(m1)
t1 = ndimage.sum(m1, lab1, range(1, n1 + 1))
p1 = []
for i in [i + 1 for i, t in enumerate(t1) if t > 5000]:
    ys, xs = np.where(lab1 == i)
    p1.append((xs.min(), xs.max() + 1, ys.min(), ys.max() + 1))
p1.sort(key=lambda b: (b[2] // 300, b[0]))
for nom, boite in (("marque", p1[3]), ("marque_active", p1[4])):
    x0, x1, y0, y1 = boite
    reduire(img1, m1, x0, x1, y0, y1).save(SORTIE + nom + ".png")
# la marque VIDE doit attirer l'oeil (règle : une marque dorée au sol = « il y a quelque chose à poser ici ») :
# on reprend la forme de la marque ACTIVE avec son or éteint (terni)
act = Image.open(SORTIE + "marque_active.png").convert("RGBA")
vide = Image.open(SORTIE + "marque.png").convert("RGBA")
for y in range(16):
    for x in range(16):
        r, g, b, a = act.getpixel((x, y))
        if a and r > 190 and g > 150 and b < 190 and r > b + 40:
            vide.putpixel((x, y), (146, 124, 56, 255))
vide.save(SORTIE + "marque.png")
print("blocs Gemini découpés :", list(sources))
