"""Outil de développement : aperçu FIDÈLE d'un ou plusieurs écrans du village (mêmes images, mêmes emprises que Scripts/exterieur.gd).
Usage : python3 Outils/apercu_village.py sortie.png Ecran1 [Ecran2 ...]      (ex. PlaceDuCoq Verger Riviere)
Les écrans sont posés côte à côte. Les habitants sont dessinés (première pose), pas les animaux."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
import generer_village as gv

RACINE = os.path.join(os.path.dirname(__file__), "..")
T = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
W, H = gv.W, gv.H

# table des objets lue directement dans exterieur.gd : lettre -> (image, largeur, hauteur)
OBJ = {}
for m in re.finditer(r'"(.)": \["(v_\w+)", Vector2i\((\d+), (\d+)\)', open(os.path.join(RACINE, "Scripts", "exterieur.gd"), encoding="utf-8").read()):
    OBJ[m.group(1)] = (m.group(2), int(m.group(3)), int(m.group(4)))


def img(nom):
    return Image.open(os.path.join(T, nom + ".png")).convert("RGBA")


def rendre(nom, g, props, grille):
    gx, gy = grille
    out = Image.new("RGBA", (W * 16, H * 16))
    chemin = lambda x, y: g[min(max(y, 0), H - 1)][min(max(x, 0), W - 1)] == ':'
    eau = lambda x, y: g[min(max(y, 0), H - 1)][min(max(x, 0), W - 1)] in '~='
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if eau(x, y):
                base = "v_eau_h" if not eau(x, y - 1) else ("v_eau_b" if not eau(x, y + 1) else "v_eau")
                out.alpha_composite(img(base + "_1"), (x * 16, y * 16))
                if c == '=':
                    cote = "g" if g[y][max(x - 1, 0)] != '=' else ("d" if g[y][min(x + 1, W - 1)] != '=' else "m")
                    out.alpha_composite(img("v_pont_" + cote), (x * 16, y * 16))
            elif chemin(x, y):
                bits = (1 if chemin(x, y - 1) else 0) | (2 if chemin(x, y + 1) else 0) | (4 if chemin(x - 1, y) else 0) | (8 if chemin(x + 1, y) else 0)
                if bits == 15:
                    coins = (1 if not chemin(x + 1, y - 1) else 0) | (2 if not chemin(x - 1, y - 1) else 0) | (4 if not chemin(x + 1, y + 1) else 0) | (8 if not chemin(x - 1, y + 1) else 0)
                    n = "v_chemin_f%d" % coins
                else:
                    n = "v_chemin_%d" % bits
                out.alpha_composite(img(n), (x * 16, y * 16))
            else:
                h = (x * 73 + y * 151 + gx * 31 + gy * 17) % 13
                out.alpha_composite(img("v_herbe_sol_%d" % (h + 1) if h < 2 else "v_herbe_sol"), (x * 16, y * 16))
    objets = []
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if c in OBJ:
                n, ew, eh = OBJ[c]
                im = img(n)
                objets.append(((y + eh) * 16, im, round((x + ew / 2) * 16 - im.width / 2), round((y + eh) * 16 - im.height)))
            elif c == 'Q':
                objets.append(((y + 4) * 16, img("girouette_mat"), x * 16, y * 16))
                coq = img("girouette_coq")
                objets.append(((y + 4) * 16 + 1, coq, x * 16 + 24 - coq.width // 2, y * 16 + 17 - coq.height))
    for ligne in props.get('pnjs', []):
        t = ligne.split('|')[0].split()
        f = os.path.join(RACINE, "Assets", "Heros", "pnj_%s.png" % t[0])
        if os.path.exists(f):
            case = Image.open(f).convert("RGBA").crop((96 if t[3] == "droite" else 64, 0, 128 if t[3] == "droite" else 96, 32))
            objets.append(((int(t[2]) + 1) * 16, case, int(t[1]) * 16 + 8 - 16, int(t[2]) * 16 + 10 - 22))
    for base, im, px, py in sorted(objets, key=lambda o: o[0]):
        out.alpha_composite(im, (px, py))
    return out


if __name__ == "__main__":
    sortie, noms = sys.argv[1], sys.argv[2:]
    toile = Image.new("RGBA", (W * 16 * len(noms), H * 16))
    for i, nom in enumerate(noms):
        grille, g, props = next((gr, gg, p) for n, gr, gg, p in gv.ecrans if n == nom)
        toile.alpha_composite(rendre(nom, g, props, grille), (i * W * 16, 0))
    toile.resize((toile.width * 2, toile.height * 2), Image.NEAREST).save(sortie)
    print("aperçu écrit :", sortie)
