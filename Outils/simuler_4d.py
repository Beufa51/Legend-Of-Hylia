"""Outil de conception : vérifie la salle 4d (Plume4d de Scenes/world.tscn) : flamme à gauche + pot sonore à droite + noir.
Règles (mêmes que room.gd) : une flamme n'attire que les sentinelles à moins de PORTEE_FLAMME cases, un bruit que celles à moins de PORTEE_BRUIT.
Vérifie : (1) ni la flamme seule, ni le bruit seul, ni rien ne suffisent ; (2) flamme + bruit = passage ; (3) les temps (à pied / en courant).
Usage : python3 Outils/simuler_4d.py"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import simuler_sentinelles as sim
from collections import deque

sim.OPAQUE += "U"
PORTEE_FLAMME, PORTEE_BRUIT = 9.0, 11.0
MARCHE = 70.0 / 16
COURSE = MARCHE * 1.7
DUREE_BRUIT, DUREE_FLAMME = 3.6, 14.0   # = generer_monde.py : duree_bruit de Plume4d, duree_braseros
ROT = (math.pi / 2) / sim.VITESSE


def axe(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    return (1 if dx > 0 else -1, 0) if abs(dx) >= abs(dy) else (0, 1 if dy > 0 else -1)


def angle_dir(d):
    return math.atan2(d[1], d[0])


def danger(g, sents, flamme, bruit):
    """Cases vues quand `flamme` (case du brasero allumé ou None) et `bruit` (case du pot brisé ou None) sont actifs."""
    sa = []
    for s, c in sents:
        d = sim.DIRS[c]
        if bruit and math.dist(s, bruit) <= PORTEE_BRUIT:
            d = axe(s, bruit)
        elif flamme and math.dist(s, flamme) <= PORTEE_FLAMME:
            d = axe(s, flamme)
        sa.append((s, angle_dir(d)))
    return sim.cases_vues(g, sa)


def voisins(c):
    return [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]


def bfs(g, debut, fins, interdit):
    vu = {debut: 0}; f = deque([debut])
    while f:
        c = f.popleft()
        if c in fins:
            return vu[c]
        for n in voisins(c):
            if n not in vu and not sim.opaque(g, *n) and n not in interdit:
                vu[n] = vu[c] + 1; f.append(n)
    return None


def chemin_fenetre(g, debut, fins, avant, apres, fenetre, v):
    vu = {debut: 0}; f = deque([debut])
    while f:
        c = f.popleft()
        if c in fins:
            return vu[c] / v
        for n in voisins(c):
            if n in vu or sim.opaque(g, *n):
                continue
            t = (vu[c] + 1) / v
            if n in (avant if t < fenetre else apres):
                continue
            vu[n] = vu[c] + 1; f.append(n)
    return None


def main():
    g, _ = sim.lire_salles()["Plume4d"]
    sents = sim.sentinelles(g)
    br = [(x, y) for y, r in enumerate(g) for x, ch in enumerate(r) if ch == "L"]
    pots = [(x, y) for y, r in enumerate(g) for x, ch in enumerate(r) if ch == "U"]
    assert len(br) == 1 and len(pots) == 1 and len(sents) == 2, (br, pots, sents)
    brasero, pot = br[0], pots[0]
    entree, sortie = (12, 11), {(12, 4), (11, 4), (13, 4)}
    ok = True
    for nom, fl, bru in (("rien", None, None), ("flamme seule", brasero, None), ("bruit seul", None, pot)):
        d = danger(g, sents, fl, bru)
        r = bfs(g, entree, sortie, d)
        print("  %-13s : %s" % (nom, "PASSAGE POSSIBLE (erreur)" if r is not None else "aucun chemin sûr (voulu)"))
        ok &= r is None
    d_flamme = danger(g, sents, brasero, None)
    d_rien = danger(g, sents, None, None)
    d_les_deux = danger(g, sents, brasero, pot)
    # 1) jusqu'au brasero : on frappe depuis une case voisine, hors du regard (état « rien »)
    frappe_b = next(c for c in voisins(brasero) if not sim.opaque(g, *c) and c not in d_rien)
    t1 = bfs(g, entree, {frappe_b}, d_rien)
    # 2) du brasero au pot : la flamme est allumée (la sentinelle de gauche regarde à gauche, celle de droite garde le milieu)
    frappe_p = [c for c in voisins(pot) if not sim.opaque(g, *c) and c not in d_flamme and c not in d_les_deux]
    print("  cases de frappe du pot sûres :", frappe_p)
    meilleur = {}
    for fp in frappe_p:
        t2 = bfs(g, frappe_b, {fp}, d_flamme)
        if t2 is None:
            continue
        for nom, v in (("à pied", MARCHE), ("en courant", COURSE)):
            # pendant le bruit on évite les cônes « flamme + bruit » ; ensuite (la sentinelle de droite revient) les cônes « flamme seule »
            t3 = chemin_fenetre(g, fp, sortie, d_les_deux, d_flamme, ROT + DUREE_BRUIT, v)
            flamme_restante = DUREE_FLAMME - t2 / v
            print("    frappe %s %s : brasero -> pot %.1f s ; pot -> passage %s ; flamme restante %.1f s" % (
                fp, nom, t2 / v, "AUCUN chemin" if t3 is None else "%.1f s" % t3, flamme_restante))
            if t3 is not None and (nom not in meilleur or t3 < meilleur[nom]):
                meilleur[nom] = t3
    for nom in ("à pied", "en courant"):
        if nom in meilleur:
            print("  MEILLEUR %s : %.1f s pour une fenêtre de %.1f s (marge %.1f s)" % (nom, meilleur[nom], DUREE_BRUIT + ROT, DUREE_BRUIT + ROT - meilleur[nom]))
    ok &= "à pied" in meilleur and DUREE_BRUIT + ROT - meilleur["à pied"] >= 0.3
    print("TOUT BON" if ok else "PROBLÈMES")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
