"""Outil de développement : extrait le coq choisi (variante en bas à gauche de embleme_coq_4variantes.jpg)
et simplifie les AILES (moins de plumes) par flou + seuil. Usage : python3 Outils/simplifier_coq.py [sigma] [seuil]
Plus sigma est grand, moins il y a de plumes (5 = environ 3 plumes par aile, 7 = 2 gros lobes)."""
import os, sys
import numpy as np
from PIL import Image, ImageFilter
RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini")
sigma = float(sys.argv[1]) if len(sys.argv) > 1 else 5
seuil = float(sys.argv[2]) if len(sys.argv) > 2 else 0.40
im = Image.open(os.path.join(RACINE, "originaux", "embleme_coq_4variantes.jpg")).convert("RGB")
a = np.array(im.crop((4, 390, 700, 764))).astype(int)
m = Image.fromarray((((a[..., 0] - a[..., 1]) > 60) * 255).astype(np.uint8)).crop((44, 24, 652, 348))
M = np.array(m) > 0
c = np.array(m.filter(ImageFilter.GaussianBlur(sigma))).astype(float) / 255 > seuil
out = M.copy()
zone = np.zeros_like(M); zone[:200, :238] = True; zone[:200, 368:] = True   # ailes seulement
out[zone] = c[zone]
rgba = np.zeros(M.shape + (4,), np.uint8); rgba[out] = (168, 20, 40, 255)
Image.fromarray(rgba, "RGBA").save(os.path.join(RACINE, "embleme", "coq_rouge.png"))
print("OK coq_rouge.png (sigma", sigma, "seuil", seuil, ")")
