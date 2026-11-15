"""Planches Gemini -> Assets/Gemini/tuiles/ (à lancer APRÈS traiter_pack_donjon.py et fabriquer_objets.py, qui écrivent les anciennes versions).

- `originaux/pics.jpg` : 5 dalles de piège à pics (rentrés, avertissement, à moitié, sortis, écrasés)
  -> pics_1..5.png (16x24 : la dalle occupe les 16 px du bas, les pointes dépassent au-dessus) + pics_ecrase.png.
  Ordre attendu par pics.gd : 1 rentrés, 2 rentrés, 3 petites pointes, 4 à moitié, 5 sortis.
- `originaux/plume_doree.jpg` : 2 plumes dorées (normale, brillante) -> plume_doree.png et plume_doree_eclat.png (16x16).
"""
import numpy as np
from PIL import Image, ImageFilter
from collections import deque

SORTIE = "Assets/Gemini/tuiles/"


def plus_grande_composante(m):
    h, w = m.shape
    lab = np.zeros((h, w), int); n = 0; tailles = {}
    for sy in range(h):
        for sx in range(w):
            if m[sy, sx] and not lab[sy, sx]:
                n += 1; lab[sy, sx] = n; q = deque([(sy, sx)]); t = 0
                while q:
                    y, x = q.popleft(); t += 1
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and m[yy, xx] and not lab[yy, xx]:
                            lab[yy, xx] = n; q.append((yy, xx))
                tailles[n] = t
    return lab == max(tailles, key=tailles.get) if tailles else m


def reduire(rgb, masque, L, H, fond=(20, 22, 30)):
    """Réduit une image (tableau RGB + masque booléen) en L x H, contours nets. Hors du masque, la couleur
    est remplacée par `fond` (sombre) pour que le magenta ne déteigne pas sur les bords."""
    rgb = rgb.copy(); rgb[~masque] = fond
    im = Image.fromarray(rgb.astype(np.uint8), "RGB")
    a = Image.fromarray((masque * 255).astype(np.uint8)).resize((L, H), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    c = im.filter(ImageFilter.GaussianBlur(0.6)).resize((L, H), Image.LANCZOS)
    c = c.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    return Image.merge("RGBA", (*c.split(), a))


def dilater(m, r):
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


# --- Pics ---------------------------------------------------------------------------------
# Dalles mesurées sur la planche (1408x768) : x de chaque dalle, y de la dalle 264..516 ; les pointes montent jusqu'à y≈182.
DALLES_X = [(52, 299), (312, 563), (576, 832), (845, 1097), (1110, 1359)]
Y_DALLE, Y_BAS = 264, 516
img = np.array(Image.open("Assets/Gemini/originaux/pics.jpg").convert("RGB")).astype(int)
hauteur_dessus = round((Y_BAS - Y_DALLE) * 8 / 16)        # 8 px de sortie au-dessus d'une dalle de 16 px
planches = []
for (x0, x1) in DALLES_X:
    c = img[Y_DALLE - hauteur_dessus:Y_BAS, x0:x1]
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    m = np.zeros(r.shape, bool)
    m[hauteur_dessus:, :] = True                           # la dalle : entièrement opaque
    haut = c[:hauteur_dessus]
    hr, hg, hb = haut[..., 0], haut[..., 1], haut[..., 2]
    argent = ((hr + hg + hb > 480) | ((hr + hg + hb > 380) & (hg - hr < 22))) & ~((hr > 150) & (hb > 130) & (hg < 120))  # acier des pointes (pas les joints clairs du carrelage, ni le magenta)
    terre = (hr > hb + 20) & (hr > 70) & (hg > hb) & ~((hb > 100) & (hg < hr - 40))   # éclats et cailloux (dalle écrasée), pas le magenta
    garde = argent | terre
    proche = dilater(garde, 7)
    sombre = (hr + hg + hb < 170) & proche                 # contours sombres des pointes seulement (pas la grille du carrelage)
    m[:hauteur_dessus] = garde | sombre
    planches.append(reduire(c, m, 16, 24))

noms = [0, 0, 1, 2, 3]
for k, i in enumerate(noms):
    planches[i].save(SORTIE + "pics_%d.png" % (k + 1))
planches[4].save(SORTIE + "pics_ecrase.png")
print("pics_1..5 + pics_ecrase (16x24)")

# --- Plume dorée --------------------------------------------------------------------------
plume = np.array(Image.open("Assets/Gemini/originaux/plume_doree.jpg").convert("RGB")).astype(int)
W = plume.shape[1]
for nom, (x0, x1) in (("plume_doree", (0, W // 2)), ("plume_doree_eclat", (W // 2, W))):
    c = plume[:, x0:x1]
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    # garder l'or (bleu faible) et le contour brun sombre ; le halo (or mêlé de magenta) a trop de bleu
    m = ((b < g - 25) & (r > 120)) | ((r + g + b < 260) & (b < 120))
    m = plus_grande_composante(m)
    ys, xs = np.where(m)
    c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; m = m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    cote = max(c.shape[0], c.shape[1])                    # carré : la plume en diagonale remplit la case
    carre = np.zeros((cote, cote, 3), int); mc = np.zeros((cote, cote), bool)
    oy, ox = (cote - c.shape[0]) // 2, (cote - c.shape[1]) // 2
    carre[oy:oy + c.shape[0], ox:ox + c.shape[1]] = c; mc[oy:oy + c.shape[0], ox:ox + c.shape[1]] = m
    reduire(carre, mc, 16, 16, (45, 28, 10)).save(SORTIE + nom + ".png")
    print(nom, "(16x16)")
