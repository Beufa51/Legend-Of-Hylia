"""Outil de développement : vérifie la CARTE du village (sans lancer Godot).
Usage : python3 Outils/verifier_carte.py [--carte]    (--carte : dessine aussi toute la carte en texte)
Contrôles :
  1. chaque case de bord où l'on peut marcher mène à un écran voisin qui existe, sur une case libre (sinon le héros sort de la carte) ;
  2. tous les écrans extérieurs sont atteignables à pied depuis la place, ainsi que chaque porte de maison ;
  3. chaque passage vise un écran qui existe, sur une case libre ; chaque porte correspond à une vraie maison ;
  4. habitants et animaux sont sur une case libre et atteignable.
Utilise la même logique de collision que Scripts/exterieur.gd (table EMPRISES de generer_village.py).
"""
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(__file__))
import generer_village as gv

W, H = gv.W, gv.H
PORTES = {'M': 2, 'N': 2, 'T': 2, 'R': 2, 'S': 2, 'K': 2, 'L': 2, 'U': 3, 'Z': 4}   # colonne de la porte (PORTES_MAISONS de exterieur.gd)

ext = {nom: (grille, g) for nom, grille, g, _ in gv.ecrans}
props = {nom: p for nom, _, _, p in gv.ecrans}
inte = {nom: (grille, g) for nom, grille, g, _ in gv.interieurs}
props.update({nom: p for nom, _, _, p in gv.interieurs})
erreurs = []


def passages_de(nom):
    return [l.split(" ", 2) for l in props[nom].get('passages', [])]


def solides_ext(nom):
    g = ext[nom][1]
    s = set()
    for y in range(H):
        for x in range(W):
            if g[y][x] not in gv.NON_BLOQUANTS:
                s |= set(gv.cases_objet(g, x, y))
    ter, esc = props[nom].get('terrasses', []), props[nom].get('escaliers', [])
    s |= gv.cases_relief(ter, esc)[0]          # relief : bord et falaise des terrasses
    for ligne in esc:                          # les escaliers percent la falaise
        x0, y0 = (int(v) for v in ligne.split())
        for j in range(4):
            for i in range(2): s.discard((x0 + i, y0 + j))
    for ligne in props[nom].get('coffres', []):      # un coffre bloque sa case
        s.add(tuple(int(v) for v in ligne.split("|")[0].split()[:2]))
    for ligne in props[nom].get('secrets', []):      # le rocher fissuré et le coffre caché aussi
        t = [int(v) for v in ligne.split("|")[0].split()[:4]]
        s |= {(t[0], t[1]), (t[2], t[3])}
    for p in passages_de(nom):
        s.discard((int(p[0]), int(p[1])))     # on marche dans la porte
    return s


SOL = {nom: solides_ext(nom) for nom in ext}


# --- intérieurs : cases bloquantes = murs, pans de mur du haut (2x2) et meubles (emprises lues dans Scripts/interieur.gd)
import re
_gd = open(os.path.join(os.path.dirname(__file__), "..", "Scripts", "interieur.gd"), encoding="utf-8").read()
EMP_INT = {m.group(1): (int(m.group(3)), int(m.group(4)), m.group(5) == "true")
           for m in re.finditer(r'"(.)": \["(v_\w+)", Vector2i\((\d+), (\d+)\), (true|false)\]', _gd)}


def solides_int(g):
    s = set()
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if c in ' #':
                s.add((x, y))
            elif c in 'wxyvz':
                s |= {(x + i, y + j) for i in range(2) for j in range(2)}
            elif c in EMP_INT and EMP_INT[c][2]:
                w, h, _ = EMP_INT[c]
                s |= {(x + i, y + j) for i in range(w) for j in range(h)}
    return s


SOL_INT = {nom: solides_int(g) for nom, (_, g) in inte.items()}


def libre(nom, x, y):
    if not (0 <= x < W and 0 <= y < H): return False
    if nom in ext: return (x, y) not in SOL[nom]
    return (x, y) not in SOL_INT[nom]


# --- 1. bords ---
par_grille = {grille: nom for nom, (grille, _) in ext.items()}
for nom, ((gx, gy), g) in ext.items():
    for y in range(H):
        for x in range(W):
            if not libre(nom, x, y): continue
            dx = -1 if x == 0 else (1 if x == W - 1 else 0)
            dy = -1 if y == 0 else (1 if y == H - 1 else 0)
            if dx == 0 and dy == 0: continue
            if dx and dy: continue
            voisin = par_grille.get((gx + dx, gy + dy))
            if voisin is None:
                erreurs.append("%s : la case (%d,%d) du bord est libre mais il n'y a pas d'écran voisin" % (nom, x, y))
            elif not libre(voisin, (x + dx) % W, (y + dy) % H):
                erreurs.append("%s : la sortie (%d,%d) donne sur un obstacle dans %s" % (nom, x, y, voisin))

