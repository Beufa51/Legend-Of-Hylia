"""Outil de développement : cherche, au hasard, des variantes PLUS COURTES et plus lisibles de la plume D5b (reflet + plots).
Part du plan actuel (aile_droite.tscn), déplace reflet / dalles / cristal / barrières, garde seulement les plans
« impossibles sans le cristal » et classe par nombre de coups puis nombre de changements de direction.
Usage : python3 Outils/chercher_d5b.py [essais]"""
import random, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from resoudre_d5 import resoudre, compresser, plan_de

base = [list(l) for l in plan_de("PlumeD5b")]
H, W = len(base), len(base[0])

def variante(rng):
    p = [r[:] for r in base]
    # on efface les éléments mobiles
    for y in range(H):
        for x in range(W):
            if p[y][x] in 'raKou': p[y][x] = '.'
    # poche du reflet : colonnes 2-8, rangées 2-5 ; barrière orange en colonne 9 (hauteur variable)
    haut = rng.choice([2, 3, 4]); bas = rng.choice([4, 5])
    for y in range(haut, bas + 1): p[y][9] = 'o'
    r = (rng.randint(3, 8), rng.randint(2, 5)); p[r[1]][r[0]] = 'r'
    pad_r = (rng.randint(2, 8), rng.randint(2, 5))
    if pad_r == r: return None
    # dalle du joueur dans la moitié basse/droite
    pad_j = (rng.randint(12, 21), rng.randint(8, 10))
    p[pad_r[1]][pad_r[0]] = 'a'; p[pad_j[1]][pad_j[0]] = 'a'
    # cristal sur le chemin du joueur
    k = (rng.randint(10, 20), rng.randint(8, 9))
    if p[k[1]][k[0]] != '.' or k == pad_j: return None
    p[k[1]][k[0]] = 'K'
    # barrière bleue (rangée 7 ou 8) sur une partie de la largeur
    ry = rng.choice([7, 8]); x0 = rng.randint(11, 15); x1 = rng.randint(x0 + 4, 22)
    for x in range(x0, x1 + 1):
        if p[ry][x] == '.': p[ry][x] = 'u'
    return [''.join(r) for r in p], pad_r, pad_j

def tourne(ch):
    return sum(1 for a, b in zip(ch, ch[1:]) if a != b)

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 400
    rng = random.Random(7); res = []
    for _ in range(n):
        v = variante(rng)
        if not v: continue
        plan, pr, pj = v
        but = lambda e, t, pr=pr, pj=pj: e['r'] is not None and {e['j'], e['r']} == {pr, pj}
        ch = resoudre(plan, (12, 11), but, maxi=150_000)
        if not ch: continue
        sans = resoudre([l.replace('K', '#') for l in plan], (12, 11), but, maxi=150_000)
        if sans is not None: continue
        res.append((len(ch), tourne(ch), plan, pr, pj, ch))
    res.sort(key=lambda t: (t[0] + t[1], t[0]))
    for t in res[:5]:
        print(t[0], "coups,", t[1], "virages", compresser(t[5]), "reflet-dalle", t[3], "joueur-dalle", t[4])
        print("\n".join(t[2])); print()
    print(len(res), "variantes valides sur", n)
