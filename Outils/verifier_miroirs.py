# Vérifie les salles à miroirs de la plume 5 (aile gauche) en lisant Scenes/world.tscn.
# Mêmes règles que room.gd::_tracer_rayon : le rayon part du soleil R (vers la case de sol voisine), M = « / », N = « \ »,
# chaque coup de lance retourne un miroir. Pour chaque salle : toutes les orientations possibles sont essayées.
# Affiche : solutions, coups minimum, miroirs utiles / inutiles, et si la stratégie « retourner le dernier miroir
# touché » suffit (si oui, l'énigme se résout sans réfléchir).
# Usage : python3 Outils/verifier_miroirs.py
import itertools, re, os

ICI = os.path.dirname(os.path.abspath(__file__))
OPAQUES = set("#SOBVXDHCRWLKQJE^v<>123456")


def salles():
    txt = open(os.path.join(ICI, "..", "Scenes", "world.tscn"), encoding="utf-8").read()
    for bloc in txt.split("[node ")[1:]:
        nom = re.search(r'name="([^"]+)"', bloc).group(1)
        m = re.search(r'layout = PackedStringArray\((.*)\)', bloc)
        if m and "R" in m.group(1) and nom.startswith("Plume5"):
            yield nom, re.findall(r'"([^"]*)"', m.group(1))


def tracer(g, miroirs, etat, bloc_ote):
    soleil = [(x, y) for y, r in enumerate(g) for x, c in enumerate(r) if c == "R"][0]
    d = next((dx, dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
             if 0 <= soleil[1] + dy < len(g) and 0 <= soleil[0] + dx < len(g[0]) and g[soleil[1] + dy][soleil[0] + dx] != "#")
    x, y = soleil
    touches, vus = [], set()
    for _ in range(300):
        x += d[0]; y += d[1]
        if not (0 <= y < len(g) and 0 <= x < len(g[0])):
            return False, touches
        if (x, y) in miroirs:
            touches.append((x, y))
            d = (-d[1], -d[0]) if etat[miroirs[(x, y)]] else (d[1], d[0])
            if (x, y, d) in vus:
                return False, touches
            vus.add((x, y, d))
            continue
        c = g[y][x]
        if c in "YC":                       # réceptacle ou statue qui chante au soleil
            return True, touches
        if c == "X" and bloc_ote:
            continue
        if c == "H":                        # grille ouverte par le bouton (5c)
            continue
        if c in OPAQUES:
            return False, touches
    return False, touches


def glouton(g, miroirs, etat, bloc_ote):
    etat = list(etat); vus = set()
    for coups in range(30):
        ok, t = tracer(g, miroirs, etat, bloc_ote)
        if ok:
            return coups
        if not t or tuple(etat) in vus:
            return None
        vus.add(tuple(etat))
        i = miroirs[t[-1]]; etat[i] = not etat[i]
    return None


for nom, g in salles():
    liste = [(x, y) for y, r in enumerate(g) for x, c in enumerate(r) if c in "MN"]
    miroirs = {m: i for i, m in enumerate(liste)}
    depart = [g[y][x] == "M" for x, y in liste]
    bloc = any("X" in r for r in g)
    sols = []
    for etat in itertools.product([True, False], repeat=len(liste)):
        ok, t = tracer(g, miroirs, etat, True)
        if ok:
            sols.append((sum(a != b for a, b in zip(etat, depart)), etat, t))
    sols.sort()
    utiles = set(m for s in sols for m in s[2])
    print(f"{nom}: {len(liste)} miroirs, {len(sols)} solution(s)" + (" (bloc dégagé)" if bloc else ""))
    if sols:
        print(f"   coups minimum : {sols[0][0]}   miroirs inutiles : {sorted(set(liste) - utiles) or 'aucun'}")
        gl = glouton(g, miroirs, depart, True)
        print("   « retourner le dernier miroir touché » : " + ("suffit (%d coups)" % gl if gl is not None else "NE SUFFIT PAS (il faut réfléchir)"))
    else:
        print("   AUCUNE SOLUTION !")
