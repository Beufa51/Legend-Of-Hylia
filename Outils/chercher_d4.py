"""Outil de développement : cherche des plans PLUS COURTS et plus lisibles pour les salles du reflet (plume D4).
Pour chaque plan candidat : solution la plus courte (BFS) + part des états ATTEIGNABLES SANS ISSUE (cul-de-sac = frustration).
Usage : python3 Outils/chercher_d4.py <4b|4c|4d> [essais]   (écrit les meilleurs plans à l'écran)"""
import random, sys, os
from collections import deque
sys.path.insert(0, os.path.dirname(__file__))
from resoudre_reflet import DIRS, SOLIDES

def graphe(plan, depart, but):
    H, W = len(plan), len(plan[0])
    trouve = lambda c: [(x, y) for y in range(H) for x in range(W) if plan[y][x] == c]
    r0 = trouve('r')[0]; boutons = set(trouve('P'))
    def bloquee(c, ouvert):
        x, y = c
        if not (0 <= x < W and 0 <= y < H): return True
        l = plan[y][x]
        return l in SOLIDES or l == 'D' or (l == 'H' and not ouvert)
    e0 = (depart, r0, False); vus = {e0: None}; file = deque([e0]); inv = {}; buts = []
    while file:
        e = file.popleft(); j, r, o = e
        if but(j, r, o): buts.append(e)
        for k, (dx, dy) in DIRS.items():
            nj = (j[0] + dx, j[1] + dy)
            if bloquee(nj, o): continue
            nr = (r[0] - dx, r[1] + dy)
            if bloquee(nr, o): nr = r
            n = (nj, nr, o or nr in boutons)
            inv.setdefault(n, []).append(e)
            if n not in vus: vus[n] = (e, k); file.append(n)
        if len(vus) > 300000: return None
    if not buts: return None
    # longueur de la solution la plus courte
    but0 = None
    for b in buts:
        n = 0; e = b
        while vus[e] is not None: e = vus[e][0]; n += 1
        if but0 is None or n < but0[0]: but0 = (n, b)
    bons = set(buts); file = deque(buts)
    while file:
        e = file.popleft()
        for p in inv.get(e, []):
            if p not in bons: bons.add(p); file.append(p)
    morts = len(vus) - len(bons & set(vus))
    return but0[0], morts / len(vus), len(vus)

def vide():
    g = [['#'] * 25 for _ in range(14)]
    for y in range(2, 12):
        for x in range(2, 23): g[y][x] = '.'
    for y in (12, 13):
        for x in (11, 12, 13): g[y][x] = '.'
    return g

def fin(g): return [''.join(r) for r in g]

def candidat(salle, rng):
    g = vide()
    libres = lambda: [(x, y) for y in range(3, 11) for x in range(2, 23) if g[y][x] == '.']
    if salle == '4d':
        for x in (11, 12, 13): g[0][x] = '#'; g[1][x] = '#'
        for y in range(2, 6):
            for x in range(2, 23):
                if not (9 <= x <= 15): g[y][x] = '#'
        for y in range(2, 5):
            for x in range(9, 16): g[y][x] = '.'
        for x in (11, 12, 13): g[5][x] = 'D'
        for y in range(2, 6):
            for x in range(2, 23):
                if g[y][x] == '.' and not (9 <= x <= 15): g[y][x] = '#'
        # enclos en haut à droite : colonnes 16-22, rangées 6-7, fermé par herse en rangée 8
        for x in range(16, 23): g[8][x] = '#'
        for x in (18, 19, 20): g[8][x] = 'H'
        for y in (6, 7): g[y][16] = '#'
        pad_e = (rng.randint(17, 22), rng.choice([6, 7])); g[pad_e[1]][pad_e[0]] = 'a'
        p = (rng.randint(2, 5), rng.randint(6, 10)); g[p[1]][p[0]] = 'P'
        pad = rng.choice([c for c in libres() if c[1] >= 6 and c[0] < 16]); g[pad[1]][pad[0]] = 'a'
        r = rng.choice([c for c in libres() if c[1] >= 8]); g[r[1]][r[0]] = 'r'
        for _ in range(rng.randint(2, 5)):
            c = rng.choice([c for c in libres() if c[1] >= 6 and c != (12, 11)]); g[c[1]][c[0]] = '#'
        return fin(g)
    for x in (11, 12, 13): g[0][x] = 'D' if salle == '4b' else 'H'; g[1][x] = g[0][x]
    if salle == '4b':
        r = rng.choice(libres()); g[r[1]][r[0]] = 'r'
        for c in rng.sample(libres(), 2): g[c[1]][c[0]] = 'a'
        y = rng.randint(3, 6); x0 = rng.randint(3, 16); x1 = x0 + rng.randint(2, 6)
        for x in range(x0, min(x1, 22) + 1):
            if g[y][x] == '.': g[y][x] = '#'
        for c in rng.sample(libres(), rng.randint(0, 2)): g[c[1]][c[0]] = '#'
    else:  # 4c : bouton dans une niche ouverte à l'est
        cote = rng.choice([0, 1])
        nx = rng.randint(2, 4) if cote == 0 else rng.randint(20, 22); ny = rng.randint(3, 8)
        g[ny][nx] = 'P'
        mur = [(nx, ny - 1), (nx, ny + 1), (nx - 1 if cote == 0 else nx + 1, ny)]
        if cote == 0: mur += [(nx - 1, ny)]
        for (x, y) in mur:
            if 2 <= x <= 22 and 2 <= y <= 11: g[y][x] = '#'
        if cote == 1:
            for x in range(nx, 23):
                if x != nx: g[ny][x] = '#'
        r = rng.choice([c for c in libres() if c[1] >= 5]); g[r[1]][r[0]] = 'r'
        for c in rng.sample(libres(), rng.randint(3, 7)): g[c[1]][c[0]] = '#'
    return fin(g)

if __name__ == '__main__':
    salle = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
    rng = random.Random(11); res = []
    if salle == '4b': but = lambda j, r, o: False
    for _ in range(n):
        try: plan = candidat(salle, rng)
        except IndexError: continue
        H = len(plan)
        pads = {(x, y) for y in range(H) for x in range(25) if plan[y][x] == 'a'}
        if salle == '4c': but = lambda j, r, o: o and j[1] <= 1
        else: but = lambda j, r, o, pads=pads: {j, r} == pads
        if salle != '4c' and len(pads) != 2: continue
        try: g = graphe(plan, (12, 11), but)
        except Exception: continue
        if not g: continue
        lg, morts, nb = g
        if not (7 <= lg <= (11 if salle == '4b' else 20)): continue
        res.append((morts, lg, nb, plan))
    res.sort(key=lambda t: (round(t[0], 2), -t[1]))
    for t in res[:4]:
        print("coups", t[1], "| états sans issue %.0f%%" % (100 * t[0]), "| états", t[2]); print("\n".join(t[3])); print()
    print(len(res), "candidats valides")
