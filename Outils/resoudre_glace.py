"""Outil de développement : SOLVEUR des salles de glace (mêmes règles que room.gd, player.gd, bloc.gd).
Usage : python3 Outils/resoudre_glace.py   -> vérifie PlumeD3a, D3b, D3c de Scenes/aile_droite.tscn et affiche la solution la plus courte.

Règles simulées :
- glace `i` (et `p` = marque gelée) : on glisse tout droit jusqu'à un obstacle ; une case libre NON glacée (sol, marque P, plot baissé) arrête dessus ;
- bloc `X` : poussé d'une case, puis il glisse tant qu'il est sur la glace et que la case suivante est libre ;
- plots `o` (orange, levé au départ) / `u` (bleu, baissé) : le cristal `K` (frappé depuis une case voisine) les inverse ;
  un plot levé bloque, un plot baissé est du sol (on s'arrête dessus). Simplification : on refuse de frapper si un plot doit se lever sous le joueur ou un bloc ;
- marques `P` / `p` : toutes couvertes par un bloc = la porte `D` s'ouvre (et reste ouverte).
Coups : H B G D = glisser/marcher ; pousseX = pousser un bloc ; cristal = frapper le cristal."""
from collections import deque

DIRS = {'H': (0, -1), 'B': (0, 1), 'G': (-1, 0), 'D': (1, 0)}
MURS = set('#VSOBK~kcIR')


def resoudre(plan, depart, buts, maxi=400000, sans=None):
    """plan : liste de chaînes. sans : lettre à remplacer avant de chercher (ex. 'X' -> glace, 'K' -> mur) pour prouver qu'elle est nécessaire."""
    plan = [list(r) for r in plan]
    H, W = len(plan), len(plan[0])
    if sans == 'X':
        plan = [['i' if c == 'X' else c for c in r] for r in plan]
    if sans == 'K':
        plan = [['#' if c == 'K' else c for c in r] for r in plan]
    blocs0 = frozenset((x, y) for y in range(H) for x in range(W) if plan[y][x] == 'X')
    marques = [(x, y) for y in range(H) for x in range(W) if plan[y][x] in 'Pp']
    portes = {(x, y) for y in range(H) for x in range(W) if plan[y][x] == 'D'}
    sous_bloc = {}   # la case de départ d'un bloc : sol normal (comme dans le jeu)

    def lettre(c):
        x, y = c
        if not (0 <= x < W and 0 <= y < H): return '#'
        return plan[y][x]

    def glace(c):
        return lettre(c) in 'ip'

    def bloquee(c, blocs, orange, ouvert):
        l = lettre(c)
        if l in MURS: return True
        if c in blocs: return True
        if l == 'o' and orange: return True
        if l == 'u' and not orange: return True
        if c in portes and not ouvert: return True
        return False

    def plots_qui_montent(orange):
        return {(x, y) for y in range(H) for x in range(W) if plan[y][x] == ('u' if orange else 'o')}

    debut = (depart, blocs0, True, not marques)
    vus = {debut: None}
    file = deque([debut])
    while file:
        etat = file.popleft()
        p, blocs, orange, ouvert = etat
        if p in buts and (ouvert or not portes):
            chemin = []
            while vus[etat] is not None:
                etat, m = vus[etat]
                chemin.append(m)
            return chemin[::-1]
        suivants = []
        for k, d in DIRS.items():
            n = (p[0] + d[0], p[1] + d[1])
            if n in blocs:   # pousser le bloc
                b, nb = n, (n[0] + d[0], n[1] + d[1])
                if bloquee(nb, blocs, orange, ouvert): continue
                autres = set(blocs) - {b}
                b = nb
                while glace(b):
                    nb = (b[0] + d[0], b[1] + d[1])
                    if bloquee(nb, autres, orange, ouvert) or nb == p: break
                    b = nb
                nouv = frozenset(autres | {b})
                ouv = ouvert or all(m in nouv for m in marques)
                suivants.append(((p, nouv, orange, ouv), 'pousse' + k))
                continue
            if lettre(n) == 'K':   # frapper le cristal
                montent = plots_qui_montent(orange)
                if p in montent or montent & set(blocs): continue
                suivants.append(((p, blocs, not orange, ouvert), 'cristal'))
                continue
            if bloquee(n, blocs, orange, ouvert): continue
            arr = n
            while glace(arr):   # on glisse tant qu'on est sur la glace
                nn = (arr[0] + d[0], arr[1] + d[1])
                if bloquee(nn, blocs, orange, ouvert): break
                arr = nn
            suivants.append(((arr, blocs, orange, ouvert), k))
        for e, m in suivants:
            if e not in vus:
                vus[e] = (etat, m)
                file.append(e)
        if len(vus) > maxi: return None
    return None


if __name__ == "__main__":
    import os, re
    racine = os.path.join(os.path.dirname(__file__), "..")
    w = open(os.path.join(racine, "Scenes", "aile_droite.tscn"), encoding="utf-8").read()
    for nom, buts, cle in [("PlumeD3a", {(11, 2), (12, 2), (13, 2)}, None), ("PlumeD3b", {(11, 2), (12, 2), (13, 2)}, 'X'),
                           ("PlumeD3c", {(11, 3), (12, 3), (13, 3)}, "K")]:
        bloc = w.split('name="%s"' % nom)[1]
        plan = re.findall(r'"([^"]+)"', re.search(r"layout = PackedStringArray\((.*?)\)\n", bloc).group(1))
        solution = resoudre(plan, (12, 11), buts)
        texte = "AUCUNE SOLUTION !" if solution is None else "%d coups %s" % (len(solution), solution)
        if cle:
            sans = resoudre(plan, (12, 11), buts, sans=cle)
            texte += " | sans %s : %s" % (cle, "impossible (bien)" if sans is None else "POSSIBLE en %d coups (mauvais)" % len(sans))
        print(nom, ":", texte)
