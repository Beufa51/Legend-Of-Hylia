"""Disque solaire du coq (salle 5e) : planche Gemini `originaux/disque_solaire.jpg` (éteint à gauche, allumé à droite)
-> `disque_solaire_eteint.png` et `disque_solaire.png` (26x26, fond transparent)."""
from PIL import Image
import numpy as np
D = "Assets/Gemini/"
im = Image.open(D + "originaux/disque_solaire.jpg").convert("RGB")
a = np.asarray(im).astype(int)
fond = (a[..., 0] > 150) & (a[..., 2] > 150) & (a[..., 1] < 110)
rgba = Image.fromarray(np.dstack([a, np.where(fond, 0, 255)]).astype("uint8"), "RGBA")
W = rgba.width
for nom, (x0, x1) in {"disque_solaire_eteint": (0, W // 2), "disque_solaire": (W // 2, W)}.items():
    m = rgba.crop((x0, 0, x1, rgba.height))
    m = m.crop(m.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox())
    p = m.resize((26, 26), Image.LANCZOS)
    al = p.getchannel("A").point(lambda v: 255 if v > 140 else 0)
    q = p.convert("RGB").quantize(24, method=Image.MEDIANCUT).convert("RGBA")
    q.putalpha(al)
    q.save(D + "tuiles/%s.png" % nom)
    print(nom)
