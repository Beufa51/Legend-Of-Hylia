#!/usr/bin/env python3
"""FAÇADE DE LA QUEUE vue du village = un morceau de la MÊME image que la cinématique (Coq_sans_ailes / Coq_forteresse_bec), pas une autre peinture :
le donjon rond, l'éventail des 5 couloirs, l'arc de tours à flammes et la porte, avec leurs vraies formes (rien de droit).
Les GRIFFES sont retirées de ce morceau : ce sont les stèles du Parvis (écran au sud), elles y sont déjà.
À lancer APRÈS traiter_coq_cinematique.py ET traiter_facades.py (il écrase v_facade_queue.png), AVANT generer_village.py.
Cadrage : image 1408x768 -> morceau (454, 480)-(954, 720) réduit à 400x192 (échelle 0,8) ; la porte tombe en rangée 11, colonnes 11-13."""
import os
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
CIN = os.path.join(RACINE, "Assets", "Cinematique")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles", "v_facade_queue.png")
POLY_G = [(0, 84), (141, 84), (141, 100), (200, 100), (200, 215), (0, 215)]   # = traiter_griffes.py
ZONE_G = (400, 520, 600, 735)
ZONE_D = (808, 520, 1008, 735)

sol = Image.open(os.path.join(CIN, "sol.png")).convert("RGBA")
corps = Image.open(os.path.join(CIN, "corps.png")).convert("RGBA")
alpha = corps.getchannel("A")
d = ImageDraw.Draw(alpha)
for (x0, y0, x1, y1), miroir in ((ZONE_G, False), (ZONE_D, True)):
    w = x1 - x0
    poly = [(w - x, y) for x, y in POLY_G] if miroir else POLY_G
    d.polygon([(x0 + x, y0 + y) for x, y in poly], fill=0)     # les griffes disparaissent (le sol réapparaît)
corps.putalpha(alpha)
sol.alpha_composite(corps)
morceau = sol.crop((454, 480, 954, 720)).resize((400, 192), Image.LANCZOS)   # échelle 0,8 (le château doit PESER devant le joueur)
morceau.save(SORTIE)
# la bande de SOL sous la façade (rangées 12-13, colonnes 1-24) : même image, pour que le dessous ne soit pas de l'herbe de village
bande = sol.crop((474, 720, 954, 760)).resize((384, 32), Image.LANCZOS)
bande.save(SORTIE.replace("v_facade_queue.png", "v_facade_queue_sol.png"))
print("v_facade_queue.png écrit (morceau de l'image du coq)")