# --- 2. atteignabilité (marche + portes) ---
def voisins(nom, x, y):
    for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + ddx, y + ddy
        if 0 <= nx < W and 0 <= ny < H:
            if libre(nom, nx, ny): yield (nom, nx, ny)
        elif nom in ext:
            gx, gy = ext[nom][0]
            v = par_grille.get((gx + (nx < 0 and -1 or nx >= W and 1 or 0), gy + (ny < 0 and -1 or ny >= H and 1 or 0)))
            if v and libre(v, nx % W, ny % H): yield (v, nx % W, ny % H)
    if nom in ext or nom in inte:
        for p in (passages_de(nom) if nom in props else []):
            if (int(p[0]), int(p[1])) == (x, y) and len(p) > 2:
                m = p[2].split(" ")
                if m[0] in inte or m[0] in ext:
                    yield (m[0], int(m[1]), int(m[2]))

depart = ('PlaceDuCoq', 12, 7)
vus = {depart}
file = deque([depart])
while file:
    u = file.popleft()
    for v in voisins(*u):
        if v not in vus:
            vus.add(v); file.append(v)
for nom in list(ext) + list(inte):
    if not any(v[0] == nom for v in vus):
        erreurs.append("%s : écran INATTEIGNABLE depuis la place" % nom)

# --- 3. passages ---
for nom in props:
    for p in passages_de(nom):
        x, y = int(p[0]), int(p[1])
        cible = p[2].split(" ")[0] if len(p) > 2 else ""
        if cible[:1] in ("!", "$"): continue
        if cible.startswith("@"): continue
        if cible not in ext and cible not in inte:
            erreurs.append("%s : le passage (%d,%d) vise un écran inconnu : %s" % (nom, x, y, cible)); continue
        m = p[2].split(" ")
        if not libre(cible, int(m[1]), int(m[2])):
            erreurs.append("%s : le passage (%d,%d) arrive sur une case bloquée de %s (%s,%s)" % (nom, x, y, cible, m[1], m[2]))
        if nom in ext:
            g = ext[nom][1]
            if not any(g[y - (gv.TAILLES_MAISONS[c][1] - 1)][x - col] == c for c, col in PORTES.items()
                       if 0 <= y - (gv.TAILLES_MAISONS[c][1] - 1) < H and 0 <= x - col < W):
                erreurs.append("%s : le passage (%d,%d) n'est sous la porte d'aucune maison" % (nom, x, y))
            if (nom, x, y + 1) not in vus:
                erreurs.append("%s : la porte (%d,%d) n'est pas atteignable à pied" % (nom, x, y))

# --- 4. habitants et animaux ---
for nom, p in props.items():
    gens = [("habitant", l.split("|")[0].split()[1:3]) for l in p.get('pnjs', [])] + [("animal", l.split()[1:3]) for l in p.get('animaux', [])]
    for qui, (sx, sy) in gens:
        x, y = int(sx), int(sy)
        if not libre(nom, x, y):
            erreurs.append("%s : un %s est dans un obstacle en (%d,%d)" % (nom, qui, x, y))
        elif (nom, x, y) not in vus:
            erreurs.append("%s : un %s est inatteignable en (%d,%d)" % (nom, qui, x, y))

# --- 5. coffres et rochers : atteignables (une case voisine libre et atteinte)
for nom, p in props.items():
    cibles = [tuple(int(v) for v in l.split("|")[0].split()[:2]) for l in p.get('coffres', [])]
    for l in p.get('secrets', []):
        t = [int(v) for v in l.split("|")[0].split()[:4]]
        cibles += [(t[0], t[1]), (t[2], t[3])]
    for (x, y) in cibles:
        if not any((nom, x + dx, y + dy) in vus for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            erreurs.append("%s : le coffre/rocher (%d,%d) n'est pas atteignable à pied" % (nom, x, y))

print("écrans extérieurs :", len(ext), "| intérieurs :", len(inte), "| cases atteintes :", len(vus))
if erreurs:
    print("\n%d PROBLÈME(S) :" % len(erreurs))
    for e in erreurs: print(" -", e)
else:
    print("OK : bords fermés, tout est atteignable, tous les passages sont cohérents.")

if "--carte" in sys.argv:
    xs = [grille[0] for grille, _ in ext.values()]; ys = [grille[1] for grille, _ in ext.values()]
    for gy in range(min(ys), max(ys) + 1):
        for y in range(H):
            ligne = ""
            for gx in range(min(xs), max(xs) + 1):
                nom = par_grille.get((gx, gy))
                for x in range(W):
                    if nom is None: ligne += " "; continue
                    c = ext[nom][1][y][x]
                    ligne += ('~' if c == '~' else '=' if c == '=' else '#' if (x, y) in SOL[nom] else ':' if c == ':' else '.')
                ligne += "|"
            print(ligne)
        print("-" * 5)
sys.exit(1 if erreurs else 0)
