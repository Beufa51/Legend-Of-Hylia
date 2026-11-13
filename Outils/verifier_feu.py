"""Outil de développement : vérifie que la salle « lance enflammée » (Plume 2a) est RÉSOLUBLE.
Modèle : le joueur marche (140 px/s = 8,75 cases/s) ; la lance reste enflammée FEU secondes après avoir touché un foyer ou un brasero allumé ;
entrer dans une flaque l'éteint. Chaque brasero à allumer doit être atteignable depuis un foyer / un brasero déjà allumé, sans flaque, dans le temps.
Usage : python3 Outils/verifier_feu.py   (lit Scenes/world.tscn, salle Plume2a)"""
import os, re
from collections import deque
FEU, VITESSE = 2.5, 8.75   # secondes de feu ; cases par seconde
racine = os.path.join(os.path.dirname(__file__), "..")
w = open(os.path.join(racine, "Scenes", "world.tscn"), encoding="utf-8").read()
bloc = w.split('name="Plume2a"')[1]
plan = re.findall(r'"([^"]+)"', re.search(r"layout = PackedStringArray\((.*)\)", bloc).group(1))
H, W = len(plan), len(plan[0])
sources = {(x, y) for y in range(H) for x in range(W) if plan[y][x] == 'l'}
cibles = {(x, y) for y in range(H) for x in range(W) if plan[y][x] == 'L'}
libre = lambda x, y: 0 <= x < W and 0 <= y < H and plan[y][x] in '.Tw' and plan[y][x] != 'w'

def temps_pour(src, cib):
    """Plus court trajet (en secondes) d'une case voisine de src à une case voisine de cib, sans flaque ni obstacle."""
    departs = [(src[0] + dx, src[1] + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if libre(src[0] + dx, src[1] + dy)]
    buts = {(cib[0] + dx, cib[1] + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if libre(cib[0] + dx, cib[1] + dy)}
    vus = {d: 0 for d in departs}; file = deque(departs)
    while file:
        c = file.popleft()
        if c in buts: return vus[c] / VITESSE + 0.35   # + le coup de lance
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + dx, c[1] + dy)
            if libre(*n) and n not in vus: vus[n] = vus[c] + 1; file.append(n)
    return None

allumes = set(sources); restant = set(cibles); ordre = []
while restant:
    prochain = None
    for c in sorted(restant):
        meilleur = min((t for s in allumes if (t := temps_pour(s, c)) is not None), default=None)
        if meilleur is not None and meilleur <= FEU and (prochain is None or meilleur < prochain[1]): prochain = (c, meilleur)
    if prochain is None:
        print("NON RÉSOLUBLE : braseros inatteignables dans le temps :", sorted(restant)); raise SystemExit(1)
    allumes.add(prochain[0]); restant.discard(prochain[0]); ordre.append(prochain)
print("RÉSOLUBLE. Ordre possible (brasero, secondes du trajet) :", [(c, round(t, 1)) for c, t in ordre])
# sans relais (depuis un foyer seulement) : combien de braseros sont atteignables ?
direct = [c for c in sorted(cibles) if any((t := temps_pour(s, c)) is not None and t <= FEU for s in sources)]
print("Atteignables directement depuis un foyer :", direct, "(il faut donc des relais pour les autres)")
