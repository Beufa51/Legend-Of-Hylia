"""Outil de développement (APRÈS fabriquer_bloc.py, qui n'est plus qu'un repli) : découpe la planche Gemini `blocs_pierre.jpg`
(bloc simple, bloc à rune dorée, bloc enfoncé, plaque au sol inactive / active, fond magenta) et écrit dans Assets/Gemini/tuiles/ :
  bloc_pierre.png, bloc_pierre_actif.png, bloc_pierre_enfonce.png (le bloc qui comble un trou), marque.png, marque_active.png  (16x16)."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/blocs_pierre.jpg"
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


# SYMBOLE du bloc : la PLUME dorée (même icône que la plume qu'on ramasse en fin de plume : le motif de la Forteresse), pas une lettre.
PLUME = Image.open(SORTIE + "plume_doree.png").convert("RGBA")
GRAVE, GRAVE_CLAIR = (36, 58, 82, 255), (88, 120, 146, 255)


def symbole_plume(im, nom):
    """Efface la rune « R » de Gemini (taches dorées) et pose une plume : creusée sur le bloc simple, dorée (l'icône de la plume) sur les blocs actifs / enfoncés."""
    fond = im.getpixel((4, 5))                         # couleur du panneau de la face supérieure
    for y in range(16):
        for x in range(16):
            r, g, b, a = im.getpixel((x, y))
            if a and r > 170 and b < 140:
                im.putpixel((x, y), fond)
    petite = PLUME.resize((7, 7), Image.LANCZOS)
    x0, y0 = 4, 2
    for j in range(7):
        for i in range(7):
            r, g, b, a = petite.getpixel((i, j))
            if a < 110:
                continue
            if nom == "bloc_pierre":
                im.putpixel((x0 + i, y0 + j), GRAVE_CLAIR)           # le reflet (décalé)
    for j in range(7):
        for i in range(7):
            r, g, b, a = petite.getpixel((i, j))
            if a < 110:
                continue
            im.putpixel((x0 + i, y0 + j), GRAVE if nom == "bloc_pierre" else (r, g, b, 255))
    # un liseré clair décalé sous la plume gravée (effet creusé)


img = np.array(Image.open(SRC).convert("RGB"))
m = ~fond(img)
lab, n = ndimage.label(m)
tailles = ndimage.sum(m, lab, range(1, n + 1))
gardes = [i + 1 for i, t in enumerate(tailles) if t > 5000]
pieces = []
for i in gardes:
    ys, xs = np.where(lab == i)
    pieces.append((xs.min(), xs.max() + 1, ys.min(), ys.max() + 1))
# 5 pièces : rangée du haut (bloc, bloc à rune), rangée du bas (bloc enfoncé, plaque, plaque active)
pieces.sort(key=lambda b: (b[2] // 300, b[0]))
assert len(pieces) == 5, pieces
noms = ["bloc_pierre", "bloc_pierre_actif", "bloc_pierre_enfonce", "marque", "marque_active"]
for nom, (x0, x1, y0, y1) in zip(noms, pieces):
    im = reduire(img, m, x0, x1, y0, y1)
    if nom.startswith("bloc_pierre"):
        symbole_plume(im, nom)
    im.save(SORTIE + nom + ".png")
# la marque VIDE doit attirer l'oeil (règle : une marque dorée au sol = « il y a quelque chose à poser ici ») :
# on reprend la forme de la marque ACTIVE avec son or éteint (terni)
act = Image.open(SORTIE + "marque_active.png").convert("RGBA")
vide = Image.open(SORTIE + "marque.png").convert("RGBA")
for y in range(16):
    for x in range(16):
        r, g, b, a = act.getpixel((x, y))
        if a and r > 190 and g > 160 and b < 150:
            vide.putpixel((x, y), (146, 124, 56, 255))
vide.save(SORTIE + "marque.png")
print("blocs Gemini découpés :", noms)
