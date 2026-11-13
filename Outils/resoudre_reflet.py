"""Outil de développement : SOLVEUR des salles du REFLET (plume D4 de l'aile droite), modèle par cases :
chaque coup = le joueur avance d'une case ; le reflet avance d'une case dans la direction MIROIR (gauche <-> droite)
s'il n'est pas bloqué. Usage : python3 Outils/resoudre_reflet.py (lit Scenes/aile_droite.tscn ; à relancer après toute modif)."""
from collections import deque
DIRS = {'H': (0, -1), 'B': (0, 1), 'G': (-1, 0), 'D': (1, 0)}
SOLIDES = set('#SOBVKXQJ~R')
def resoudre(plan, depart, but=None, maxi=400000):
    H, W = len(plan), len(plan[0])
    trouve = lambda c: [(x, y) for y in range(H) for x in range(W) if plan[y][x] == c]
    reflet0 = trouve('r')[0]
    pads = set(trouve('a')); boutons = set(trouve('P'))
    sorties = set((x, y) for (x, y) in [(x, 0) for x in range(W)] if plan[0][x] in '.')
    def bloquee(c, ouvert):
        x, y = c
        if not (0 <= x < W and 0 <= y < H): return True
        l = plan[y][x]
        if l in SOLIDES: return True
        if l == 'H' and not ouvert: return True
        if l == 'D': return True     # porte de sortie (s'ouvre avec les dalles du reflet)
        return False
    e0 = (depart, reflet0, False)
    vus = {e0: None}; file = deque([e0])
    while file:
        e = file.popleft(); j, r, ouvert = e
        if (but(j, r, ouvert) if but else (pads and {j, r} == pads)):
            ch = []
            while vus[e] is not None: e, m = vus[e]; ch.append(m)
            return ch[::-1]
        for k, (dx, dy) in DIRS.items():
            nj = (j[0] + dx, j[1] + dy)
            if bloquee(nj, ouvert): continue
            nr = (r[0] - dx, r[1] + dy)
            if bloquee(nr, ouvert): nr = r
            o = ouvert or (nr in boutons)
            n = (nj, nr, o)
            if n not in vus: vus[n] = (e, k); file.append(n)
        if len(vus) > maxi: return None
    return None
def compresser(ch):
    out = []
    for m in ch:
        if out and out[-1][0] == m: out[-1] = (m, out[-1][1] + 1)
        else: out.append((m, 1))
    return ' '.join('%s%d' % (m, n) for m, n in out)


if __name__ == "__main__":
    import os, re
    racine = os.path.join(os.path.dirname(__file__), "..")
    w = open(os.path.join(racine, "Scenes", "aile_droite.tscn"), encoding="utf-8").read()
    sortie = lambda j, r, o: o and j[1] <= 1
    for nom, but in [("PlumeD4a", None), ("PlumeD4b", None), ("PlumeD4c", sortie), ("PlumeD4d", None)]:
        bloc = w.split('name="%s"' % nom)[1]
        plan = re.findall(r'"([^"]+)"', re.search(r"layout = PackedStringArray\((.*)\)", bloc).group(1))
        ch = resoudre(plan, (12, 11), but)
        print(nom, ":", "AUCUNE SOLUTION !" if ch is None else "%d coups  %s" % (len(ch), compresser(ch)))
