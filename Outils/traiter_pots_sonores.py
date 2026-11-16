"""Planche Gemini `originaux/pots_sonores.jpg` (pot doré avec ondes, ondes seules, pots brisés, pot simple ; fond magenta)
-> Assets/Gemini/tuiles/pot_sonore.png (pot intact 16x16), pot_sonore_brise.png (tessons 16x16), sonore_anneaux.png (2 anneaux dorés 40x40).
Utilisés par Scripts/pot_sonore.gd (lettre `U`). Ordre : n'importe quand après traiter_pots.py."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/pots_sonores.jpg"
SORTIE = "Assets/Gemini/tuiles/"
a = np.array(Image.open(SRC).convert("RGB")).astype(int)


def decouper(zone, taille, contour=True):
    x0, y0, x1, y1 = zone
    c = a[y0:y1, x0:x1]
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 130)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    garde = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > 40])   # on garde tous les morceaux (tessons, anneaux)
    ys, xs = np.where(garde)
    c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy(); m = garde[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    c[~m] = (20, 16, 18) if contour else (230, 190, 90)
    h, w = c.shape[:2]
    e = taille / max(h, w)
    L, H = max(1, round(w * e)), max(1, round(h * e))
    im = Image.fromarray(c.astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.7)).resize((L, H), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    alpha = Image.fromarray((m * 255).astype(np.uint8)).resize((L, H), Image.LANCZOS).point(lambda v: 255 if v > 90 else 0)
    return Image.merge("RGBA", (*im.split(), alpha))


def poser(im, nom, cote, bas=True):
    out = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
    out.paste(im, ((cote - im.width) // 2, (cote - im.height) if bas else (cote - im.height) // 2), im)
    out.save(SORTIE + nom + ".png")
    print(nom, im.size)


poser(decouper((60, 395, 300, 690), 15), "pot_sonore", 16)                      # le pot doré simple
poser(decouper((360, 390, 700, 760), 15), "pot_sonore_brise", 16, bas=False)    # tessons
poser(decouper((365, 10, 700, 370), 40, contour=False), "sonore_anneaux", 40, bas=False)   # 2 anneaux dorés
