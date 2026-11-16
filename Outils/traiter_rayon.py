"""Rayon de lumière : planche Gemini `originaux/rayon.jpg` -> `rayon_segment.png` (48 px, se répète bout à bout),
`rayon_etincelles.png` (même longueur, étincelles autour), `rayon_impact.png` (éclat d'impact 26x26)."""
from PIL import Image
import numpy as np
D = "Assets/Gemini/"
im = Image.open(D + "originaux/rayon.jpg").convert("RGB")
a = np.asarray(im).astype(int)
fond = ((a[..., 0] > 150) & (a[..., 2] > 150) & (a[..., 1] < 130)) | ((a[..., 0] > 200) & (a[..., 2] > 200) & (a[..., 1] > 130) & (a[..., 1] < 200) & (a[..., 0] - a[..., 1] > 40) & (a[..., 2] - a[..., 1] > 40))
rgba = Image.fromarray(np.dstack([a, np.where(fond, 0, 255)]).astype("uint8"), "RGBA")


def decoupe(box, taille, nom, quant=20):
    c = rgba.crop(box)
    b = c.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()
    c = c.crop(b)
    p = c.resize(taille, Image.LANCZOS)
    al = p.getchannel("A").point(lambda v: 255 if v > 120 else 0)
    q = p.convert("RGB").quantize(quant, method=Image.MEDIANCUT).convert("RGBA")
    q.putalpha(al)
    q.save(D + "tuiles/%s.png" % nom)
    print(nom, q.size)


# segments : on recadre pile sur le faisceau (largeur 357..1050) pour que le motif se raccorde ; hauteur 6 px
decoupe((357, 45, 1051, 140), (48, 6), "rayon_segment")
# version à étincelles : même largeur, plus haute (les étincelles dépassent)
decoupe((357, 200, 1051, 360), (48, 10), "rayon_etincelles")
decoupe((535, 365, 875, 710), (26, 26), "rayon_impact")
