"""Planche Gemini `originaux/pots.jpg` (6 pots : 3 couleurs x 2 formes, + 1 pot brisé non utilisé ; fond magenta)
-> Assets/Gemini/tuiles/pot_1..6.png : 1-3 pansus (ocre, bleu, vert) 15x15, 4-6 hauts (ocre, bleu, vert) 11x16.
Utilisé par pot.gd / room.gd (lettre V). Les anciens vase_1/2 (pack Craftpix) restent pour le stand de tir."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/pots.jpg"
SORTIE = "Assets/Gemini/tuiles/"
# zones (x0, y0, x1, y1) de chaque pot sur la planche 1408x768, et taille finale
POTS = [((40, 70, 300, 330), 15), ((345, 70, 605, 330), 15), ((650, 70, 910, 330), 15),
        ((60, 395, 280, 680), 16), ((365, 395, 585, 680), 16), ((670, 395, 890, 680), 16)]

a = np.array(Image.open(SRC).convert("RGB")).astype(int)
for i, ((x0, y0, x1, y1), haut) in enumerate(POTS):
    c = a[y0:y1, x0:x1]
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = ndimage.binary_fill_holes(lab == (np.argmax(tailles) + 1))
    ys, xs = np.where(m)
    c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy(); m = m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    c[~m] = (20, 16, 18)                                   # pas de magenta qui déteint sur le contour
    e = haut / c.shape[0]; L = max(1, round(c.shape[1] * e))
    im = Image.fromarray(c.astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.8)).resize((L, haut), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    alpha = Image.fromarray((m * 255).astype(np.uint8)).resize((L, haut), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    out = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    out.paste(Image.merge("RGBA", (*im.split(), alpha)), ((16 - L) // 2, 16 - haut))
    out.save(SORTIE + "pot_%d.png" % (i + 1))
    print("pot_%d" % (i + 1), (L, haut))
