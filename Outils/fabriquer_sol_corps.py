#!/usr/bin/env python3
"""Sols du DONJON FINAL (queue et cour du coq) : terre battue (couloirs de la queue) et herbe (cour de l'arène),
comme sur l'image Coq_forteresse.jpg. Écrit dans Assets/Gemini/tuiles/ : sol_terre(_b/_c), sol_herbe(_b/_c). 16x16.
Lettres des plans (room.gd::_nom_sol) : `,` terre, `;` herbe. À lancer AVANT generer_corps.py."""
import os
import numpy as np
from PIL import Image

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
rng = np.random.default_rng(7)


def tuile(base, ecart, cailloux=0, touffes=0, clair=(1.0, 1.0, 1.0)):
    a = np.zeros((16, 16, 3), float) + np.array(base, float)
    a += rng.normal(0, ecart, (16, 16, 1))
    for _ in range(cailloux):                      # petits cailloux / brins sombres
        x, y = rng.integers(1, 15, 2)
        a[y, x] *= 0.62
        a[y, x + 1 if x < 15 else x] *= 0.82
    for _ in range(touffes):                       # brins clairs
        x, y = rng.integers(1, 15, 2)
        a[y, x] = np.minimum(255, a[y, x] * 1.35 * np.array(clair))
        a[y - 1, x] = np.minimum(255, a[y - 1, x] * 1.2 * np.array(clair))
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).convert("RGBA")


for nom, base, e, c, t in [
    ("sol_terre", (112, 84, 60), 5, 0, 0), ("sol_terre_b", (108, 81, 58), 5, 3, 0), ("sol_terre_c", (116, 87, 62), 6, 1, 1),
    ("sol_herbe", (52, 86, 44), 6, 0, 2), ("sol_herbe_b", (46, 78, 40), 7, 0, 5), ("sol_herbe_c", (58, 92, 48), 6, 2, 3),
]:
    tuile(base, e, c, t).save(os.path.join(SORTIE, nom + ".png"))
print("sols du corps écrits")
