"""Découpe la planche Gemini `plots.jpg` (4 colonnes x 3 rangées, fond magenta, vue de face) -> Assets/Gemini/tuiles/ :
plot_haut_o/u (blocs levés) et plot_bas_o/u (dalles baissées), 16x16, cristal_o / cristal_u (16x18),
dalle_rouge / dalle_bleue / dalle_doree (16x16, étirées en carré). Les autres cases (dalles losanges, levier, piédestal) ne sont pas utilisées."""
import numpy as np
from PIL import Image, ImageFilter
from collections import deque

SRC = "Assets/Gemini/originaux/plots.jpg"
SORTIE = "Assets/Gemini/tuiles/"
# (rangée, colonne) -> (nom, largeur, hauteur, étirer)
CASES = {(0, 0): ("plot_haut_o", 16, 16, False), (0, 1): ("plot_haut_u", 16, 16, False),
         (1, 0): ("plot_bas_o", 16, 16, True), (1, 1): ("plot_bas_u", 16, 16, True),
         (0, 2): ("cristal_o", 16, 18, False), (0, 3): ("cristal_u", 16, 18, False),
         (1, 2): ("dalle_rouge", 16, 16, True), (1, 3): ("dalle_bleue", 16, 16, True),
         (2, 0): ("dalle_doree", 16, 16, True)}
MARGE = 8   # ignore les traits noirs de la grille entre les cases

def fond(rgb):
    r, g, b = [rgb[..., i].astype(int) for i in range(3)]
    return (r > 120) & (b > 120) & (g < np.minimum(r, b) - 45)

img = Image.open(SRC).convert("RGB"); W, Ht = img.size
for (j, i), (nom, L, H, etirer) in CASES.items():
    c = np.array(img.crop((i * W // 4 + MARGE, j * Ht // 3 + MARGE, (i + 1) * W // 4 - MARGE, (j + 1) * Ht // 3 - MARGE)))
    m = ~fond(c); h, w = m.shape
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
    m = lab == max(tailles, key=tailles.get)
    ys, xs = np.where(m)
    im = Image.fromarray(np.dstack([c, (m * 255).astype(np.uint8)]), "RGBA").crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    if etirer: nw, nh = L, H
    else:
        e = min(L / im.width, H / im.height); nw, nh = max(1, round(im.width * e)), max(1, round(im.height * e))
    a = im.split()[3].resize((nw, nh), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.4)).resize((nw, nh), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=120, threshold=2))
    ar = np.array(rgb).astype(int)
    rose = (ar[..., 0] > ar[..., 1] + 35) & (ar[..., 2] > ar[..., 1] + 35)   # liseré magenta seulement (pas l'orange ni le rouge)
    ar[..., 1] = np.where(rose, np.maximum(ar[..., 1], np.minimum(ar[..., 0], ar[..., 2]) - 12), ar[..., 1])
    ar[..., 0] = np.where(rose, np.minimum(ar[..., 0], ar[..., 2]), ar[..., 0])
    rgb = Image.fromarray(ar.clip(0, 255).astype(np.uint8), "RGB")
    out = Image.new("RGBA", (L, H), (0, 0, 0, 0)); r = Image.merge("RGBA", (*rgb.split(), a))
    out.paste(r, ((L - nw) // 2, H - nh), r); out.save(SORTIE + nom + ".png"); print(nom, (nw, nh))
