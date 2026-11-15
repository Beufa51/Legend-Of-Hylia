"""Planche Gemini `originaux/torches.jpg` : 4 flammes (rangée du bas) -> nouvelles flammes des torches murales
Assets/Gemini/tuiles/torche_1..6.png (12x24, mêmes noms/tailles qu'avant : room.gd inchangé ; animation 1 2 3 4 3 2).
La coupe de fer des torches reste celle du pack donjon (le support Gemini de la planche est vu DE PROFIL : il ne va pas
sur le mur du fond ; gardé pour de futures torches sur les murs de côté). À lancer APRÈS traiter_pack_donjon.py.
La coupe est mémorisée une fois dans torche_support.png (tirée de l'ancienne torche_1, sans sa flamme)."""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/torches.jpg"
SORTIE = "Assets/Gemini/tuiles/"
FLAMMES = [(105, 539, 247, 716), (446, 468, 610, 716), (798, 422, 962, 716), (1150, 504, 1314, 716)]
HAUT_MAX = 16          # hauteur de la plus grande flamme (px)
PIED = 18              # rangée où la flamme sort de la coupe

support_png = SORTIE + "torche_support.png"
if not os.path.exists(support_png):
    t = np.array(Image.open(SORTIE + "torche_1.png").convert("RGBA")).astype(int)
    flamme = (t[..., 0] > 150) & (t[..., 2] < 120) & (t[..., 3] > 0)
    t[flamme] = 0
    Image.fromarray(t.astype(np.uint8), "RGBA").save(support_png)
support = Image.open(support_png).convert("RGBA")

a = np.array(Image.open(SRC).convert("RGB")).astype(int)
echelle = HAUT_MAX / max(y1 - y0 for (_, y0, _, y1) in FLAMMES)
flammes = []
for (x0, y0, x1, y1) in FLAMMES:
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    m = ~((r > 150) & (b > 150) & (g < 120))
    lab, n = ndimage.label(m)
    m = lab == (np.argmax(ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))) + 1)
    c[~m] = (190, 50, 10)
    w, h = max(1, round(c.shape[1] * echelle)), max(1, round(c.shape[0] * echelle))
    im = Image.fromarray(c.astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.8)).resize((w, h), Image.LANCZOS)
    al = Image.fromarray((m * 255).astype(np.uint8)).resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    flammes.append(Image.merge("RGBA", (*im.split(), al)))

for k, i in enumerate([0, 1, 2, 3, 2, 1]):
    out = Image.new("RGBA", support.size, (0, 0, 0, 0))
    f = flammes[i]
    out.alpha_composite(f, ((support.width - f.width) // 2, max(0, PIED - f.height)))
    out.alpha_composite(support)          # le bord de la coupe passe DEVANT le pied de la flamme
    out.save(SORTIE + "torche_%d.png" % (k + 1))
print("torche_1..6", support.size, [f.size for f in flammes])
