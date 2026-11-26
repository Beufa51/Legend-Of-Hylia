"""Recolore l'armure GRISE du garde (heros_lpc.png) en bronze doré, comme dans l'intro.

Lancer : python3 Outils/recolorer_armure.py [entree] [sortie]
(par défaut : Assets/Heros/heros_lpc.png écrit sur lui-même ; garder une copie avant.)

Règle : seuls les pixels presque NEUTRES/BLEUTÉS et de luminosité moyenne sont repeints
(armure, casque). Les contours sombres, la peau, le bois de la lance, le cimier rouge
et les bottes restent tels quels. La luminosité de chaque pixel est conservée
(le relief reste identique), seule la teinte change.
"""
import sys
from PIL import Image

ENTREE = sys.argv[1] if len(sys.argv) > 1 else "Assets/Heros/heros_lpc.png"
SORTIE = sys.argv[2] if len(sys.argv) > 2 else ENTREE

# Teinte cible (bronze doré) à luminosité 255 ; la luminosité du pixel la fait varier.
TEINTE = (255, 222, 150)
# Pixels « gris » : écart max-min faible (peu de saturation) et luminosité moyenne.
ECART_MAX = 26
LUM_MIN, LUM_MAX = 60, 215


def repeindre(r, g, b):
    lum = (r * 299 + g * 587 + b * 114) / 1000
    k = min(1.0, lum / 255.0 * 1.15)
    return (min(255, int(TEINTE[0] * k)),
            min(255, int(TEINTE[1] * k)),
            min(255, int(TEINTE[2] * k)))


im = Image.open(ENTREE).convert("RGBA")
pixels = im.load()
w, h = im.size
nb = 0
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        ecart = max(r, g, b) - min(r, g, b)
        lum = (r * 299 + g * 587 + b * 114) / 1000
        # Teinte presque neutre ou bleutée (pas la peau chaude, pas le rouge du cimier).
        if ecart <= ECART_MAX and r <= b + 12 and LUM_MIN <= lum <= LUM_MAX + 40:
            pixels[x, y] = repeindre(r, g, b) + (a,)
            nb += 1
im.save(SORTIE)
print(f"{nb} pixels repeints -> {SORTIE}")
