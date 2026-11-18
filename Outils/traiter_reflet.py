"""Découpe la planche Gemini `reflet.jpg` (rangée du haut : dalle-miroir éteinte / allumée, bouton rond relevé / enfoncé ; fond magenta)
-> Assets/Gemini/tuiles/ : dalle_reflet.png, dalle_reflet_on.png, bouton_reflet.png, bouton_reflet_on.png (16x16).
Les herses (rangée du bas) ne sont PAS utilisées : image presque carrée, nos portes intérieures font 3x1 ou 3x2 cases.
A lancer APRES traiter_pack_donjon.py (qui écrit les anciennes dalle_reflet en code)."""
import numpy as np
from PIL import Image
from collections import deque

SRC = "Assets/Gemini/originaux/reflet.jpg"
SORTIE = "Assets/Gemini/tuiles/"
NOMS = ["dalle_reflet", "dalle_reflet_on", "bouton_reflet", "bouton_reflet_on"]

img = Image.open(SRC).convert("RGB")
W, H = img.size
haut = np.array(img.crop((0, 0, W, H // 2 - 10)))
r, g, b = [haut[..., i].astype(int) for i in range(3)]
masque = ~((r > 120) & (b > 120) & (g < np.minimum(r, b) - 45))
h, w = masque.shape
lab = np.zeros((h, w), int); n = 0; tailles = {}
for sy in range(h):
    for sx in range(w):
        if masque[sy, sx] and not lab[sy, sx]:
            n += 1; lab[sy, sx] = n; q = deque([(sy, sx)]); t = 0
            while q:
                y, x = q.popleft(); t += 1
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and masque[yy, xx] and not lab[yy, xx]:
                        lab[yy, xx] = n; q.append((yy, xx))
            tailles[n] = t
gros = sorted([k for k, v in tailles.items() if v > 5000], key=lambda k: np.where(lab == k)[1].min())
assert len(gros) == 4, "4 objets attendus, trouvé %d" % len(gros)
for k, nom in zip(gros, NOMS):
    ys, xs = np.where(lab == k)
    boite = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    alpha = Image.fromarray(((lab == k) * 255).astype(np.uint8)).crop(boite)
    im = Image.fromarray(haut).crop(boite).convert("RGBA")
    im.putalpha(alpha)
    im = im.resize((16, 16), Image.LANCZOS)
    a = np.array(im); a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
    Image.fromarray(a).save(SORTIE + nom + ".png")
print("écrit :", ", ".join(NOMS))
