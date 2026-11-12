"""Outil de développement : fabrique en pixels les petites images d'objets (hors planches Gemini).
Usage : python3 Outils/fabriquer_objets.py      -> écrit dans Assets/Gemini/tuiles/
  - plume_doree.png        : la plume du pack Ninja Adventure (Items/Resource/feather.png) recolorée en or
  - cloche_support.png     : support en bois des cloches (2 montants + poutre)
  - cloche_1.png ... _5.png : cloches de bronze, de la plus grosse (note grave) à la plus petite
  - miroir_m.png (/) et miroir_n.png (\\) : miroirs sur socle (plume 5)
  - source_soleil.png : disque solaire incrusté dans le mur (d'où part le rayon)
  - cible.png / cible_allumee.png : réceptacle du rayon (éteint / allumé)
  - fragment_aile.png : l'aile gauche du coq héraldique (Assets/Gemini/embleme/coq_rouge.png), en petit
  - Assets/Gemini/embleme/blason_socle.png : le GRAND BLASON de la cinématique (coq en pierre, empreintes des ailes vides)
  - Assets/Gemini/embleme/blason_aile_gauche.png / _droite.png : chaque aile seule, rouge, sur la même toile que le socle
    (la racine de chaque aile = point de pivot, affiché à la fin du script -> à recopier dans world.gd)"""
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
    """Réceptacle du rayon : un SOLEIL (même motif que source_soleil) posé sur un socle de pierre.
    Éteint = soleil de pierre grise (on comprend qu'il attend la lumière) ; allumé = soleil doré."""
    img = Image.new("RGBA", (16, 16))
    # Socle (colonnes 4-11, lignes 11-15) avec un dessus clair
    for y in range(11, 16):
        for x in range(4, 12):
            bord = x in (4, 11) or y == 15
            img.putpixel((x, y), CONTOUR if bord else ((150, 150, 160, 255) if y == 11 else (100, 100, 112, 255)))
    if allumee:
        coeur, disque, cercle, rayon = (255, 246, 190, 255), (250, 200, 70, 255), (150, 80, 20, 255), (255, 214, 90, 255)
    else:
        coeur, disque, cercle, rayon = (120, 112, 100, 255), (92, 86, 80, 255), (40, 34, 30, 255), (110, 104, 96, 255)
    cx, cy = 7.5, 6.0
    for y in range(0, 12):
        for x in range(16):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d <= 2.0:
                img.putpixel((x, y), coeur)
            elif d <= 3.4:
                img.putpixel((x, y), disque)
            elif d <= 4.4:
                img.putpixel((x, y), cercle)
            elif d <= 6.2 and (abs(x - cx) < 1 or abs(y - cy) < 1 or abs(abs(x - cx) - abs(y - cy)) < 1) and y <= 10:
                img.putpixel((x, y), rayon)
    return img


