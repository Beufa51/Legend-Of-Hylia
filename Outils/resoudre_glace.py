"""Outil de développement : SOLVEUR des salles de glace (mêmes règles que room.gd, player.gd, bloc.gd).
Usage : python3 Outils/resoudre_glace.py   -> vérifie PlumeD3a, D3b, D3c de Scenes/aile_droite.tscn et affiche la solution la plus courte.
Coups : H B G D = glisser/marcher vers le haut, bas, gauche, droite ; pousseX = pousser un bloc ; cristalX = frapper le cristal."""
from collections import deque
DIRS = {'H': (0, -1), 'B': (0, 1), 'G': (-1, 0), 'D': (1, 0)}
SOL = set(".TPFG")      # sol normal (marchable)
def glisser(plan, c, d, bloquee):
    """Depuis la case de glace c, glisse en d. Renvoie la case d'arrivée."""
    while True:
        n = (c[0] + d[0], c[1] + d[1])
        if bloquee(n): return c
        if plan[n[1]][n[0]] == 'i': c = n; continue
        return n   # sol normal : on sort de la glace
def resoudre(plan, depart, buts, plots_init=None, maxi=200000):
    H, W = len(plan), len(plan[0])
    blocs0 = frozenset((x, y) for y in range(H) for x in range(W) if plan[y][x] == 'X')
    def lettre(c):
        x, y = c
        if not (0 <= x < W and 0 <= y < H): return '#'
        return plan[y][x]
    def sol_sous(c):   # ce qu'il y a sous un bloc / sous une case
        l = lettre(c); return 'i' if l == 'i' else ('.' if l in SOL or l == 'X' else l)
    def bloquee_f(blocs, orange):
        def f(c):
            l = lettre(c)
            if l in '#VSOBK~': return True
            if c in blocs: return True
            if l == 'o' and orange: return True
            if l == 'u' and not orange: return True
            return False
        return f
    plan2 = [list(r) for r in plan]
    for (x, y) in blocs0:  # sous les blocs : glace si un voisin... on écrit 'i' dans le plan si le bloc est sur la glace (lettre 'Y' = bloc sur glace)
        pass
    depart_etat = (depart, blocs0, True)
    vus = {depart_etat: None}; file = deque([depart_etat])
    while file:
        etat = file.popleft(); p, blocs, orange = etat
        if p in buts:
            chemin = []
            while vus[etat] is not None:
                etat, m = vus[etat]; chemin.append(m)
            return chemin[::-1]
        bl = bloquee_f(blocs, orange)
        sur_glace = sol_sous(p) == 'i'
        suivants = []
        for k, d in DIRS.items():
            n = (p[0] + d[0], p[1] + d[1])
            if n in blocs:   # pousser le bloc
                b = n; nb = (b[0] + d[0], b[1] + d[1])
                if bl(nb): continue
                nouv = set(blocs); nouv.discard(b)
                # le bloc avance d'une case, puis glisse tant qu'il est sur la glace
                while True:
                    b = nb
                    if sol_sous(b) != 'i': break
                    nb = (b[0] + d[0], b[1] + d[1])
                    if bl(nb) or nb in nouv: break
                nouv.add(b)
                suivants.append(((p, frozenset(nouv), orange), 'pousse' + k))
                continue
            if lettre(n) == 'K':   # frapper le cristal (commute les plots) si on est à côté
                # (seulement si aucun plot ne se lèverait sous le joueur : simplification)
                suivants.append(((p, blocs, not orange), 'cristal' + k))
                continue
            if bl(n): continue
            if sur_glace or sol_sous(n) == 'i':
                if sol_sous(n) == 'i':
                    arr = glisser(plan, n, d, bl)
                else:
                    arr = n
                suivants.append(((arr, blocs, orange), k))
            else:
                suivants.append(((n, blocs, orange), k))
        for e, m in suivants:
            if e not in vus:
                vus[e] = (etat, m); file.append(e)
        if len(vus) > maxi: return None
    return None
def lire(lignes): return [l for l in lignes]


if __name__ == "__main__":
    import os, re
    racine = os.path.join(os.path.dirname(__file__), "..")
    w = open(os.path.join(racine, "Scenes", "aile_droite.tscn"), encoding="utf-8").read()
    for nom, buts in [("PlumeD3a", {(11, 2), (12, 2), (13, 2)}), ("PlumeD3b", {(11, 2), (12, 2), (13, 2)}), ("PlumeD3c", {(12, 4)})]:
        bloc = w.split('name="%s"' % nom)[1]
        plan = re.findall(r'"([^"]+)"', re.search(r"layout = PackedStringArray\((.*)\)", bloc).group(1))
        plan = [l.replace("V", "#").replace("S", "#").replace("O", "#") if i >= 11 else l for i, l in enumerate(plan)]
        solution = resoudre(plan, (12, 11), buts)
        print(nom, ":", "AUCUNE SOLUTION !" if solution is None else "%d coups %s" % (len(solution), solution))
