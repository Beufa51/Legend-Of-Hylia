#!/usr/bin/env python3
"""CIEL ÉTOILÉ et CRÉNEAUX de l'arène du donjon final (Room.ciel_etoile). Écrit dans Assets/Gemini/tuiles/ :
  ciel_nuit_a/b/c.png  tuiles 16x16 de ciel du soir (bleu nuit, quelques étoiles) ;
  mur_creneaux.png     tuile de mur du haut dont les 8 px du haut alternent merlon / vide (le vide laisse voir le ciel).
À lancer APRÈS traiter_pack_donjon.py (il lit mur_face_haut.png), AVANT generer_corps.py."""
import os
import numpy as np
from PIL import Image

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
rng = np.random.default_rng(21)


def ciel(nb_etoiles, grosse):
    a = np.zeros((16, 16, 3), float) + np.array((11, 16, 42), float)
    a += rng.normal(0, 2.2, (16, 16, 1))
    for _ in range(nb_etoiles):
        x, y = rng.integers(1, 15, 2)
        a[y, x] = (200, 210, 255)
    if grosse:
        x, y = rng.integers(3, 13, 2)
        a[y, x] = (255, 255, 255)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a[y + dy, x + dx] = (120, 135, 200)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")


for nom, n, g in (("ciel_nuit_a", 1, False), ("ciel_nuit_b", 2, False), ("ciel_nuit_c", 1, True)):
    ciel(n, g).save(os.path.join(SORTIE, nom + ".png"))

mur = Image.open(os.path.join(SORTIE, "mur_face_haut.png")).convert("RGBA")
px = mur.load()
for y in range(8):                 # le haut : un merlon (8 px) puis un vide (8 px)
    for x in range(16):
        if x >= 8:
            px[x, y] = (0, 0, 0, 0)
        elif y < 2:                # dessus du merlon éclairé
            r, g, b, a = px[x, y]
            px[x, y] = (min(255, r + 38), min(255, g + 38), min(255, b + 44), a)
mur.save(os.path.join(SORTIE, "mur_creneaux.png"))
print("ciel étoilé et créneaux écrits")
