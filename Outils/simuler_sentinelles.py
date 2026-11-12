"""Outil de conception : simule le CÔNE de vision des sentinelles (même règle que room.gd::_voit / _portee_libre).
Usage : python3 Outils/simuler_sentinelles.py          -> vérifie les salles de la plume 4 (lues dans Scenes/world.tscn)
Une case est « dangereuse » si l'un de ses points (centre + 4 coins rentrés de 3 px) est vu par une sentinelle.
On cherche ensuite un passage case par case (le joueur avance d'1 case ou attend toutes les dt secondes)."""
import math, os, re

TUILE = 16
PORTEE = 7 * TUILE          # = room.gd PORTEE_REGARD * TUILE
DEMI = math.radians(26)     # = room.gd DEMI_ANGLE (demi-ouverture du cône)
VITESSE = 7.0               # = sentinelle.gd VITESSE_ROTATION (radians par seconde)
OPAQUE = "#SOBVXCKLDR12345^v<>MNY"
DIRS = {'^': (0, -1), 'v': (0, 1), '<': (-1, 0), '>': (1, 0)}
ORDRE = ['^', '>', 'v', '<']   # rotation horaire
RACINE = os.path.join(os.path.dirname(__file__), "..")


def lire_salles():
    txt = open(os.path.join(RACINE, "Scenes", "world.tscn"), encoding="utf-8").read()
    salles = {}
    for bloc in txt.split("[node ")[1:]:
        nom = re.search(r'name="([^"]+)"', bloc).group(1)
        m = re.search(r'layout = PackedStringArray\((.*)\)', bloc)
        if m:
            g = re.findall(r'"([^"]*)"', m.group(1))
            per = re.search(r'periodes_sentinelles = PackedFloat32Array\(([^)]*)\)', bloc)
            salles[nom] = (g, [float(v) for v in per.group(1).split(",")] if per else [])
    return salles


def opaque(g, cx, cy, ignore=None):
    if (cx, cy) == ignore:
        return False
    return not (0 <= cy < len(g) and 0 <= cx < len(g[0])) or g[cy][cx] in OPAQUE


def portee_libre(g, oeil, angle, case_s):
    d = 0.0
    while d < PORTEE:
        d += 2.0
        px, py = oeil[0] + math.cos(angle) * d, oeil[1] + math.sin(angle) * d
        if opaque(g, math.floor(px / TUILE), math.floor(py / TUILE), case_s):
            return d - 2.0
    return PORTEE


def voit(g, s, angle, p):
    oeil = (s[0] * TUILE + 8, s[1] * TUILE + 8)
    vx, vy = p[0] - oeil[0], p[1] - oeil[1]
    dist = math.hypot(vx, vy)
    if dist > PORTEE:
        return False
    diff = (math.atan2(vy, vx) - angle + math.pi) % (2 * math.pi) - math.pi
    if abs(diff) > DEMI:
        return False
    return portee_libre(g, oeil, math.atan2(vy, vx), s) >= dist - 1


def cases_vues(g, sents_angles):
    vues = set()
    for y in range(len(g)):
        for x in range(len(g[0])):
            if opaque(g, x, y):
                continue
            pts = [(x * 16 + 8, y * 16 + 8)] + [(x * 16 + a, y * 16 + b) for a in (3, 13) for b in (3, 13)]
            if any(voit(g, s, ang, p) for s, ang in sents_angles for p in pts):
                vues.add((x, y))
    return vues


def sentinelles(g):
    return [((x, y), c) for y, r in enumerate(g) for x, c in enumerate(r) if c in DIRS]


def angle_a(c0, periode, t):
    """Angle du regard à l'instant t (rotation douce d'un quart de tour toutes les `periode` s)."""
    a0 = math.atan2(DIRS[c0][1], DIRS[c0][0])
    if periode <= 0:
        return a0
    k = int(t // periode)
    debut = a0 + k * math.pi / 2
    return debut - math.pi / 2 + min(math.pi / 2, (t - k * periode) * VITESSE) if k > 0 else a0


def montre(g, vues):
    for y, r in enumerate(g):
        print(''.join('*' if (x, y) in vues else c for x, c in enumerate(r)))
    print()


def espace_temps(g, periodes, debut, fin, dt=0.25, tmax=40.0, angles_fixes=None):
    sents = sentinelles(g)
    cache = {}
    def cov(k):
        if k not in cache:
            vu = set()
            for sub in range(4):
                t = (k + sub / 4) * dt
                sa = [(s, angles_fixes.get(s) if angles_fixes and s in angles_fixes else angle_a(c, periodes[i] if i < len(periodes) else 0, t))
                      for i, (s, c) in enumerate(sents)]
                vu |= cases_vues(g, sa)
            cache[k] = vu
        return cache[k]
    front = {debut}; k = 0
    while k * dt < tmax:
        nxt = set()
        for c in front:
            for d in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
                n = (c[0] + d[0], c[1] + d[1])
                if opaque(g, *n) or n in cov(k + 1):
                    continue
                nxt.add(n)
        k += 1; front = nxt
        if fin in front:
            return k * dt
        if not front:
            return None
    return None


if __name__ == "__main__":
    salles = lire_salles()
    for nom in ("Plume4a", "Plume4b", "Plume4c", "Plume4d"):
        g, per = salles[nom]
        sa = [(s, angle_a(c, 0, 0)) for s, c in sentinelles(g)]
        print(nom, "(regard de départ)")
        montre(g, cases_vues(g, sa))
