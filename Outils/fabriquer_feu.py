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

# (colonne de départ, rangée, longueur) des traînées claires dans la tuile, pour chaque image
RIDES = {1: [(3, 5, 6), (8, 11, 5), (2, 9, 3)], 2: [(5, 4, 5), (3, 11, 6), (10, 8, 3)]}


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


def flaque(bits, n):
    ext = masque(bits, 1)
    corps = masque(bits, 2)
    cœur = masque(bits, 3)
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    t.paste(Image.new("RGBA", (16, 16), RIVE), mask=ext)        # contour sombre
    t.paste(Image.new("RGBA", (16, 16), BORD), mask=corps)      # lèvre de pierre
    t.paste(Image.new("RGBA", (16, 16), EAU), mask=cœur)        # eau
    d = ImageDraw.Draw(t)
    for y in range(16):
        for x in range(16):
            if not cœur.getpixel((x, y)): continue
            haut = y == 0 or not cœur.getpixel((x, y - 1))
            haut2 = y > 1 and not cœur.getpixel((x, y - 2)) and not haut
            bas = y == 15 or not cœur.getpixel((x, y + 1))
            if haut: d.point((x, y), fill=OMBRE)                 # le rebord nord fait de l'ombre sur l'eau
            elif haut2: d.point((x, y), fill=(14, 72, 66, 255))
            elif bas: d.point((x, y), fill=EAU_CLAIRE)           # reflet du ciel contre le rebord sud
    for (x, y, l) in RIDES[n]:
        for i in range(l):
            if cœur.getpixel((x + i, y)) and cœur.getpixel((x + i, y - 1)):
                d.point((x + i, y), fill=RIDE)
        if cœur.getpixel((x + l // 2, y)):
            d.point((x + l // 2, y), fill=RIDE_FORTE)
    # reflet de lumière sur le bord haut-gauche de la flaque
    for (x, y) in ((3, 3), (4, 3), (3, 4)):
        if cœur.getpixel((x, y)):
            d.point((x, y), fill=EAU_CLAIRE if n == 1 else RIDE)
    return t


if __name__ == "__main__":
    for bits in range(16):
        for n in (1, 2):
            flaque(bits, n).save(os.path.join(SORTIE, "flaque_%d_%d.png" % (bits, n)))
    for ancien in ("flaque_1.png", "flaque_2.png"):
        p = os.path.join(SORTIE, ancien)
        if os.path.exists(p): os.remove(p)
    print("flaques fabriquées (16 formes x 2 images)")
