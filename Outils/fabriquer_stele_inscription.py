# Fabrique la petite stèle de pierre à INSCRIPTION (lettre I des salles du donjon) :
# une tablette de pierre arrondie en haut, sur un socle, avec des lignes gravées dorées (le texte se lit en marchant devant).
# -> Assets/Gemini/tuiles/stele_inscription.png (16x24). Lancer : python3 Outils/fabriquer_stele_inscription.py
from PIL import Image
import os

ICI = os.path.dirname(os.path.abspath(__file__))
SORTIE = os.path.join(ICI, "..", "Assets", "Gemini", "tuiles", "stele_inscription.png")

CONTOUR = (28, 30, 42, 255)
SOMBRE = (78, 86, 104, 255)
PIERRE = (112, 122, 140, 255)
CLAIR = (150, 160, 178, 255)
OR = (232, 190, 92, 255)
OR_SOMBRE = (150, 108, 46, 255)

im = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
p = im.load()
# Tablette : x 2..13, y 1..18, haut arrondi
for y in range(1, 19):
    for x in range(2, 14):
        if y < 4 and (x - 7.5) ** 2 / 36 + (y - 4) ** 2 / 9 > 1:
            continue
        p[x, y] = PIERRE
# Ombrage : clair à gauche/haut, sombre à droite
for y in range(1, 19):
    xs = [x for x in range(16) if p[x, y][3]]
    if not xs:
        continue
    p[xs[0], y] = CLAIR
    p[xs[-1], y] = SOMBRE
    if len(xs) > 2:
        p[xs[-2], y] = SOMBRE if y > 3 else PIERRE
# Contour
masque = [[p[x, y][3] > 0 for x in range(16)] for y in range(24)]
for y in range(24):
    for x in range(16):
        if not masque[y][x]:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if 0 <= x + dx < 16 and 0 <= y + dy < 24 and masque[y + dy][x + dx]:
                    p[x, y] = CONTOUR
                    break
# Petit soleil gravé en haut (le thème de l'énigme)
for x, y in ((7, 4), (8, 4), (7, 5), (8, 5)):
    p[x, y] = OR
for x, y in ((7, 3), (8, 3), (6, 4), (9, 4), (6, 5), (9, 5), (7, 6), (8, 6)):
    p[x, y] = OR_SOMBRE
# Lignes de « texte » gravées (tirets dorés irréguliers)
lignes = [(8, [4, 5, 6, 8, 9, 11]), (10, [4, 5, 7, 8, 9, 10, 11]), (12, [4, 6, 7, 8, 10, 11]), (14, [4, 5, 6, 7, 9, 10])]
for y, xs in lignes:
    for x in xs:
        p[x, y] = OR
        p[x, y + 1] = OR_SOMBRE if (x + y) % 3 else SOMBRE
# Socle
for y in range(19, 23):
    for x in range(1, 15):
        p[x, y] = CLAIR if y == 19 else (SOMBRE if y == 22 else PIERRE)
    p[1, y] = CONTOUR
    p[14, y] = CONTOUR
for x in range(1, 15):
    p[x, 23] = CONTOUR
im.save(SORTIE)
print("écrit", SORTIE)
