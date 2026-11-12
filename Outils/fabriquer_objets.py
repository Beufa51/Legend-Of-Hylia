"""Outil de développement : fabrique en pixels les petites images d'objets (hors planches Gemini).
Usage : python3 Outils/fabriquer_objets.py      -> écrit dans Assets/Gemini/tuiles/
  - plume_doree.png        : la plume du pack Ninja Adventure (Items/Resource/feather.png) recolorée en or
  - cloche_support.png     : support en bois des cloches (2 montants + poutre)
  - cloche_1.png ... _5.png : cloches de bronze, de la plus grosse (note grave) à la plus petite"""
import os
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
CONTOUR = (34, 20, 14, 255)


def plume_doree():
    src = Image.open(os.path.join(RACINE, "Assets/Ninja_adventure/Items/Resource/feather.png")).convert("RGBA")
    # Rampe dorée, de l'ombre au reflet
    rampe = [(92, 48, 12), (168, 98, 18), (222, 160, 34), (250, 208, 78), (255, 244, 186)]
    out = Image.new("RGBA", src.size)
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src.getpixel((x, y))
            if a == 0:
                continue
            lum = (r * 3 + g * 6 + b) / 10
            if lum < 60:   # contour : brun très foncé (plus chaud que le noir)
                out.putpixel((x, y), (54, 26, 8, a))
                continue
            i = min(len(rampe) - 1, int((lum - 60) / 196 * len(rampe)))
            out.putpixel((x, y), rampe[i] + (a,))
    out.save(os.path.join(SORTIE, "plume_doree.png"))


def support():
    img = Image.new("RGBA", (16, 16))
    bois, bois_clair, bois_fonce = (110, 68, 34, 255), (150, 98, 52, 255), (70, 42, 22, 255)
    for x0 in (1, 13):   # montants
        for y in range(3, 16):
            img.putpixel((x0, y), bois_clair)
            img.putpixel((x0 + 1, y), bois_fonce)
    for x in range(0, 16):   # poutre
        img.putpixel((x, 1), bois_clair)
        img.putpixel((x, 2), bois)
        img.putpixel((x, 3), bois_fonce)
    for x in (0, 15):
        for y in (1, 2, 3):
            img.putpixel((x, y), CONTOUR)
    img.putpixel((7, 4), (60, 60, 64, 255))   # crochet
    img.putpixel((8, 4), (90, 90, 96, 255))
    return img


def cloche(largeur):
    """Cloche de `largeur` pixels (rebord compris), dessinée dans une image 16x13. Le haut (y=0) est le point d'attache."""
    img = Image.new("RGBA", (16, 13))
    h = largeur  # hauteur à peu près égale à la largeur
    cx = 7.5
    bronze = [(88, 52, 18), (140, 88, 30), (190, 128, 46), (226, 172, 78), (250, 222, 150)]
    profil = []
    for y in range(h):
        t = y / (h - 1)
        # dôme étroit en haut, flancs qui s'évasent, rebord large en bas
        base = largeur / 2 - 1.5
        if y == 0:
            demi = base * 0.35          # sommet arrondi
        elif y == 1:
            demi = base * 0.6
        else:
            demi = base * (0.68 + 0.32 * t * t) + (1.5 if y >= h - 2 else 0)   # flancs qui s'évasent + rebord
        profil.append(demi)
    for y, demi in enumerate(profil):
        x0, x1 = round(cx - demi), round(cx + demi)
        for x in range(x0, x1 + 1):
            if x in (x0, x1) or y == 0 or y == h - 1:
                c = CONTOUR
            else:
                u = (x - x0) / max(1, x1 - x0)   # 0 = gauche (éclairé) -> 1 = droite (ombre)
                i = 3 if u < 0.25 else 2 if u < 0.55 else 1 if u < 0.85 else 0
                if y == h - 2:
                    i = max(0, i - 1)   # rebord un peu plus sombre
                c = bronze[i] + (255,)
            img.putpixel((x, y), c)
    # reflet vertical
    for y in range(2, h - 3):
        img.putpixel((round(cx - profil[y]) + 2, y), bronze[4] + (255,))
    # battant
    img.putpixel((7, h), CONTOUR); img.putpixel((8, h), CONTOUR)
    img.putpixel((7, h - 1), (60, 40, 20, 255)); img.putpixel((8, h - 1), (60, 40, 20, 255))
    return img


if __name__ == "__main__":
    plume_doree()
    support().save(os.path.join(SORTIE, "cloche_support.png"))
    for note, largeur in enumerate([12, 11, 10, 9, 8], start=1):
        cloche(largeur).save(os.path.join(SORTIE, "cloche_%d.png" % note))
    print("objets écrits dans", SORTIE)
