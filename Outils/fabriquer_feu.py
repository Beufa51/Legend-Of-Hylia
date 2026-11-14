"""Outil de développement (APRÈS traiter_gemini.py) : fabrique les FLAQUES d'eau de la salle « lance enflammée » (Plume 2a).
  flaque_<bits>_<1|2>.png : tuile 16x16 qui se raccorde à ses voisines (bits : 1 = eau au nord, 2 = sud, 4 = ouest, 8 = est) ;
  les bords sans voisine sont arrondis (rive sombre + liseré clair), l'intérieur est de l'eau profonde avec des traînées claires
  qui bougent entre les 2 images (même style de rides que le pack Craftpix `water_detilazation_v2.png`)."""
import os
from PIL import Image, ImageDraw, ImageChops

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
S = 8   # sur-échantillonnage pour des bords propres
# Palette tirée de la planche Gemini `eau.jpg` (rebord clair, eau vert sombre). Canal creusé dans la dalle : lèvre de pierre claire, ombre sous la lèvre, eau sombre vert-bleu (peu saturée, accordée à la pierre)
RIVE = (18, 34, 44, 255)        # contour sombre
BORD = (170, 192, 180, 255)     # lèvre de pierre éclairée
OMBRE = (8, 52, 52, 255)       # ombre portée du rebord nord
EAU = (22, 96, 84, 255)
EAU_CLAIRE = (34, 124, 102, 255)
RIDE = (140, 214, 188, 255)
RIDE_FORTE = (214, 240, 240, 255)

# TEXTURE DE L'EAU = celle de la planche Gemini `eau.jpg` (canal vertical, eau seule), réduite à 8 px de large puis découpée
# par variante et par image (l'image 2 décale la texture d'1 px : l'eau « coule »).
SRC_EAU = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "originaux", "eau.jpg")
_im = Image.open(SRC_EAU).convert("RGB").crop((790, 30, 868, 765))
TEXTURE = _im.resize((8, round(735 * 8 / 78)), Image.LANCZOS).quantize(16, dither=Image.NONE).convert("RGB")
VAR_DECALAGE = [0, 19, 41, 62]


def masque(bits, marge):
    n, s, o, e = bits & 1, bits & 2, bits & 4, bits & 8
    x0, y0, x1, y1 = (0 if o else marge), (0 if n else marge), (16 if e else 16 - marge), (16 if s else 16 - marge)
    m = Image.new("L", (16 * S, 16 * S), 0)
    d = ImageDraw.Draw(m)
    # un coin est arrondi seulement si les deux côtés qui le forment n'ont pas de voisin
    coins = (not n and not o, not n and not e, not s and not e, not s and not o)   # haut-gauche, haut-droit, bas-droit, bas-gauche
    rayon = max(0, min(5 * S, (x1 - x0) * S // 2 - 3, (y1 - y0) * S // 2 - 3))
    d.rounded_rectangle((x0 * S, y0 * S, x1 * S - 1, y1 * S - 1), radius=rayon, fill=255, corners=coins)
    return m.resize((16, 16), Image.LANCZOS).point(lambda v: 255 if v > 127 else 0)


def flaque(bits, v, n):
    """Même profil que la planche Gemini : contour sombre, lèvre de pierre claire (2 px), contour, ombre du rebord, eau texturée."""
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    couches = [(0, RIVE), (1, BORD), (3, RIVE)]
    for marge, couleur in couches:
        t.paste(Image.new("RGBA", (16, 16), couleur), mask=masque(bits, marge))
    eau = masque(bits, 4)
    horizontal = bool(bits & 12) and not (bits & 3)   # canal horizontal : la texture est tournée d'un quart de tour
    th = TEXTURE.height
    decalage = VAR_DECALAGE[v] + (n - 1)
    d = ImageDraw.Draw(t)
    def dedans(x, y):
        if y < 0: return bool(bits & 1)
        if y > 15: return bool(bits & 2)
        if x < 0: return bool(bits & 4)
        if x > 15: return bool(bits & 8)
        return bool(eau.getpixel((x, y)))
    for y in range(16):
        for x in range(16):
            if not eau.getpixel((x, y)): continue
            u, w = (y - 4) % 8, x + decalage
            if not horizontal:
                u, w = (x - 4) % 8, y + decalage
            c = TEXTURE.getpixel((u, w % th))
            # ombre du rebord nord et ouest sur l'eau
            if not dedans(x, y - 1): c = OMBRE
            elif not dedans(x, y - 2): c = (10, 62, 60)
            elif not dedans(x - 1, y) and not (bits & 4): c = OMBRE
            t.putpixel((x, y), tuple(c[:3]) + (255,))
    return t


if __name__ == "__main__":
    for bits in range(16):
        for v in range(4):
            for n in (1, 2):
                flaque(bits, v, n).save(os.path.join(SORTIE, "flaque_%d_%d_%d.png" % (bits, v, n)))
        for n in (1, 2):   # anciens noms (sans variante)
            p = os.path.join(SORTIE, "flaque_%d_%d.png" % (bits, n))
            if os.path.exists(p): os.remove(p)
    for ancien in ("flaque_1.png", "flaque_2.png"):
        p = os.path.join(SORTIE, ancien)
        if os.path.exists(p): os.remove(p)
    print("flaques fabriquées (16 formes x 2 images)")