def fragment():
    """L'aile gauche du coq, réduite à 22 px de large, avec un contour sombre et un liseré doré."""
    coq = Image.open(os.path.join(RACINE, "Assets/Gemini/embleme/coq_rouge.png")).convert("RGBA")
    aile = coq.crop((0, 0, 215, 195))   # sans le corps (x > 215)
    aile = aile.crop(aile.getbbox())
    petite = aile.resize((22, max(8, round(22 * aile.height / aile.width))), Image.LANCZOS)
    h = petite.height
    out = Image.new("RGBA", (24, h + 2))
    masque = [[petite.getpixel((x, y))[3] > 100 for x in range(22)] for y in range(h)]
    plein = lambda x, y: 0 <= x < 22 and 0 <= y < h and masque[y][x]
    for y in range(h + 2):
        for x in range(24):
            px, py = x - 1, y - 1
            if plein(px, py):
                haut_vide = not plein(px, py - 1)
                out.putpixel((x, y), (250, 200, 80, 255) if haut_vide else (196, 28, 44, 255) if (px + py) % 5 else (150, 16, 32, 255))
            elif any(plein(px + dx, py + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                out.putpixel((x, y), (40, 8, 12, 255))
    return out


# --- Village : statue du coq (place du village) et puits ---------------------------------
PIERRE = [(70, 66, 82, 255), (112, 108, 122, 255), (150, 146, 160, 255), (190, 186, 198, 255)]   # ombre -> lumière


def _bloc(img, x0, y0, x1, y1):
    """Pavé de pierre ombré (lumière en haut, ombre en bas et à droite, contour sombre)."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            bord = x in (x0, x1) or y in (y0, y1)
            if bord:
                c = CONTOUR
            elif y == y0 + 1:
                c = PIERRE[3]
            elif y >= y1 - 2 or x == x1 - 1:
                c = PIERRE[0] if y == y1 - 1 else PIERRE[1]
            else:
                c = PIERRE[2] if (x * 3 + y * 5) % 17 else PIERRE[1]
            img.putpixel((x, y), c)


def statue_coq():
    """48x48 : socle de pierre à 2 étages, colonne, et le coq héraldique en bronze rouge au sommet."""
    img = Image.new("RGBA", (48, 48))
    _bloc(img, 3, 36, 44, 47)     # marche du bas
    _bloc(img, 9, 27, 38, 37)     # socle
    for x in range(14, 34, 4):    # petites rainures décoratives sur le socle
        img.putpixel((x, 32), PIERRE[0])
    coq = Image.open(os.path.join(RACINE, "Assets/Gemini/embleme/coq_rouge.png")).convert("RGBA")
    petit = coq.resize((40, round(40 * coq.height / coq.width)), Image.LANCZOS)
    h = petit.height
    plein = lambda x, y: 0 <= x < 40 and 0 <= y < h and petit.getpixel((x, y))[3] > 110
    oy = 27 - h   # le coq est posé sur le socle
    for y in range(-1, h + 1):
        for x in range(-1, 41):
            if plein(x, y):
                c = (236, 92, 70, 255) if not plein(x, y - 1) else (176, 34, 44, 255) if (x + y) % 4 else (132, 20, 34, 255)
            elif any(plein(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                c = (40, 8, 12, 255)
            else:
                continue
            if 0 <= y + oy < 48:
                img.putpixel((x + 4, y + oy), c)
    return img


def puits():
    """32x32 : margelle ronde en pierre, eau sombre, 2 poteaux et un petit toit de bois."""
    img = Image.new("RGBA", (32, 32))
    cx, cy = 15.5, 23.0
    for y in range(32):
        for x in range(32):
            dx, dy = (x - cx) / 13.5, (y - cy) / 8.0
            d = dx * dx + dy * dy
            if d <= 1.0:
                if d > 0.45:   # margelle
                    c = CONTOUR if d > 0.88 else (PIERRE[3] if y < cy - 3 else PIERRE[2] if y < cy + 3 else PIERRE[1])
                else:          # eau
                    c = (24, 52, 92, 255) if (x + y) % 5 else (60, 110, 160, 255)
                img.putpixel((x, y), c)
    BOIS, BOIS_OMBRE = (150, 92, 50, 255), (96, 56, 30, 255)
    for x in (4, 26):          # poteaux
        for y in range(7, 23):
            img.putpixel((x, y), CONTOUR); img.putpixel((x + 1, y), BOIS); img.putpixel((x + 2, y), CONTOUR)
    for y in range(1, 9):      # toit
        for x in range(1 + (8 - y) // 2, 31 - (8 - y) // 2):
            img.putpixel((x, y), CONTOUR if y in (1, 8) or x in (1 + (8 - y) // 2, 30 - (8 - y) // 2) else (BOIS if y % 3 else BOIS_OMBRE))
    for x in range(8, 24):     # treuil et corde
        img.putpixel((x, 11), BOIS_OMBRE)
    for y in range(12, 19):
        img.putpixel((16, y), (200, 180, 140, 255))
    return img


# --- Grand blason de la cinématique -------------------------------------------------------
LARGEUR_BLASON = 240   # px à l'écran (l'écran fait 400x224)
MARGE = 2


def _masques_ailes(alpha):
    """Sépare les deux ailes du reste du coq (remplissage depuis un point de chaque aile)."""
    from PIL import ImageDraw
    m = alpha.point(lambda v: 255 if v > 100 else 0)
    ImageDraw.floodfill(m, (100, 80), 100)    # aile gauche
    ImageDraw.floodfill(m, (508, 80), 50)     # aile droite
    gauche = m.point(lambda v: 255 if v == 100 else 0)
    droite = m.point(lambda v: 255 if v == 50 else 0)
    tout = alpha.point(lambda v: 255 if v > 100 else 0)
    return tout, gauche, droite


def _reduire(masque, w, h):
    return masque.resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)


def _peindre(masque, interieur, haut, contour, w, h, motif=None):
    """Remplit `masque` (0/255) : `haut` sur le bord supérieur, `contour` tout autour (1 px), `interieur` dedans."""
    out = Image.new("RGBA", (w + 2 * MARGE, h + 2 * MARGE))
    plein = lambda x, y: 0 <= x < w and 0 <= y < h and masque.getpixel((x, y)) > 0
    for y in range(-MARGE, h + MARGE):
        for x in range(-MARGE, w + MARGE):
            if plein(x, y):
                if not plein(x, y - 1):
                    c = haut
                elif motif and motif(x, y):
                    c = motif(x, y)
                else:
                    c = interieur
            elif any(plein(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                c = contour
            else:
                continue
            out.putpixel((x + MARGE, y + MARGE), c)
    return out


def blason():
    coq = Image.open(os.path.join(RACINE, "Assets/Gemini/embleme/coq_rouge.png")).convert("RGBA")
    tout, gauche, droite = _masques_ailes(coq.getchannel("A"))
    w = LARGEUR_BLASON
    h = round(w * coq.height / coq.width)
    tout, gauche, droite = (_reduire(m, w, h) for m in (tout, gauche, droite))
    corps = Image.new("L", (w, h))
    corps.paste(tout, (0, 0))
    corps.paste(0, (0, 0), gauche)
    corps.paste(0, (0, 0), droite)
    # Socle : le coq en pierre grise (petites taches), les ailes = empreintes sombres cerclées d'or terne
    pierre = lambda x, y: (92, 88, 104, 255) if (x * 7 + y * 13) % 23 == 0 else None
    socle = _peindre(corps, (122, 118, 134, 255), (170, 166, 180, 255), (26, 22, 34, 255), w, h, pierre)
    for aile in (gauche, droite):
        empreinte = _peindre(aile, (30, 26, 42, 255), (20, 16, 30, 255), (150, 118, 60, 255), w, h)
        socle.alpha_composite(empreinte)
    # Ailes rouges, liseré doré en haut, plumes légèrement ombrées
    plume = lambda x, y: (150, 16, 32, 255) if (x + y) % 6 == 0 else None
    pivots = {}
    for nom, aile in (("gauche", gauche), ("droite", droite)):
        img = _peindre(aile, (196, 28, 44, 255), (250, 200, 80, 255), (40, 8, 12, 255), w, h, plume)
        img.save(os.path.join(RACINE, "Assets/Gemini/embleme/blason_aile_%s.png" % nom))
        # Racine de l'aile = pixels les plus proches du corps (8 colonnes du côté du corps)
        xs = [x for x in range(w) for y in range(h) if aile.getpixel((x, y))]
        bord = max(xs) - 8 if nom == "gauche" else min(xs) + 8
        pts = [(x, y) for x in range(w) for y in range(h) if aile.getpixel((x, y)) and (x >= bord if nom == "gauche" else x <= bord)]
        pivots[nom] = (round(sum(p[0] for p in pts) / len(pts)) + MARGE, round(sum(p[1] for p in pts) / len(pts)) + MARGE)
    socle.save(os.path.join(RACINE, "Assets/Gemini/embleme/blason_socle.png"))
    print("blason", socle.size, "pivots (dans l'image) :", pivots)


if __name__ == "__main__":
    statue_coq().save(os.path.join(SORTIE, "statue_coq.png"))
    puits().save(os.path.join(SORTIE, "puits.png"))
    blason()
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
