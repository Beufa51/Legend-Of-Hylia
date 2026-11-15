"""Planche Gemini `originaux/braseros.jpg` (brasero allumé, brasero éteint aux braises + fumée, 4 flammes seules ; fond magenta)
-> Assets/Gemini/tuiles/brasero_eteint.png et brasero_1..6.png (20x26, comme avant : room.gd / brasero.gd inchangés,
   décalage Room.DECALAGE_BRASERO). À lancer APRÈS traiter_pack_donjon.py (qui écrit les anciennes versions).
Le brasero allumé = le brasero éteint (coupe + braises) + une des 4 flammes posée dans la coupe : animation 1 2 3 4 3 2."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/braseros.jpg"
SORTIE = "Assets/Gemini/tuiles/"
L, H = 20, 26
CORPS = (751, 165, 1033, 422)        # brasero éteint, coupé sous la fumée (au bord de la coupe)
FLAMMES = [(152, 545, 282, 698), (463, 516, 616, 698), (792, 492, 945, 698), (1132, 504, 1256, 698)]
FOND_BRAISES = 230                   # y (planche) du fond de la coupe, où naît la flamme

a = np.array(Image.open(SRC).convert("RGB")).astype(int)


def morceau(boite, echelle, sombre=(18, 16, 18)):
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    garde = np.zeros(fond.shape, bool)
    for i, t in enumerate(ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))):
        if t > 300: garde |= lab == i + 1          # le corps (et pas les petites taches)
    c[~garde] = sombre
    w, h = max(1, round(c.shape[1] * echelle)), max(1, round(c.shape[0] * echelle))
    im = Image.fromarray(c.astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.8)).resize((w, h), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = Image.fromarray((garde * 255).astype(np.uint8)).resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*im.split(), al))


e = L / (CORPS[2] - CORPS[0])
corps = morceau(CORPS, e)
eteint = Image.new("RGBA", (L, H), (0, 0, 0, 0))
haut_corps = H - corps.height
eteint.alpha_composite(corps, (0, haut_corps))
eteint.save(SORTIE + "brasero_eteint.png")

pied_flamme = haut_corps + round((FOND_BRAISES - CORPS[1]) * e) + 1
flammes = [morceau(f, e * 1.05, (200, 60, 10)) for f in FLAMMES]
for k, i in enumerate([0, 1, 2, 3, 2, 1]):
    im = eteint.copy()
    f = flammes[i]
    im.alpha_composite(f, ((L - f.width) // 2, max(0, pied_flamme - f.height)))
    im.save(SORTIE + "brasero_%d.png" % (k + 1))
print("brasero_eteint + brasero_1..6 (20x26) ; corps", corps.size, "flammes", [f.size for f in flammes])
