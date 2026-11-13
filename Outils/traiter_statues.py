"""Outil de développement : découpe la planche Gemini `statues.jpg` (4 colonnes x 2 rangées, fond magenta en dégradé)
et écrit des statues 22x34 (alignées en bas) dans Assets/Gemini/tuiles/.
A lancer APRÈS fabriquer_statues.py (il remplace statue_chevalier / statue_oiseau par les versions Gemini)."""
import numpy as np
from PIL import Image, ImageFilter
from collections import deque

SRC = "Assets/Gemini/originaux/statues.jpg"
SORTIE = "Assets/Gemini/tuiles/"
L, H = 22, 34
NOMS = [["statue_chevalier", "statue_lance", "statue_oiseau", "statue_oiseau_g"],
        ["statue_oiseau_d2", "statue_capuche", "statue_gargouille", "statue_gargouille_ailee"]]

def fond(rgb):
    r, g, b = [rgb[..., i].astype(int) for i in range(3)]
    return (r > 120) & (b > 120) & (g < np.minimum(r, b) - 45)

img = Image.open(SRC).convert("RGB")
W, Ht = img.size
for j in range(2):
    for i in range(4):
        x0, x1 = i * W // 4, (i + 1) * W // 4
        y0, y1 = j * Ht // 2, (j + 1) * Ht // 2
        c = np.array(img.crop((x0, y0, x1, y1)))
        m = ~fond(c)
        # garde la plus grande composante (ignore les bords des cases voisines)
        h, w = m.shape
        lab = np.zeros((h, w), int); n = 0; tailles = {}
        for sy in range(h):
            for sx in range(w):
                if m[sy, sx] and not lab[sy, sx]:
                    n += 1; lab[sy, sx] = n; q = deque([(sy, sx)]); t = 0
                    while q:
                        y, x = q.popleft(); t += 1
                        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                            yy, xx = y+dy, x+dx
                            if 0 <= yy < h and 0 <= xx < w and m[yy, xx] and not lab[yy, xx]:
                                lab[yy, xx] = n; q.append((yy, xx))
                    tailles[n] = t
        gros = max(tailles, key=tailles.get)
        m = lab == gros
        ys, xs = np.where(m)
        bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        rgba = np.dstack([c, (m * 255).astype(np.uint8)])
        im = Image.fromarray(rgba, "RGBA").crop((bx0, by0, bx1, by1))
        ech = min(L / im.width, H / im.height)
        nw, nh = max(1, round(im.width * ech)), max(1, round(im.height * ech))
        # réduction sur couleurs prémultipliées pour éviter le liseré magenta
        a = im.split()[3].resize((nw, nh), Image.LANCZOS)
        rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.4)).resize((nw, nh), Image.LANCZOS)
        rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=120, threshold=2))
        a = a.point(lambda v: 255 if v > 110 else 0)
        # supprime les reflets magenta résiduels (g trop bas par rapport à r et b)
        ar = np.array(rgb).astype(int)
        ar[..., 1] = np.maximum(ar[..., 1], np.minimum(ar[..., 0], ar[..., 2]) - 12)
        ar[..., 0] = np.minimum(ar[..., 0], ar[..., 2])
        rgb = Image.fromarray(ar.clip(0, 255).astype(np.uint8), "RGB")
        out = Image.new("RGBA", (L, H), (0, 0, 0, 0))
        r = Image.merge("RGBA", (*rgb.split(), a))
        out.paste(r, ((L - nw) // 2, H - nh), r)
        out.save(SORTIE + NOMS[j][i] + ".png")
        print(NOMS[j][i], (nw, nh))

# aperçu
ap = Image.new("RGBA", (8 * (L + 6) * 3, (H + 6) * 3), (60, 62, 80, 255))
for k, n in enumerate(sum(NOMS, [])):
    s = Image.open(SORTIE + n + ".png").resize((L * 3, H * 3), Image.NEAREST)
    ap.paste(s, (k * (L + 6) * 3 + 9, 9), s)
ap.save("Outils/apercus/statues.png")
