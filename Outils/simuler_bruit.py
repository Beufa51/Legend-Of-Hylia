"""Outil de conception : vérifie la salle 4c « Le bruit » (Plume4c de Scenes/world.tscn).
Règles vérifiées (même géométrie de cône que room.gd, voir simuler_sentinelles.py) :
  1) sans bruit, la sentinelle qui regarde vers le bas voit tout le passage : AUCUN chemin sûr de l'entrée à la porte ;
  2) après avoir brisé un pot sonore, elle regarde vers le pot (axe dominant) pendant `duree_bruit` s : on calcule le temps qu'il faut,
     à pied et en courant, depuis la case de frappe du pot jusqu'à être HORS du passage (rangée 4), puis jusqu'à la porte ;
  3) à la fin du bruit elle revient vers le bas : la suite du chemin doit rester hors de son cône.
Usage : python3 Outils/simuler_bruit.py"""
import math, sys, os
sys.path.insert(0, os.path.dirname(__file__))
import simuler_sentinelles as sim
from collections import deque

sim.OPAQUE += "U"
VITESSE_MARCHE = 70.0 / 16        # cases par seconde (player.gd : 70 px/s)
VITESSE_COURSE = VITESSE_MARCHE * 1.7
ROTATION = (math.pi / 2) / sim.VITESSE    # un quart de tour = 0,22 s
DUREE = 3.0                       # = generer_monde.py 'duree_bruit'


def dangereuses(g, s, angle):
    return sim.cases_vues(g, [(s, angle)])


def voisins(c):
    return [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]


def atteignable(g, debut, fin, interdit):
    vu, file = {debut}, deque([debut])
    while file:
        c = file.popleft()
        if c == fin:
            return True
        for n in voisins(c):
            if n not in vu and not sim.opaque(g, *n) and n not in interdit:
                vu.add(n); file.append(n)
    return False


def duree_chemin(g, debut, fin, interdit_avant, interdit_apres, fenetre, vitesse):
    """Plus court chemin (en cases) où toute case atteinte avant `fenetre` s n'est pas dans interdit_avant, après : pas dans interdit_apres."""
    vu = {debut: 0}
    file = deque([debut])
    while file:
        c = file.popleft()
        if c == fin:
            return vu[c] / vitesse
        for n in voisins(c):
            if n in vu or sim.opaque(g, *n):
                continue
            t = (vu[c] + 1) / vitesse
            if t < fenetre and n in interdit_avant:
                continue
            if t >= fenetre and n in interdit_apres:
                continue
            vu[n] = vu[c] + 1
            file.append(n)
    return None


def main():
    g, _ = sim.lire_salles()["Plume4c"]
    (s, c), = sim.sentinelles(g)
    bas = dangereuses(g, s, math.pi / 2)
    entree, porte = (12, 11), (12, 1)
    ok = True
    if atteignable(g, entree, porte, bas):
        print("ERREUR : sans bruit on peut passer !"); ok = False
    else:
        print("OK 1 : sans bruit, aucun chemin sûr (le passage est surveillé)")
    pots = [(x, y) for y, r in enumerate(g) for x, ch in enumerate(r) if ch == "U"]
    for pot in pots:
        vers = (pot[0] - s[0], pot[1] - s[1])
        angle = 0.0 if vers[0] > 0 else math.pi
        bruit = dangereuses(g, s, angle)
        cible = (11, 3) if pot[0] > s[0] else (13, 3)
        for frappe in voisins(pot):   # on essaie toutes les cases d'où l'on peut frapper le pot, on garde la meilleure
            if sim.opaque(g, *frappe) or frappe in bas or frappe in bruit or not atteignable(g, entree, frappe, bas):
                continue
            for nom, v in (("à pied", VITESSE_MARCHE), ("en courant", VITESSE_COURSE)):
                t = duree_chemin(g, frappe, cible, bruit, bas, ROTATION + DUREE, v)
                print("  pot", pot, "frappé depuis", frappe, nom, ":", "aucun chemin" if t is None else "%.1f s jusqu'à %s (marge %.1f s sur %.1f s)" % (t, cible, DUREE - t, DUREE))
    print("TOUT BON" if ok else "PROBLÈMES")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
