"""Outil de conception : simule le regard des sentinelles (même règle que room.gd::_cases_vues).
montre(plan) affiche les cases vues (*) ; espace_temps(plan, periodes, depart, arrivee) cherche un passage sans être vu."""
import math
# Simulateur du regard des sentinelles (même règle que room.gd)
R = 7
OPAQUE = "#SOBVXCKLD12345^v<>"
DIRS = {'^': (0, -1), 'v': (0, 1), '<': (-1, 0), '>': (1, 0)}
def opaque(g, x, y):
    return not (0 <= y < len(g) and 0 <= x < len(g[0])) or g[y][x] in OPAQUE
def cone(g, s, d):
    vus = set(); sx, sy = s; dx, dy = d; px, py = -dy, dx
    for dist in range(1, R + 1):
        half = min(2, dist // 2)
        for o in range(-half, half + 1):
            cx, cy = sx + dx * dist + px * o, sy + dy * dist + py * o
            if opaque(g, cx, cy): continue
            n = dist * 4; ok = True
            for i in range(1, n):
                t = i / n
                x = math.floor(sx + (cx - sx) * t + 0.5); y = math.floor(sy + (cy - sy) * t + 0.5)
                if (x, y) in ((sx, sy), (cx, cy)): continue
                if opaque(g, x, y): ok = False; break
            if ok: vus.add((cx, cy))
    return vus
def montre(g, dirs_override=None):
    g = [list(r) for r in g]; vus = set()
    for y, r in enumerate(g):
        for x, c in enumerate(r):
            if c in DIRS:
                d = DIRS[c] if not dirs_override else dirs_override.get((x, y), DIRS[c])
                vus |= cone(g, (x, y), d)
    for (x, y) in vus: g[y][x] = '*' if g[y][x] == '.' else g[y][x].lower() if g[y][x].isalpha() else '*'
    print('\n'.join(''.join(r) for r in g)); print()
    return vus

ORDRE = ['^', '>', 'v', '<']   # rotation horaire
def dir_a(c0, periode, t):
    if periode <= 0: return DIRS[c0]
    return DIRS[ORDRE[(ORDRE.index(c0) + int(t // periode)) % 4]]
def couverture(g, periodes, t):
    sents = [(x, y, c) for y, r in enumerate(g) for x, c in enumerate(r) if c in DIRS]
    vus = set()
    for i, (x, y, c) in enumerate(sents):
        vus |= cone(g, (x, y), dir_a(c, periodes[i] if i < len(periodes) else 0, t))
    return vus
def chemin(g, interdit, debut, fin):
    from collections import deque
    q = deque([debut]); vu = {debut}
    while q:
        c = q.popleft()
        if c == fin: return True
        for d in DIRS.values():
            n = (c[0] + d[0], c[1] + d[1])
            if n in vu or opaque(g, *n) or n in interdit: continue
            vu.add(n); q.append(n)
    return False

def espace_temps(g, periodes, debut, fin, dt=0.25, tmax=48.0, t0=0.0):
    """Le joueur avance d'1 case (ou attend) toutes les dt secondes. Renvoie la durée minimale, ou None."""
    import functools
    cache = {}
    def cov(k):
        if k not in cache: cache[k] = couverture(g, periodes, t0 + k * dt) | couverture(g, periodes, t0 + k * dt + dt * 0.99)
        return cache[k]
    front = {debut}; k = 0
    while k * dt < tmax:
        nxt = set()
        for c in front:
            for d in [(0, 0)] + list(DIRS.values()):
                n = (c[0] + d[0], c[1] + d[1])
                if opaque(g, *n) or n in cov(k + 1): continue
                nxt.add(n)
        k += 1; front = nxt
        if fin in front: return k * dt
        if not front: return None
    return None
