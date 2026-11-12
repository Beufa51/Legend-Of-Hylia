"""Outil de développement : fabrique une image d'aperçu d'une salle de world.tscn (même logique que room.gd).
Usage : python3 Outils/apercu_salle.py <numero_salle> <fichier_sortie.png>   (0 = Entrée, 1 = Salle1, ...)"""
import os, re, sys
from PIL import Image
RACINE = os.path.join(os.path.dirname(__file__), "..")
D = os.path.join(RACINE, "Assets", "Gemini", "tuiles") + os.sep
T, E = 16, 2
C = {}
def L(n):
    if n not in C: C[n] = Image.open(D + n + ".png").convert("RGBA")
    return C[n]
def room(lay, out):
    H = len(lay); W = len(lay[0]); img = Image.new("RGBA", (W * T, H * T))
    mur = lambda x, y: x < 0 or y < 0 or x >= W or y >= H or lay[y][x] == "#"
    sol = lambda x, y: not mur(x, y)
    vus = set(); st = [(x, y) for y in range(H) for x in range(W) if (x in (0, W - 1) or y in (0, H - 1)) and lay[y][x] == "#"]
    while st:
        c = st.pop(); x, y = c
        if c in vus or not (0 <= x < W and 0 <= y < H) or lay[y][x] != "#": continue
        vus.add(c); st += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    P = lambda n, x, y, dx=0, dy=0: img.alpha_composite(L(n), (x * T + dx, y * T + dy))
    for y in range(H):
        for x in range(W):
            if not mur(x, y):
                h = (x * 7 + y * 13 + x * y * 3) % 37; clair = (x + y) % 2 == 0
                P(("sol_plat_c" if clair else "sol_plat_d") if h == 0 else ("sol_plat" if clair else "sol_plat_b"), x, y)
                if mur(x, y - 1): img.alpha_composite(Image.new("RGBA", (T, 5), (0, 0, 0, 70)), (x * T, y * T))
                if x < E or y < E or x >= W - E or y >= H - E: img.alpha_composite(Image.new("RGBA", (T, T), (0, 0, 0, 115)), (x * T, y * T))
            elif (x, y) in vus:
                P("mur_fond", x, y)
                n, s_, e, o = sol(x, y - 1), sol(x, y + 1), sol(x + 1, y), sol(x - 1, y)
                u = {"n": 0, "s": 0, "e": 0, "o": 0}
                for a, b, fa, fb in [("n", "o", n, o), ("n", "e", n, e), ("s", "o", s_, o), ("s", "e", s_, e)]:
                    if fa and fb: P("mur_coin_" + a + b, x, y); u[a] = u[b] = 1
                for k, f in [("n", n), ("s", s_), ("e", e), ("o", o)]:
                    if f and not u[k]: P("mur_bord_" + k, x, y)
                if not (n or s_ or e or o):
                    for nm, (dx, dy) in {"se": (1, 1), "so": (-1, 1), "ne": (1, -1), "no": (-1, -1)}.items():
                        if sol(x + dx, y + dy): P("mur_dot_" + nm, x, y)
            else: P("dalle_unie", x, y)
    for y in range(H):
        for x in range(W):
            ch = lay[y][x]
            if ch == "T": P("tapis_milieu", x, y)
            elif ch == "S": P("statue_chevalier", x, y, 0, T - 30)
            elif ch == "O": P("statue_oiseau", x, y, 0, T - 30)
            elif ch == "V": P("vase_1", x, y, 3, 3)
            elif ch == "B": P("brasero_2", x, y)
    for x in (7, 17):
        if mur(x, E - 1) and sol(x, E): P("banniere", x, 0, 0, E * T - 26)
    for x in (4, 20):
        if mur(x, E - 1) and sol(x, E): P("torche_1", x, E - 1)
    kn = Image.open(os.path.join(RACINE, "Assets/Ninja_adventure/Actor/Character/Knight/SeparateAnim/Idle.png")).convert("RGBA").crop((0, 0, 16, 16))
    img.alpha_composite(kn, (192, 172))
    img.resize((W * T * 3, H * T * 3), Image.NEAREST).save(out)
if __name__ == "__main__":
    w = open(os.path.join(RACINE, "Scenes", "world.tscn"), encoding="utf-8").read()
    l = re.findall(r"layout = PackedStringArray\((.*)\)", w)
    room(re.findall(r'"([^"]+)"', l[int(sys.argv[1])]), sys.argv[2])
