"""Planche Gemini `originaux/tapis.jpg` (tapis rouge à bordure dorée : 4 coins, 4 bords, 1 centre à emblème, fond magenta)
-> Assets/Gemini/tuiles/tapis_<bits>.png (16x16) : AUTOTILE par voisins (bits : 1 nord, 2 sud, 4 ouest, 8 est = un autre tapis de ce côté),
   + tapis_embleme.png (centre avec l'emblème doré). Utilisé par room.gd (lettre T).

Méthode : on fabrique 9 tuiles de référence 16x16 (coins, bords, centre) à la MÊME épaisseur de bordure, puis chaque tuile finale
est assemblée par quarts de 8x8 (chaque quart pris dans la référence qui correspond aux côtés sans voisin)."""
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SRC = "Assets/Gemini/originaux/tapis.jpg"
SORTIE = "Assets/Gemini/tuiles/"
T = 16

a = np.array(Image.open(SRC).convert("RGB")).astype(int)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
fond = (r > 150) & (b > 150) & (g < 100)
lab, n = ndimage.label(~fond)
boites = [s for s in ndimage.find_objects(lab) if (s[0].stop - s[0].start) * (s[1].stop - s[1].start) > 2000]
# les 9 pièces, reconnues à la position de leur centre (coins aux 4 coins, bords latéraux entre les coins et le centre)
morceaux = {}
for s in boites:
    x0, x1, y0, y1 = s[1].start, s[1].stop, s[0].start, s[0].stop
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    W, H = a.shape[1], a.shape[0]
    if cx < W * 0.22: nom = "no" if cy < H / 2 else "so"
    elif cx > W * 0.78: nom = "ne" if cy < H / 2 else "se"
    elif cx < W * 0.4: nom = "o"
    elif cx > W * 0.6: nom = "e"
    else: nom = "n" if cy < H * 0.3 else ("s" if cy > H * 0.7 else "c")
    M = 10   # le trait noir qui entoure chaque pièce de la planche : on le retire (sinon une ligne sombre entre chaque tuile)
    morceaux[nom] = Image.fromarray(a[y0 + M:y1 - M, x0 + M:x1 - M].astype(np.uint8), "RGB")

def red(im, w, h):
    return im.filter(ImageFilter.GaussianBlur(0.7)).resize((w, h), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=0.8, percent=100, threshold=2))

echelle = T / morceaux["no"].width                     # même épaisseur de bordure partout
c = morceaux["c"]
rouge = c.crop((20, 20, 80, 80))                        # du rouge sans l'emblème
ref = {}
moy = np.array(rouge).reshape(-1, 3).mean(0)          # rouge UNI (avec une trame très légère) : pas de couture visible entre les tuiles
fond_rouge = np.zeros((T, T, 3)) + moy
fond_rouge[(np.add.outer(np.arange(T), np.arange(T)) % 4) == 0] *= 0.94
ref["c"] = Image.fromarray(fond_rouge.clip(0, 255).astype(np.uint8), "RGB")
for k in ("no", "ne", "so", "se"):
    ref[k] = red(morceaux[k], T, T)
for k, vertical in (("n", True), ("s", True), ("o", False), ("e", False)):
    m = morceaux[k]
    base = ref["c"].copy()
    if vertical:
        h = max(4, round(m.height * echelle)); bande = red(m, T, h)
        base.paste(bande, (0, 0 if k == "n" else T - h))
    else:
        w = max(4, round(m.width * echelle)); bande = red(m, w, T)
        base.paste(bande, (0 if k == "o" else T - w, 0))
    ref[k] = base
ref["c"].save(SORTIE + "tapis_plein.png")
emb = red(c, T, T); emb.save(SORTIE + "tapis_embleme.png")

H8 = T // 2
for bits in range(16):
    N, S, O, E = bits & 1, bits & 2, bits & 4, bits & 8   # vrai = voisin tapis de ce côté
    out = Image.new("RGB", (T, T))
    for qy, haut in ((0, True), (H8, False)):
        for qx, gauche in ((0, True), (H8, False)):
            bord_v = not (N if haut else S)              # pas de voisin en haut/bas de ce quart
            bord_h = not (O if gauche else E)
            if bord_v and bord_h: k = ("n" if haut else "s") + ("o" if gauche else "e")
            elif bord_v: k = "n" if haut else "s"
            elif bord_h: k = "o" if gauche else "e"
            else: k = "c"
            out.paste(ref[k].crop((qx, qy, qx + H8, qy + H8)), (qx, qy))
    px = out.load()                                      # fin liseré sombre sur le bord extérieur du tapis
    for i in range(T):
        if not N: px[i, 0] = (52, 14, 18)
        if not S: px[i, T - 1] = (52, 14, 18)
        if not O: px[0, i] = (52, 14, 18)
        if not E: px[T - 1, i] = (52, 14, 18)
    out.save(SORTIE + "tapis_%d.png" % bits)
print("tapis_0..15, tapis_plein, tapis_embleme (16x16)")
