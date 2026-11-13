"""Outil de développement : redessine les STATUES du donjon, plus détaillées (20x34 : chevalier en armure avec épée et écu, coq de pierre) sur un piédestal biseauté.
Écrit statue_chevalier.png et statue_oiseau.png dans Assets/Gemini/tuiles/. Le coq reprend la forme du coq de la girouette (même emblème). À lancer APRÈS fabriquer_objets.py.
Posées bas-centre sur leur case : room.gd (S, O), chanteur.gd (C) et apercu_salle.py savent que l'image fait 20x34 (décalage x -2, y -18)."""
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import fabriquer_objets as fo

SORTIE = fo.SORTIE
O = (28, 28, 42, 255)                    # contour
D, M, L, H = (72, 74, 96, 255), (112, 114, 138, 255), (156, 158, 182, 255), (206, 208, 226, 255)
MOUSSE = (86, 120, 88, 255)


def eclairer(forme):
    """Ombrage depuis le haut-gauche + contour : arête haute et gauche claires, bas et droite sombres, contour sombre autour."""
    W, H_ = forme.size
    a = lambda x, y: 0 <= x < W and 0 <= y < H_ and forme.getpixel((x, y))[3] > 0
    sortie = Image.new("RGBA", (W + 2, H_ + 2))
    for y in range(-1, H_ + 1):
        for x in range(-1, W + 1):
            if a(x, y):
                c = forme.getpixel((x, y))
                if c[:3] == M[:3]:
                    if not a(x, y - 1) or not a(x - 1, y): c = L
                    elif not a(x, y + 1) or not a(x + 1, y): c = D
                    elif not a(x - 1, y - 1): c = H
                sortie.putpixel((x + 1, y + 1), c)
            elif any(a(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                sortie.putpixel((x + 1, y + 1), O)
    return sortie


def piedestal(d, w=18, x0=1, y0=25, h=8):
    d.rectangle((x0, y0, x0 + w - 1, y0 + h - 1), fill=M)
    d.rectangle((x0 + 1, y0 + 2, x0 + w - 2, y0 + h - 2), fill=D)           # panneau enfoncé
    d.line((x0 + 3, y0 + 4, x0 + w - 4, y0 + 4), fill=M)                    # gravure


def chevalier():
    f = Image.new("RGBA", (20, 32))
    d = ImageDraw.Draw(f)
    piedestal(d)
    d.rectangle((6, 21, 9, 25), fill=M); d.rectangle((11, 21, 14, 25), fill=M)          # jambes (grèves)
    d.polygon([(5, 13), (15, 13), (14, 22), (6, 22)], fill=M)                            # cuirasse
    d.line((10, 14, 10, 21), fill=D)                                                     # arête du plastron
    d.rectangle((6, 20, 14, 21), fill=D)                                                 # ceinture
    d.ellipse((2, 11, 7, 17), fill=M); d.ellipse((13, 11, 18, 17), fill=M)               # épaulières
    d.rectangle((3, 16, 5, 22), fill=M)                                                  # bras gauche
    d.rectangle((14, 16, 16, 21), fill=M)                                                # bras droit
    d.rectangle((16, 6, 17, 24), fill=L)                                                 # lame de l'épée (pointe en haut)
    d.rectangle((14, 21, 19, 22), fill=D)                                                # garde
    d.polygon([(1, 17), (7, 17), (7, 24), (4, 26), (1, 24)], fill=D)                     # écu
    d.line((4, 18, 4, 24), fill=L); d.line((2, 20, 6, 20), fill=L)                       # croix sur l'écu
    d.ellipse((6, 3, 14, 12), fill=M)                                                    # heaume
    d.rectangle((7, 7, 13, 8), fill=D)                                                   # visière
    d.line((10, 8, 10, 11), fill=D)
    d.polygon([(9, 0), (11, 0), (12, 4), (8, 4)], fill=L)                                # cimier
    return eclairer(f)


def oiseau():
    """Un coq de pierre dessiné à la main (crête, bec, barbillon, queue en panache, aile), posé sur un piédestal."""
    f = Image.new("RGBA", (20, 32))
    d = ImageDraw.Draw(f)
    piedestal(d)
    d.rectangle((6, 22, 14, 24), fill=D)                                              # socle sous les pattes
    d.polygon([(4, 16), (0, 9), (1, 4), (4, 7), (7, 13)], fill=M)                      # queue : plume arrière
    d.polygon([(5, 16), (3, 9), (5, 5), (8, 8), (9, 14)], fill=M)                      # plume avant
    d.ellipse((4, 11, 15, 22), fill=M)                                                 # corps
    d.ellipse((11, 7, 17, 14), fill=M)                                                 # poitrail et cou
    d.ellipse((12, 3, 18, 9), fill=M)                                                  # tête
    for cx in (12, 14, 16):
        d.ellipse((cx, 0, cx + 2, 3), fill=M)                                          # crête
    d.polygon([(18, 5), (21, 6), (18, 8)], fill=L)                                     # bec
    d.ellipse((17, 8, 19, 11), fill=D)                                                 # barbillon
    img = eclairer(f)
    ep = ImageDraw.Draw(img)
    ep.point((16, 6), fill=O); ep.point((17, 6), fill=H)                              # œil
    ep.arc((6, 13, 14, 21), 200, 340, fill=D); ep.arc((7, 15, 15, 22), 200, 340, fill=D)   # plumes de l'aile
    ep.line((8, 22, 8, 25), fill=D); ep.line((12, 22, 12, 25), fill=D)                 # pattes
    return img


if __name__ == "__main__":
    chevalier().save(os.path.join(SORTIE, "statue_chevalier.png"))
    oiseau().save(os.path.join(SORTIE, "statue_oiseau.png"))
    print("statues redessinées")
