"""Fabrique les touffes d'HERBE HAUTE coupables (Assets/Gemini/tuiles/v_herbe_haute_1..3.png, 16x16).
Vert franc du village, brins pointus avec lumière / ombre, 3 variantes pour que le champ ne se répète pas.
À lancer APRÈS traiter_village_jadson.py (qui écrit le sol d'herbe)."""
import random
from PIL import Image, ImageDraw

SORTIE = "Assets/Gemini/tuiles/"
CLAIR, MOYEN, FONCE, CONTOUR = (150, 214, 70), (96, 168, 52), (58, 118, 42), (34, 78, 36)


def touffe(graine):
    rnd = random.Random(graine)
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 11, 13, 15), fill=(0, 0, 0, 55))                   # ombre au sol
    brins = []
    for i in range(7):
        x = 2 + i * 2 + rnd.randint(-1, 1)
        haut = rnd.randint(6, 11)
        brins.append((x, haut))
    for x, haut in sorted(brins, key=lambda b: b[1]):
        pointe = x + rnd.choice([-1, 0, 1])
        for y in range(14, 14 - haut, -1):
            t = (14 - y) / haut
            px = round(x + (pointe - x) * t * t)
            col = FONCE if t < 0.25 else (MOYEN if t < 0.7 else CLAIR)
            d.point((px, y), fill=col)
            d.point((px + 1, y), fill=col if t < 0.7 else MOYEN)
        d.point((pointe, 14 - haut), fill=CLAIR)
    # contour sombre discret sur le dessous
    px = im.load()
    for y in range(16):
        for x in range(16):
            if px[x, y][3] == 0 and any(0 <= x + dx < 16 and 0 <= y + dy < 16 and px[x + dx, y + dy][3] == 255
                                         for dx, dy in ((1, 0), (-1, 0), (0, 1))):
                px[x, y] = CONTOUR + (255,)
    return im


for n in (1, 2, 3):
    touffe(n * 17).save(f"{SORTIE}v_herbe_haute_{n}.png")
print("3 touffes écrites")
