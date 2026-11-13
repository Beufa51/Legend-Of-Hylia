"""Outil de développement : fabrique une image d'aperçu d'une salle de world.tscn (même logique que room.gd).
Usage : python3 Outils/apercu_salle.py <numero_salle> <fichier_sortie.png> [scene.tscn]   (numéro = ordre dans la scène ; scène par défaut world.tscn)"""
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
    P = lambda n, x, y, dx=0, dy=0: img.alpha_composite(L(n), (x * T + dx, y * T + dy))
    mur = lambda x, y: x < 0 or y < 0 or x >= W or y >= H or lay[y][x] in "#R"
    sol = lambda x, y: not mur(x, y)
    face_bas = lambda x, y: mur(x, y) and 0 <= y + 1 < H and sol(x, y + 1)
    face_haut = lambda x, y: mur(x, y) and face_bas(x, y + 1) and mur(x, y - 1)
    for y in range(H):
        for x in range(W):
            if sol(x, y):
                h = (x * 7 + y * 13 + x * y * 3) % 37
                if lay[y][x] == "i": P("glace_1" if (x * 3 + y * 5) % 4 else "glace_2", x, y)
                else: P("sol_plat_c" if h == 0 else ("sol_plat_d" if h == 18 else "sol_plat"), x, y)
                if lay[y][x] == "X": P("bloc_pierre", x, y)
                if x < E or y < E or x >= W - E or y >= H - E: img.alpha_composite(Image.new("RGBA", (T, T), (0, 0, 0, 90)), (x * T, y * T))
    for y in range(H):
        for x in range(W):
            if not mur(x, y): continue
            if not (mur(x - 1, y) or mur(x + 1, y) or mur(x, y - 1) or mur(x, y + 1)):
                P("pilier", x, y, 0, -8); continue
            if face_bas(x, y) or face_haut(x, y):
                nom = "mur_face_" + ("bas" if face_bas(x, y) else "haut")
                if not mur(x - 1, y): nom += "_g"
                elif not mur(x + 1, y): nom += "_d"
                if face_bas(x, y): P("sol_plat", x, y)   # le bas de la face est transparent (ombre sur le sol)
                P(nom, x, y); continue
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
    for y in range(H):
        for x in range(W):
            ch = lay[y][x]
            if ch == "T": P("tapis_milieu", x, y)
            elif ch == "S": P("statue_chevalier", x, y, -3, T - 34)
            elif ch == "O": P("statue_oiseau", x, y, -3, T - 34)
            elif ch == "V": P("vase_1", x, y, 0, -1)
            elif ch == "B" or ch == "l": P("brasero_2", x, y, -2, -10)
            elif ch == "L": P("brasero_eteint", x, y, -2, -10)
            elif ch == "w":
                b = (1 if y > 0 and lay[y-1][x] == "w" else 0) | (2 if y < len(lay)-1 and lay[y+1][x] == "w" else 0) | (4 if x > 0 and lay[y][x-1] == "w" else 0) | (8 if x < len(lay[y])-1 and lay[y][x+1] == "w" else 0)
                P("flaque_%d_1" % b, x, y)
            elif ch == "Q": P("coffre_1", x, y, -2, -6)
            elif ch == "a": P("dalle_reflet", x, y)
            elif ch == "P": P("marque", x, y)
            elif ch == "G": P("plume_doree", x, y, 2, 2)
            elif ch == "J": P("levier_1", x, y, 0, -12)
            elif ch == "Z": P("pics_5" if x % 2 == 0 else "pics_1", x, y, 0, -8)
            elif ch == "~": P("eau_1", x, y)
            elif ch in "DE" and y == 0 and x + 2 < W and lay[y][x + 2] == ch and (x == 0 or lay[y][x - 1] != ch):
                P("arche_bois_1" if ch == "E" else "arche_herse_1", x, y)
            elif ch == "D" and 0 < y < H - 1 and lay[y - 1][x] != "D" and lay[y + 1][x] != "D" and x + 2 < W and lay[y][x + 2] == "D" and lay[y][x - 1] != "D":
                P("arche_basse_1", x, y)
    for x in (7, 17):
        if mur(x, E - 1) and sol(x, E): P("banniere", x, 0, 0, E * T - 26)
    for x in (9, 14):   # niches voûtées à barreaux (room.gd::COLONNES_NICHES)
        if mur(x, E - 1) and sol(x, E) and mur(x + 1, E - 1) and sol(x + 1, E): P("niche_grille", x, 0, 0, E * T - 21)
    for x in (4, 20):
        if mur(x, E - 1) and sol(x, E): P("torche_1", x, 0, 2, E * T - 24)
    kn = Image.open(os.path.join(RACINE, "Assets/Ninja_adventure/Actor/Character/Knight/SeparateAnim/Idle.png")).convert("RGBA").crop((0, 0, 16, 16))
    img.alpha_composite(kn, (192, 172))
    img.resize((W * T * 3, H * T * 3), Image.NEAREST).save(out)
if __name__ == "__main__":
    scene = sys.argv[3] if len(sys.argv) > 3 else "world.tscn"
    w = open(os.path.join(RACINE, "Scenes", scene), encoding="utf-8").read()
    l = re.findall(r"layout = PackedStringArray\((.*)\)", w)
    room(re.findall(r'"([^"]+)"', l[int(sys.argv[1])]), sys.argv[2])
