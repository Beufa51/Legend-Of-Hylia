"""Outil de développement (APRÈS fabriquer_objets.py) : découpe la planche Gemini `cloches.jpg` (5 cloches sur portique + 5 plaques
de couleur, fond magenta) -> Assets/Gemini/tuiles/cloche_1..5.png (portique + cloche, aligné en bas) et plaque_cloche_1..5.png (14x7).
Écrase les anciennes cloches dessinées en code (cloche_support.png n'est plus utilisé)."""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "Assets/Gemini/originaux/cloches.jpg"
SORTIE = "Assets/Gemini/tuiles/"
LIMITES_X = [0, 366, 652, 916, 1152, 1408]   # séparation entre les 5 colonnes
Y_PLAQUES = 572                              # en dessous : les plaques de couleur
ECHELLE = 0.065
CONTOUR = (28, 20, 14)
LARGEUR, HAUTEUR = 22, 34

def fond(rgb):
    r, g, b = [rgb[..., i].astype(int) for i in range(3)]
    return (r > 120) & (b > 120) & (g < np.minimum(r, b) - 45)

def decouper(img, x0, x1, y0, y1, cadre):
    c = np.array(img.crop((x0, y0, x1, y1)))
    m = ~fond(c)
    lab, n = ndimage.label(m)
    if n > 1:   # on garde les composantes assez grosses (portique, cloche, battant)
        tailles = ndimage.sum(m, lab, range(1, n + 1))
        m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > 0.01 * tailles.max()])
    ys, xs = np.where(m)
    bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    rgb = c[by0:by1, bx0:bx1].copy(); mm = m[by0:by1, bx0:bx1]
    rgb[~mm] = CONTOUR
    w, h = max(1, round((bx1 - bx0) * ECHELLE)), max(1, round((by1 - by0) * ECHELLE))
    p = Image.fromarray(rgb).resize((w, h), Image.LANCZOS)
    a = Image.fromarray((mm * 255).astype(np.uint8)).resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    p = p.quantize(colors=24, dither=Image.NONE).convert("RGB")
    out = p.convert("RGBA"); out.putalpha(a)
    # centré en largeur, aligné en bas dans le cadre
    cw, ch = cadre
    res = Image.new("RGBA", (cw, ch))
    res.alpha_composite(out, ((cw - w) // 2, ch - h))
    return res

img = Image.open(SRC).convert("RGB")
for i in range(5):
    x0, x1 = LIMITES_X[i], LIMITES_X[i + 1]
    decouper(img, x0, x1, 0, Y_PLAQUES, (LARGEUR, HAUTEUR)).save(SORTIE + "cloche_%d.png" % (i + 1))
    decouper(img, x0, x1, Y_PLAQUES, 768, (14, 7)).save(SORTIE + "plaque_cloche_%d.png" % (i + 1))
print("cloches Gemini découpées")
