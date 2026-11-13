"""Outil de développement : SOLVEUR GÉNÉRAL de l'aile droite (plume D5), modèle par cases.
Gère : murs, glace (i), blocs (X, glissent sur la glace), plots (o/u) + cristal commutateur (K), boutons (P, enfoncés par
un bloc ou le reflet) qui ouvrent les herses H, coffre (Q, donne la clé) + porte à serrure (E), reflet (r, gestes
gauche/droite inversés) + dalles du reflet (a), dalles de couleur (z, chaque passage les retourne).
Usage : python3 Outils/resoudre_d5.py   (lit Scenes/aile_droite.tscn, vérifie PlumeD5a..e ; à relancer après toute modif)
Coups : H B G D = aller vers le haut, bas, gauche, droite (sur la glace : glisser). Frapper un cristal, ouvrir un coffre,
ouvrir une serrure = « aller » vers lui (on reste sur place)."""
from collections import deque

DIRS = {'H': (0, -1), 'B': (0, 1), 'G': (-1, 0), 'D': (1, 0)}
SOLIDES = set('#SOBVJ~RCYMN')          # murs et objets qui bloquent toujours
MARCHABLE = set('.TFGPiWarzou')        # (o/u : seulement quand le plot est baissé)


def resoudre(plan, depart, but, maxi=3_000_000):
    H, W = len(plan), len(plan[0])
    cases = lambda c: [(x, y) for y in range(H) for x in range(W) if plan[y][x] == c]
    blocs0 = frozenset(cases('X'))
    reflet0 = (cases('r') or [None])[0]
    boutons = frozenset(cases('P'))
    dalles = {c: i for i, c in enumerate(cases('z'))}
    tout = (1 << len(dalles)) - 1
    lettre = lambda c: plan[c[1]][c[0]] if 0 <= c[0] < W and 0 <= c[1] < H else '#'
    glace = lambda c: lettre(c) == 'i'

    def bloquee(c, e, pour_reflet=False):
        l = lettre(c)
        if l in SOLIDES or l == 'K' or l == 'Q' or l == 'D': return True
        if l == 'H' and not e['h']: return True
        if l == 'E' and not e['e']: return True
        if l == 'o' and e['orange']: return True
        if l == 'u' and not e['orange']: return True
        if c in e['blocs']: return True
        return False

    def figer(e):
        return (e['j'], e['r'], e['blocs'], e['orange'], e['h'], e['cle'], e['e'], e['z'])

    e0 = dict(j=depart, r=reflet0, blocs=blocs0, orange=True, h=False, cle=False, e=False, z=0)
    vus = {figer(e0): None}
    file = deque([e0])
    while file:
        e = file.popleft()
        if but(e, tout):
            k = figer(e); ch = []
            while vus[k] is not None:
                k, m = vus[k]; ch.append(m)
            return ch[::-1]
        for nom, (dx, dy) in DIRS.items():
            n = dict(e)
            j = e['j']; c = (j[0] + dx, j[1] + dy); l = lettre(c)
            bouge = False
            if l == 'K':
                n['orange'] = not e['orange']
            elif l == 'Q':
                if e['cle']: continue
                n['cle'] = True
            elif l == 'E' and not e['e']:
                if not e['cle']: continue
                n['e'] = True
            elif c in e['blocs']:
                b = (c[0] + dx, c[1] + dy)
                if bloquee(b, e) or (e['r'] is not None and b == e['r']): continue
                while glace(b):
                    s = (b[0] + dx, b[1] + dy)
                    if bloquee(s, e): break
                    b = s
                nb = set(e['blocs']); nb.discard(c); nb.add(b); n['blocs'] = frozenset(nb)
            elif bloquee(c, e):
                continue
            else:
                # marcher (ou glisser) ; les dalles de couleur traversées se retournent
                chemin = [c]
                if glace(c):
                    while True:
                        s = (chemin[-1][0] + dx, chemin[-1][1] + dy)
                        if bloquee(s, e): break
                        chemin.append(s)
                        if not glace(s): break
                n['j'] = chemin[-1]; bouge = True
                z = e['z']
                for p in chemin:
                    if p in dalles: z ^= 1 << dalles[p]
                n['z'] = z
                # le reflet fait le même nombre de pas, gauche/droite inversées
                if e['r'] is not None:
                    r = e['r']
                    for _ in chemin:
                        s = (r[0] - dx, r[1] + dy)
                        if bloquee(s, e, True): break
                        r = s
                    n['r'] = r
            # boutons : tous enfoncés (bloc ou reflet) -> herses ouvertes pour de bon
            if boutons and not n['h'] and all(p in n['blocs'] or p == n['r'] for p in boutons):
                n['h'] = True
            k = figer(n)
            if k not in vus:
                vus[k] = (figer(e), nom); file.append(n)
        if len(vus) > maxi:
            return None
    return None


def compresser(ch):
    out = []
    for m in ch:
        if out and out[-1][0] == m: out[-1] = (m, out[-1][1] + 1)
        else: out.append((m, 1))
    return ' '.join('%s%d' % (m, k) for m, k in out)


def plan_de(nom):
    import os, re
    racine = os.path.join(os.path.dirname(__file__), "..")
    w = open(os.path.join(racine, "Scenes", "aile_droite.tscn"), encoding="utf-8").read()
    bloc = w.split('name="%s"' % nom)[1]
    return re.findall(r'"([^"]+)"', re.search(r"layout = PackedStringArray\((.*)\)", bloc).group(1))


if __name__ == "__main__":
    pads = lambda e, t: e['r'] is not None and {e['j'], e['r']} == {(16, 4), (8, 9)}
    sortie = lambda e, t: e['h'] and e['j'][1] <= 1
    tests = [
        ("PlumeD5b", pads, "K"),              # reflet + plots : impossible sans le cristal
        ("PlumeD5c", sortie, "X"),            # glace + bloc + bouton : impossible sans le bloc
        ("PlumeD5d", lambda e, t: e['z'] == t, "K"),   # dalles + plots : impossible sans le cristal
        ("PlumeD5e", lambda e, t: e['e'], "K"),        # glace + plots + coffre : impossible sans le cristal
    ]
    for nom, but, cle in tests:
        plan = plan_de(nom)
        ch = resoudre(plan, (12, 11), but)
        sans = resoudre([l.replace(cle, '#' if cle == 'K' else 'i') for l in plan], (12, 11), but)
        print(nom, ":", "AUCUNE SOLUTION !" if ch is None else "%d coups  %s" % (len(ch), compresser(ch)),
              "| sans %s : %s" % (cle, "impossible (bien)" if sans is None else "POSSIBLE (%d coups)" % len(sans)))
    print("PlumeD5a : clé + levier + pics (rythme des pics non simulé : vérifier en jeu)")
