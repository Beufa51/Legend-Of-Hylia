"""Outil de développement : aperçu FIDÈLE d'un ou plusieurs écrans du village (mêmes images, mêmes emprises que Scripts/exterieur.gd).
Usage : python3 Outils/apercu_village.py [--collisions] sortie.png Ecran1 [Ecran2 ...]      (ex. PlaceDuCoq Verger Riviere)
Les écrans sont posés côte à côte. Les habitants sont dessinés (première pose), pas les animaux."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
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
                bits = (1 if eau(x, y - 1) else 0) | (2 if eau(x, y + 1) else 0) | (4 if eau(x - 1, y) else 0) | (8 if eau(x + 1, y) else 0)
                if bits == 15:
                    base = "v_eau_f%d" % ((1 if not eau(x + 1, y - 1) else 0) | (2 if not eau(x - 1, y - 1) else 0) | (4 if not eau(x + 1, y + 1) else 0) | (8 if not eau(x - 1, y + 1) else 0))
                else:
                    base = "v_eau_%d" % bits
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
    for ligne in props.get('terrasses', []):     # RELIEF : terrasses (mêmes morceaux que exterieur.gd::_poser_relief)
        x0, y0, w, h = (int(v) for v in ligne.split())
        for j in range(h):
            for i in range(w):
                r = 0 if j == 0 else 2 if j == h - 2 else 3 if j == h - 1 else 1
                c = 0 if i == 0 else 2 if i == w - 1 else 1
                out.alpha_composite(img("v_ter_%d%d" % (r, c)), ((x0 + i) * 16, (y0 + j) * 16))
    for ligne in props.get('escaliers', []):
        x0, y0 = (int(v) for v in ligne.split())
        out.alpha_composite(img("v_escalier"), (x0 * 16, y0 * 16))
    objets = []
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if c in OBJ:
                n, ew, eh = OBJ[c]
                im = img(n)
                objets.append(((y + eh) * 16, im, round((x + ew / 2) * 16 - im.width / 2), round((y + eh) * 16 - im.height)))
            elif c == 'Q':
                objets.append(((y + 3) * 16, img("girouette_mat"), x * 16, y * 16))
                coq = img("girouette_coq")
                objets.append(((y + 3) * 16 + 1, coq, x * 16 + 24 - coq.width // 2, y * 16 + 13 - coq.height))
    for ligne in props.get('pnjs', []):
        t = ligne.split('|')[0].split()
        f = os.path.join(RACINE, "Assets", "Heros", "pnj_%s.png" % t[0])
        if os.path.exists(f):
            case = Image.open(f).convert("RGBA").crop((96 if t[3] == "droite" else 64, 0, 128 if t[3] == "droite" else 96, 32))
            objets.append(((int(t[2]) + 1) * 16, case, int(t[1]) * 16 + 8 - 16, int(t[2]) * 16 + 10 - 22))
    for base, im, px, py in sorted(objets, key=lambda o: o[0]):
        out.alpha_composite(im, (px, py))
    if COLLISIONS:   # cases bloquantes en rouge translucide
        calque = Image.new("RGBA", out.size)
        d = ImageDraw.Draw(calque)
        for (cx, cy) in solides_ecran(g, props):
            if 0 <= cx < W and 0 <= cy < H:
                d.rectangle((cx * 16, cy * 16, cx * 16 + 15, cy * 16 + 15), fill=(255, 0, 0, 90), outline=(255, 0, 0, 160))
        out.alpha_composite(calque)
    return out


MEUB = {}
for m in re.finditer(r'"(.)": \["(v_\w+)", Vector2i\((\d+), (\d+)\)', open(os.path.join(RACINE, "Scripts", "interieur.gd"), encoding="utf-8").read()):
    MEUB[m.group(1)] = (m.group(2), int(m.group(3)), int(m.group(4)))
STYLES_INT = {"maison": (["v_sol_bois", "v_sol_bois", "v_sol_bois", "v_sol_bois_b", "v_sol_bois_c"], "v_mur_bois", {"w": "v_mur_a", "x": "v_mur_b", "y": "v_mur_fenetre", "v": "v_mur_tableau", "z": "v_cheminee"}),
              "caserne": (["v_sol_pierre"], "v_mur_pierre_16", {c: "v_mur_pierre" for c in "wxyv"} | {"z": "v_mur_pierre_cheminee"})}


def solides_ecran(g, props):
    """Cases bloquantes d'un écran extérieur (même règle que exterieur.gd : objets pleins, eau, bord et falaise des terrasses ; les portes et escaliers sont ouverts)."""
    sol = set()
    for y in range(H):
        for x in range(W):
            if g[y][x] not in gv.NON_BLOQUANTS:
                sol |= set(gv.cases_objet(g, x, y))
    ter, esc = props.get('terrasses', []), props.get('escaliers', [])
    sol |= gv.cases_relief(ter, esc)[0]
    for ligne in esc:
        x0, y0 = (int(v) for v in ligne.split())
        sol -= {(x0 + i, y0 + j) for i in range(2) for j in range(4)}
    for ligne in props.get('passages', []):
        p = ligne.split(" ", 2)
        sol.discard((int(p[0]), int(p[1])))
    return sol


def rendre_interieur(g, props):
    out = Image.new("RGBA", (W * 16, H * 16), (0, 0, 0, 255))
    sols, mur, haut = STYLES_INT[props.get("style", "maison")]
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if c == " " or c in haut: continue
            out.alpha_composite(img(mur) if c == "#" else img(sols[(x * 7 + y * 13) % len(sols)]), (x * 16, y * 16))
    objets = []
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if c in haut: out.alpha_composite(img(haut[c]), (x * 16, y * 16))
            elif c in MEUB:
                n, ew, eh = MEUB[c]; im = img(n)
                objets.append(((y + eh) * 16 if c not in "tYm" else -1, im, round((x + ew / 2) * 16 - im.width / 2), round((y + eh) * 16 - im.height)))
    for ligne in props.get('pnjs', []):
        t = ligne.split('|')[0].split()
        f = os.path.join(RACINE, "Assets", "Heros", "pnj_%s.png" % t[0])
        if os.path.exists(f):
            case = Image.open(f).convert("RGBA").crop((0, 0, 32, 32))
            objets.append(((int(t[2]) + 1) * 16, case, int(t[1]) * 16 + 8 - 16, int(t[2]) * 16 + 10 - 22))
    for base, im, px, py in sorted(objets, key=lambda o: o[0]):
        out.alpha_composite(im, (px, py))
    return out


COLLISIONS = False

if __name__ == "__main__":
    if "--collisions" in sys.argv:
        COLLISIONS = True
        sys.argv.remove("--collisions")
    sortie, noms = sys.argv[1], sys.argv[2:]
    toile = Image.new("RGBA", (W * 16 * len(noms), H * 16))
    for i, nom in enumerate(noms):
        if nom.startswith("Interieur"):
            grille, g, props = next((gr, gg, p) for n, gr, gg, p in gv.interieurs if n == nom)
            toile.alpha_composite(rendre_interieur(g, props), (i * W * 16, 0))
            continue
        grille, g, props = next((gr, gg, p) for n, gr, gg, p in gv.ecrans if n == nom)
        toile.alpha_composite(rendre(nom, g, props, grille), (i * W * 16, 0))
    toile.resize((toile.width * 2, toile.height * 2), Image.NEAREST).save(sortie)
    print("aperçu écrit :", sortie)
