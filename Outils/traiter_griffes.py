"""Outil de développement : fabrique les GRIFFES du Parvis EXACTEMENT comme les pieds de pierre de l'image du coq-forteresse
(Assets/Gemini/originaux/Coq_forteresse.jpg). On découpe chaque griffe, jambe comprise (la jambe remonte et disparaît dans la forêt : le haut est caché par des arbres),
on retire le sol, on réduit à la taille du village. Les griffes sont LISSES (aucune niche : l'emplacement du symbole est sur la pierre posée devant, voir traiter_pierres.py).
  griffe GAUCHE (pied gauche de l'image) -> v_griffe_g.png ; griffe DROITE -> v_griffe_d.png
Usage : python3 Outils/traiter_griffes.py [largeur_px]    (défaut 76)"""
import os, sys
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

RACINE = os.path.join(os.path.dirname(__file__), "..")
SOURCE = os.path.join(RACINE, "Assets", "Gemini", "originaux", "Coq_forteresse.jpg")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
ZONE_G = (400, 520, 600, 735)        # griffe gauche dans l'image 1408x768 (zone de 200 x 215)
ZONE_D = (808, 520, 1008, 735)       # griffe droite
# Dans la zone (griffe gauche) : tout ce qui est à GAUCHE de x = 141 au-dessus de y = 100 (la jambe), plus tout ce qui est sous y = 100 (le pied). La tour de la patte (x > 141) est exclue.
POLY_G = [(0, 84), (141, 84), (141, 100), (200, 100), (200, 215), (0, 215)]
ALLONGE = 16        # la jambe est prolongée vers le haut (en px réduits) : elle disparaît dans la forêt, le haut est caché par les arbres


def sol(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (g > b + 6) & (g > r + 10)


def lampe(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 150) & (g > 80) & (b < 110)      # la petite torche posée près de la cheville : on l'enlève


def route(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > b + 8) & (r >= g - 2)           # la terre du chemin (brune) : ce n'est pas de la pierre


def plus_grande(m):
    h, w = m.shape
    vu = np.zeros_like(m, bool)
    meilleur, taille = None, 0
    for y in range(h):
        for x in range(w):
            if m[y, x] and not vu[y, x]:
                q = deque([(y, x)]); vu[y, x] = True; comp = [(y, x)]
                while q:
                    cy, cx = q.popleft()
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not vu[ny, nx]:
                            vu[ny, nx] = True; q.append((ny, nx)); comp.append((ny, nx))
                if len(comp) > taille:
                    taille, meilleur = len(comp), comp
    r = np.zeros_like(m, bool)
    for y, x in meilleur:
        r[y, x] = True
    return r


def decouper(zone, miroir=False):
    im = Image.open(SOURCE).convert("RGB").crop(zone)
    w, h = im.size
    poly = [(w - x, y) for x, y in POLY_G] if miroir else POLY_G
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    a = np.array(im)
    masque = (np.array(m) > 0) & ~sol(a) & ~lampe(a) & ~route(a)
    masque = plus_grande(np.array(Image.fromarray((masque * 255).astype("uint8")).filter(ImageFilter.MedianFilter(3))) > 127)
    alpha = Image.fromarray((masque * 255).astype("uint8"))
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba.crop(rgba.getbbox())


def reduire(img, largeur):
    h = round(img.height * largeur / img.width)
    petit = img.resize((largeur, h), Image.LANCZOS)
    rgb = petit.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1, percent=90, threshold=2))
    rgb = ImageEnhance.Brightness(rgb).enhance(1.22)   # un peu plus claires : sur l'herbe du village elles doivent bien se lire
    alpha = petit.split()[3].point(lambda v: 255 if v > 110 else 0)
    q = rgb.quantize(colors=28, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    q.putalpha(alpha)
    return prolonger(q)


def prolonger(img):
    """Prolonge la jambe vers le haut : on répète en colonne les premières rangées de pierre (un peu plus sombres) ; les arbres cacheront le haut."""
    w, h = img.size
    out = Image.new("RGBA", (w, h + ALLONGE), (0, 0, 0, 0))
    out.alpha_composite(img, (0, ALLONGE))
    px, src = out.load(), img.load()
    ref = 3                                           # rangée de référence (la 4e en partant du haut)
    for k in range(1, ALLONGE + 1):
        y = ALLONGE - k
        for x in range(w):
            r, g, b, a = src[x, ref]
            if a > 0:
                f = max(0.55, 1.0 - k * 0.025)
                px[x, y] = (int(r * f), int(g * f), int(b * f), 255)
    return out


if __name__ == "__main__":
    largeur = int(sys.argv[1]) if len(sys.argv) > 1 else 76
    for cote, zone, miroir in (("g", ZONE_G, False), ("d", ZONE_D, True)):
        petit = reduire(decouper(zone, miroir), largeur)
        petit.save(os.path.join(SORTIE, "v_griffe_%s.png" % cote))
        print("griffe %s : %dx%d px" % (cote, petit.width, petit.height))
