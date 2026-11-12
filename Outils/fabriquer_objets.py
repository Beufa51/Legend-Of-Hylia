"""Outil de développement : fabrique en pixels les petites images d'objets (hors planches Gemini).
Usage : python3 Outils/fabriquer_objets.py      -> écrit dans Assets/Gemini/tuiles/
  - plume_doree.png        : la plume du pack Ninja Adventure (Items/Resource/feather.png) recolorée en or
  - cloche_support.png     : support en bois des cloches (2 montants + poutre)
  - cloche_1.png ... _5.png : cloches de bronze, de la plus grosse (note grave) à la plus petite
  - miroir_m.png (/) et miroir_n.png (\\) : miroirs sur socle (plume 5)
  - source_soleil.png : disque solaire incrusté dans le mur (d'où part le rayon)
  - cible.png / cible_allumee.png : réceptacle du rayon (éteint / allumé)
  - fragment_aile.png : l'aile gauche du coq héraldique (Assets/Gemini/embleme/coq_rouge.png), en petit"""
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


def miroir(sens):
    """Miroir sur un socle rond. sens = 1 pour '/', -1 pour '\\'."""
    img = Image.new("RGBA", (16, 16))
    pierre = [(70, 72, 80, 255), (104, 106, 116, 255), (138, 140, 150, 255)]
    for y in range(11, 16):   # socle (ellipse aplatie)
        for x in range(2, 14):
            if ((x - 7.5) / 6) ** 2 + ((y - 13) / 2.6) ** 2 <= 1:
                bord = ((x - 7.5) / 6) ** 2 + ((y - 13) / 2.6) ** 2 > 0.6
                img.putpixel((x, y), CONTOUR if bord and y >= 14 else pierre[2 if y < 13 else 1])
    argent = [(110, 130, 165, 255), (180, 200, 230, 255), (240, 248, 255, 255)]
    cadre = (200, 150, 50, 255)
    for i in range(0, 11):   # plaque diagonale épaisse (cadre doré, verre argenté avec reflets)
        x = 3 + i if sens == 1 else 12 - i
        y = 12 - i
        bout = i in (0, 10)
        couches = [CONTOUR, cadre] + ([cadre] * 3 if bout else [argent[2] if i % 3 == 1 else argent[1], argent[1], argent[0]]) + [cadre, CONTOUR]
        for k, c in enumerate(couches):
            xx = x + (k - 3) if sens == 1 else x - (k - 3)
            if 0 <= xx < 16:
                img.putpixel((xx, y), c)
    return img


def soleil():
    img = Image.new("RGBA", (16, 16))
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if d <= 4.2:
                img.putpixel((x, y), (255, 236, 140, 255) if d < 2.5 else (250, 190, 60, 255))
            elif d <= 5.2:
                img.putpixel((x, y), (150, 80, 20, 255))
            elif d <= 7.4 and (abs(x - 7.5) < 1 or abs(y - 7.5) < 1 or abs(abs(x - 7.5) - abs(y - 7.5)) < 1):
                img.putpixel((x, y), (250, 200, 70, 255))   # rayons
    return img


def cible(allumee):
    img = Image.new("RGBA", (16, 16))
    pierre = (96, 98, 108, 255) if not allumee else (130, 120, 96, 255)
    for y in range(3, 16):
        for x in range(2, 14):
            img.putpixel((x, y), CONTOUR if x in (2, 13) or y in (3, 15) else pierre)
    coeur = (255, 230, 120, 255) if allumee else (70, 56, 40, 255)
    anneau = (240, 170, 50, 255) if allumee else (120, 100, 70, 255)
    for y in range(4, 15):
        for x in range(3, 13):
            d = ((x - 7.5) ** 2 + (y - 9) ** 2) ** 0.5
            if d <= 2.2:
                img.putpixel((x, y), coeur)
            elif d <= 3.6:
                img.putpixel((x, y), anneau)
    return img


def fragment():
    """L'aile gauche du coq, réduite à 22 px de large, avec un contour sombre et un liseré doré."""
    coq = Image.open(os.path.join(RACINE, "Assets/Gemini/embleme/coq_rouge.png")).convert("RGBA")
    aile = coq.crop((0, 0, 250, 215))
    petite = aile.resize((22, 19), Image.LANCZOS)
    out = Image.new("RGBA", (24, 21))
    masque = [[petite.getpixel((x, y))[3] > 100 for x in range(22)] for y in range(19)]
    plein = lambda x, y: 0 <= x < 22 and 0 <= y < 19 and masque[y][x]
    for y in range(21):
        for x in range(24):
            px, py = x - 1, y - 1
            if plein(px, py):
                haut_vide = not plein(px, py - 1)
                out.putpixel((x, y), (250, 200, 80, 255) if haut_vide else (196, 28, 44, 255) if (px + py) % 5 else (150, 16, 32, 255))
            elif any(plein(px + dx, py + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                out.putpixel((x, y), (40, 8, 12, 255))
    return out


if __name__ == "__main__":
    miroir(1).save(os.path.join(SORTIE, "miroir_m.png"))
    miroir(-1).save(os.path.join(SORTIE, "miroir_n.png"))
    soleil().save(os.path.join(SORTIE, "source_soleil.png"))
    cible(False).save(os.path.join(SORTIE, "cible.png"))
    cible(True).save(os.path.join(SORTIE, "cible_allumee.png"))
    fragment().save(os.path.join(SORTIE, "fragment_aile.png"))
    plume_doree()
    support().save(os.path.join(SORTIE, "cloche_support.png"))
    for note, largeur in enumerate([12, 11, 10, 9, 8], start=1):
        cloche(largeur).save(os.path.join(SORTIE, "cloche_%d.png" % note))
    print("objets écrits dans", SORTIE)
