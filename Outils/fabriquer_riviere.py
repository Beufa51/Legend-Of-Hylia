"""Outil de développement : fabrique les images de la RIVIÈRE et du PONT du village (écran Rivière).
Usage : python3 Outils/fabriquer_riviere.py   (à lancer avant generer_village.py ; écrit dans Assets/Gemini/tuiles/)
La rivière est un AUTOTILE comme le chemin de terre : chaque case d'eau choisit son image selon ses 4 voisins (la rive s'arrondit toute seule) :
  v_eau_<bits>_<1|2>   bits = voisins d'eau (1 nord, 2 sud, 4 ouest, 8 est) ; les côtés SANS eau montrent la rive (herbe, bord sombre, écume)
  v_eau_f<coins>_<1|2> case entourée d'eau avec des coins de terre (1 NE, 2 NO, 4 SE, 8 SO)
  v_pont_g/m/d         pont de bois (planches en travers, rambarde à gauche / sans / à droite)
Les 2 images (_1, _2) alternent : l'eau scintille. Couleurs : eau du pack Pixel Crawler, assombrie pour aller avec l'herbe.
"""
import os

from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
SORTIE = os.path.join(RACINE, "Assets/Gemini/tuiles/")

EAU = (44, 118, 180)
EAU_CLAIRE = (88, 164, 214)
EAU_PROFONDE = (32, 92, 156)
ECUME = (206, 232, 244)
BORD = (24, 52, 84)                 # liseré sombre entre l'eau et la terre
HERBE = (51, 118, 3)                # même herbe que le sol du village (traiter_pixel_crawler.py)
HERBE_FONCEE = (38, 98, 4)
BOUE = (92, 66, 36)                 # petite bande de terre mouillée au bord


def bruit(x, y, graine):
    v = (x * 374761393 + y * 668265263 + graine * 2147483647) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return (v & 0xFFFF) / 65535.0


def tuile_eau(n, s, o, e, diag, frame):
    """Une case d'eau. n, s, o, e = le voisin est de l'eau ? ; diag = coins de terre (tuile entourée d'eau)."""
    im = Image.new("RGBA", (16, 16), HERBE + (255,))
    px = im.load()
    for y in range(16):
        for x in range(16):
            marge = 3.0
            d = 99.0     # distance à la terre la plus proche (négatif = sur la terre)
            if not n: d = min(d, y - marge + (bruit(x, y, 21) - 0.5) * 2.4)
            if not s: d = min(d, 15 - y - marge + (bruit(x, y, 22) - 0.5) * 2.4)
            if not o: d = min(d, x - marge + (bruit(x, y, 23) - 0.5) * 2.4)
            if not e: d = min(d, 15 - x - marge + (bruit(x, y, 24) - 0.5) * 2.4)
            for cond, cx, cy in [(not n and not o, 0, 0), (not n and not e, 15, 0), (not s and not o, 0, 15), (not s and not e, 15, 15)]:
                if cond:
                    r = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                    d = min(d, r - 5.0 + (bruit(x, y, 25) - 0.5) * 1.8)
            if n and s and o and e:
                for bit, cx, cy in [(1, 15, 0), (2, 0, 0), (4, 15, 15), (8, 0, 15)]:
                    if diag & bit:
                        r = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                        d = min(d, r - 4.0 + (bruit(x, y, 26) - 0.5) * 1.8)
            if d >= 0:
                if d < 1.0:   c = BORD
                elif d < 2.2: c = ECUME if bruit(x, y, 27) > 0.18 else EAU_CLAIRE
                else:
                    c = EAU
                    if d > 5.0 and bruit(x, y, 28) < 0.25: c = EAU_PROFONDE      # l'eau est plus profonde au milieu
                    # petits reflets qui se déplacent d'une image à l'autre
                    if ((x + 2 * y + frame * 5) % 13 == 0 and bruit(x, y, 29) > 0.6) or ((x * 3 + y + frame * 7) % 19 == 0 and bruit(x, y, 30) > 0.6):
                        c = EAU_CLAIRE
                px[x, y] = c + (255,)
            elif d > -1.6:
                px[x, y] = BOUE + (255,)            # terre mouillée
            elif d > -2.6:
                px[x, y] = HERBE_FONCEE + (255,)    # herbe sombre au bord
    return im


def pont(cote):
    """Pont de bois : planches en travers (on le traverse du nord au sud), rambarde du côté de l'eau."""
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    claire, foncee, joint = (176, 124, 66, 255), (150, 100, 52, 255), (70, 44, 22, 255)
    for y in range(0, 16, 4):
        d.rectangle((0, y, 15, y + 2), fill=claire if (y // 4) % 2 == 0 else foncee)
        d.line((0, y + 3, 15, y + 3), fill=joint)
        d.point((2 + (y // 4) * 3 % 5, y + 1), fill=joint)    # clous
        d.point((13 - (y // 4) * 2 % 4, y + 1), fill=joint)
    if cote in ("g", "d"):
        x0 = 0 if cote == "g" else 12
        d.rectangle((x0, 0, x0 + 3, 15), fill=(104, 68, 34, 255))
        d.line((x0 + (1 if cote == "g" else 2), 0, x0 + (1 if cote == "g" else 2), 15), fill=(196, 148, 86, 255))    # lisse éclairée
        for y in (0, 7, 14):                                                                                         # poteaux
            d.rectangle((x0, y, x0 + 3, min(15, y + 1)), fill=(60, 38, 18, 255))
        # ombre portée du pont sur l'eau (bord extérieur)
        ox = 4 if cote == "d" else -1
    return t


def main():
    for frame in (0, 1):
        for bits in range(15):
            n, s, o, e = bool(bits & 1), bool(bits & 2), bool(bits & 4), bool(bits & 8)
            tuile_eau(n, s, o, e, 0, frame).save(SORTIE + "v_eau_%d_%d.png" % (bits, frame + 1))
        for diag in range(16):
            tuile_eau(True, True, True, True, diag, frame).save(SORTIE + "v_eau_f%d_%d.png" % (diag, frame + 1))
    for c in "gmd":
        pont(c).save(SORTIE + "v_pont_%s.png" % c)
    # anciennes images de la rivière (remplacées)
    for ancien in ("v_eau_h_1", "v_eau_h_2", "v_eau_b_1", "v_eau_b_2", "v_eau_1", "v_eau_2"):
        f = SORTIE + ancien + ".png"
        if os.path.exists(f): os.remove(f)
    print("rivière (autotile) et pont écrits dans", SORTIE)


if __name__ == "__main__":
    main()
