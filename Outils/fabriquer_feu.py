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

# 4 variantes de tuile (pour que l'eau ne se répète pas) : chacune a UNE ondelette courbe (suite de points (dx, dy)) et un éclat
VARIANTES = [
    {"onde": [(0, 1), (1, 0), (2, 0), (3, 1), (4, 1)], "pos": (3, 9), "eclat": (11, 4), "ton": (2, 11)},
    {"onde": [(0, 0), (1, 1), (2, 1), (3, 0)], "pos": (9, 5), "eclat": (4, 11), "ton": (9, 9)},
    {"onde": [(0, 1), (1, 1), (2, 0), (3, 0), (4, 1), (5, 1)], "pos": (4, 4), "eclat": (12, 10), "ton": (3, 3)},
    {"onde": [(0, 0), (1, 0), (2, 1)], "pos": (8, 10), "eclat": (6, 3), "ton": (10, 2)},
]


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
    ext = masque(bits, 1)
    corps = masque(bits, 2)
    cœur = masque(bits, 3)
    var = VARIANTES[v]
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    t.paste(Image.new("RGBA", (16, 16), RIVE), mask=ext)        # contour sombre
    t.paste(Image.new("RGBA", (16, 16), BORD), mask=corps)      # lèvre de pierre
    t.paste(Image.new("RGBA", (16, 16), EAU), mask=cœur)        # eau lisse
    d = ImageDraw.Draw(t)
    def dedans(x, y):   # hors de la tuile : on regarde si la voisine est de l'eau (bits)
        if y < 0: return bool(bits & 1)
        if y > 15: return bool(bits & 2)
        if x < 0: return bool(bits & 4)
        if x > 15: return bool(bits & 8)
        return bool(cœur.getpixel((x, y)))
    for y in range(16):
        for x in range(16):
            if not dedans(x, y): continue
            haut = not dedans(x, y - 1)
            haut2 = not haut and not dedans(x, y - 2)
            bas = not dedans(x, y + 1)
            if haut: d.point((x, y), fill=OMBRE)                 # le rebord nord fait de l'ombre sur l'eau
            elif haut2: d.point((x, y), fill=(14, 72, 66, 255))
            elif bas: d.point((x, y), fill=EAU_CLAIRE)           # reflet contre le rebord sud
    # une tache de ton plus clair, tramée (damier) : donne du volume sans traits répétitifs
    tx, ty = var["ton"]
    for dy in range(3):
        for dx in range(4):
            if (dx + dy) % 2 == 0 and dedans(tx + dx, ty + dy) and dedans(tx + dx, ty + dy - 1) and dedans(tx + dx, ty + dy + 2):
                d.point((tx + dx, ty + dy), fill=EAU_CLAIRE)
    # l'ondelette glisse d'1 pixel entre les 2 images ; l'éclat ne brille que dans l'image 2
    ox, oy = var["pos"]
    ox += (n - 1)
    for (dx, dy) in var["onde"]:
        if dedans(ox + dx, oy + dy) and dedans(ox + dx, oy + dy - 2):
            d.point((ox + dx, oy + dy), fill=RIDE)
    ex, ey = var["eclat"]
    if n == 2 and dedans(ex, ey) and dedans(ex, ey - 2):
        d.point((ex, ey), fill=RIDE_FORTE)
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
