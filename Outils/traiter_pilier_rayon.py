"""Planche Gemini `originaux/pilier_rayon.jpg` (piliers intacts / brûlés, grands et courts, + débris ; fond magenta)
-> Assets/Gemini/tuiles/pilier.png (petit pilier intact, 16 px de large) et pilier_brule.png (le même, tache dorée là où le rayon frappe).
Utilisés par room.gd (mur isolé d'une case ; le pilier sur lequel s'arrête le rayon de soleil montre sa brûlure).
Ordre : APRÈS traiter_lot_donjon.py (qui écrit l'ancien `pilier`)."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/pilier_rayon.jpg"
SORTIE = "Assets/Gemini/tuiles/"
a = np.array(Image.open(SRC).convert("RGB")).astype(int)
LARGEUR = 16


def decouper(zone):
    x0, y0, x1, y1 = zone
    c = a[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 130)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    garde = lab == (int(np.argmax(tailles)) + 1)          # le pilier seul (pas les étincelles détachées ni la ligne de grille)
    garde = ndimage.binary_fill_holes(garde)
    ys, xs = np.where(garde)
    c = c[ys.min():ys.max() + 1, xs.min():xs.max() + 1]; m = garde[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    c[~m] = (18, 20, 28)
    h, w = c.shape[:2]
    e = LARGEUR / w
    L, H = LARGEUR, max(1, round(h * e))
    im = Image.fromarray(c.astype(np.uint8), "RGB").filter(ImageFilter.GaussianBlur(0.8)).resize((L, H), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=0.8, percent=120, threshold=2))
    alpha = Image.fromarray((m * 255).astype(np.uint8)).resize((L, H), Image.LANCZOS).point(lambda v: 255 if v > 170 else 0)
    return Image.merge("RGBA", (*im.split(), alpha))


for zone, nom in (((375, 5, 680, 378), "pilier"), ((1080, 5, 1384, 378), "pilier_brule")):
    im = decouper(zone)
    im.save(SORTIE + nom + ".png")
    print(nom, im.size)
