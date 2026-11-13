"""Outil de développement : écrit Scenes/village.tscn (carte extérieure) à partir des plans ci-dessous.
Usage : python3 Outils/generer_village.py [apercu.png]
  - sans argument : écrit Scenes/village.tscn
  - avec un nom de fichier : écrit AUSSI un aperçu image de tous les écrans (même logique que Scripts/exterieur.gd)
Lettres des plans : voir l'en-tête de Scripts/exterieur.gd. Un écran = 25 x 14 cases.

CARTE EN FORME DE COQ DEBOUT (ailes déployées vers le haut) :
           x=1                x=2                  x=3
  y=0   Temple aile G      PARVIS (tête)       Temple aile D          <- ailes
  y=1   Verger             Grand chemin (cou)  Terrain de la Garde
  y=2   Village ouest      PLACE DU COQ        Village est (caserne)  <- corps
  y=3   Maison du héros    Rivière + pont      Ferme                  <- pattes
  y=4                      Route du Sud                               <- queue (barrée jusqu'à la fin de l'épreuve)
Intérieurs : rangée 5 de la grille (RÈGLE : aucun écran en y=4 sauf (2,4)).
Chaque plan est complété par `finaliser(g, sorties)` : les sorties sont creusées (chemin + arbres retirés) et TOUS les autres
bords sont fermés par des buissons. `Outils/verifier_carte.py` contrôle que les bords et les portes sont cohérents.
"""
import os
import sys

W, H = 25, 14
RACINE = os.path.join(os.path.dirname(__file__), "..")


def vide(): return [['.'] * W for _ in range(H)]
def put(g, c, *pts):
    for (x, y) in pts: g[y][x] = c
def maison(g, c, x, y):
    """Une maison du pack Village Top Down (N, T, R : 5x3 ; M, S, L : 8x3). On donne la même position qu'avant : la porte (colonne 2 de la maison, rangée du bas) est en (x+2, y+4)."""
    put(g, c, (x, y + 2))
def grande(g, x, y):
    """La caserne K (8x3, porte en colonne 2) : porte en (x+3, y+4) comme avant."""
    put(g, 'K', (x + 1, y + 2))
def chemin(g, x0, x1, y0, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): g[y][x] = ':'

# --- Emprises des objets (même table que Scripts/exterieur.gd::OBJETS_G) : sert à retirer/fermer proprement ---
EMPRISES = {'A': (3, 3), 'a': (3, 3), 'P': (3, 3), 'r': (1, 1), 'W': (2, 2), 'e': (2, 1), 'j': (1, 2), 'b': (1, 1), 'B': (1, 1), 'o': (1, 1),
            'x': (1, 1), 'n': (1, 1), 'u': (1, 1), 'z': (1, 1), 'Y': (1, 1), 'y': (1, 1), 'E': (3, 2), 'Q': (3, 3), '~': (1, 1),
            'f': (1, 1), 'g': (1, 1), 'w': (1, 1)}
NON_BLOQUANTS = set('fgw=')          # fleurs et pont : on marche dessus
def emprise(c):
    if c in TAILLES_MAISONS: return TAILLES_MAISONS[c]
    return EMPRISES.get(c)
def cases_objet(g, x, y):
    t = emprise(g[y][x])
    return [(x + i, y + j) for j in range(t[1]) for i in range(t[0])] if t else []
def degager_zone(g, x0, x1, y0, y1):
    """Retire de la zone tout objet (arbre, fleur, maison...) qui la touche, même par un seul coin."""
    for y in range(H):
        for x in range(W):
            if emprise(g[y][x]) and any(x0 <= cx <= x1 and y0 <= cy <= y1 for (cx, cy) in cases_objet(g, x, y)):
                g[y][x] = '.'
def ouvrir(g, cote, prof=None):
    """Creuse une SORTIE : un chemin de 3 cases de large qui traverse le bord `cote` (N, S, E ou O) sur `prof` cases."""
    if cote == 'N':   z = (11, 13, 0, (9 if prof is None else prof) - 1)
    elif cote == 'S': z = (11, 13, 14 - (6 if prof is None else prof), 13)
    elif cote == 'E': z = (25 - (12 if prof is None else prof), 24, 6, 8)
    else:             z = (0, (12 if prof is None else prof) - 1, 6, 8)
    if cote in 'EO':   # on ne retire pas la rangée 6 (c'est là que les maisons ont leur porte), sauf au bord de l'écran
        degager_zone(g, z[0], z[1], 7, 8)
        degager_zone(g, 23 if cote == 'E' else 0, 24 if cote == 'E' else 1, 6, 6)
    else:
        degager_zone(g, *z)
    chemin(g, *z)
def fermer_bords(g, sorties, deja=()):
    """Ferme par un buisson toute case du bord de l'écran qui n'est ni une sortie ni déjà bloquée (sinon le héros sortirait de la carte)."""
    bloque = set(deja)
    for y in range(H):
        for x in range(W):
            for c in cases_objet(g, x, y):
                if g[y][x] not in NON_BLOQUANTS: bloque.add(c)
    ouvertes = set()
    if 'N' in sorties: ouvertes |= {(x, 0) for x in (11, 12, 13)}
    if 'S' in sorties: ouvertes |= {(x, H - 1) for x in (11, 12, 13)}
    if 'E' in sorties: ouvertes |= {(W - 1, y) for y in (6, 7, 8)}
    if 'O' in sorties: ouvertes |= {(0, y) for y in (6, 7, 8)}
    for y in range(H):
        for x in range(W):
            if (x in (0, W - 1) or y in (0, H - 1)) and (x, y) not in bloque and (x, y) not in ouvertes:
                g[y][x] = 'b'
def cases_relief(terrasses=(), escaliers=()):
    """(cases bloquantes, cases couvertes) des terrasses : même règle que Scripts/exterieur.gd::_poser_relief."""
    solides, couvertes = set(), set()
    for ligne in terrasses:
        x0, y0, w, h = (int(v) for v in ligne.split())
        for j in range(h):
            for i in range(w):
                couvertes.add((x0 + i, y0 + j))
                if i == 0 or i == w - 1 or j == 0 or j >= h - 2: solides.add((x0 + i, y0 + j))
    for ligne in escaliers:
        x0, y0 = (int(v) for v in ligne.split())
        for j in range(4):
            for i in range(2):
                solides.discard((x0 + i, y0 + j)); couvertes.add((x0 + i, y0 + j))
    return solides, couvertes
def nettoyer_arbres(g, couvertes=()):
    """Retire les arbres 3x3 qui gênent : sur un chemin, dans l'eau, sur une terrasse, débordant de l'écran ou chevauchant une maison/un objet plein."""
    occupe = set(couvertes)
    for y in range(H):
        for x in range(W):
            c = g[y][x]
            if emprise(c) and c not in 'AaP' and c not in NON_BLOQUANTS and c != 'b':
                occupe |= set(cases_objet(g, x, y))
    for y in range(H):
        for x in range(W):
            if g[y][x] in 'AaP':
                cases = cases_objet(g, x, y)
                if x + 3 > W or y + 3 > H or any(cx >= W or cy >= H or (cx, cy) in occupe or g[cy][cx] in ':~=' for cx, cy in cases):
                    g[y][x] = '.'
def finaliser(g, sorties, profondeurs=None, terrasses=(), escaliers=()):
    """Dernière étape d'un écran extérieur : sorties creusées, arbres gênants retirés, décors retirés sous les maisons, bords fermés (sauf sous une terrasse)."""
    solides_ter, couvertes_ter = cases_relief(terrasses, escaliers)
    for c in sorties: ouvrir(g, c, (profondeurs or {}).get(c))
    degager_maisons(g)
    nettoyer_arbres(g, couvertes_ter)
    fermer_bords(g, sorties, couvertes_ter)
def sortie(g): return 'PackedStringArray(' + ', '.join('"' + ''.join(r) + '"' for r in g) + ')'


# --- PLACE DU COQ (2,2) : cœur du village. Statue du coq au centre, puits, marché, deux maisons.
#     Sorties : nord (grand chemin vers le temple), ouest (village ouest), est (village est, caserne).
#     Tant que les écrans voisins n'existent pas, les sorties sont fermées par des buissons (b).
place = vide()
chemin(place, 11, 13, 0, 4)                 # vers le nord
chemin(place, 0, 5, 6, 8)                   # vers l'ouest
chemin(place, 19, 24, 6, 8)                 # vers l'est
for y in range(H):                          # la place : un grand ovale de terre autour de la statue
    for x in range(W):
        if ((x - 12) / 7.6) ** 2 + ((y - 7) / 3.7) ** 2 <= 1.0: place[y][x] = ':'
chemin(place, 4, 5, 6, 6); chemin(place, 19, 20, 6, 6)   # devant les portes des maisons
# Bordure d'arbres en haut et en bas, ouverture au nord (colonnes 10-14) : faite plus bas par bordure() (définie après)
# Côtés : arbres, ouvertures ouest/est (rangées 6-8)
for (x, y) in [(0, 2), (0, 4), (0, 9), (23, 2), (23, 4), (23, 9)]:
    put(place, 'P' if y == 4 else 'A', (x, y))
put(place, 'b', (0, 11), (1, 11), (23, 11), (24, 11))
# Sortie nord provisoirement fermée (l'écran voisin n'existe pas encore) ; ouest et est sont ouvertes
# Maisons (portes en bas : colonnes 4 et 20)
maison(place, 'M', 3, 2); maison(place, 'T', 18, 2)   # maisons 7x4 : portes en (5,6) et (20,6)
# Statue du coq au centre, bannières de part et d'autre
put(place, 'Q', (11, 4)); put(place, 'j', (9, 5), (15, 5))   # girouette 3x3 au centre
# Marché (en bas à gauche) et puits (en bas à droite)
put(place, 'E', (4, 9)); put(place, 'o', (7, 10), (3, 9))
put(place, 'W', (18, 9)); put(place, 'o', (21, 10))
# Fleurs (f tournesol, g fleur rouge, w marguerite) : par petits massifs
put(place, 'f', (8, 2), (9, 3), (16, 3), (22, 9), (10, 11))
put(place, 'g', (15, 2), (14, 11), (8, 3), (2, 6), (7, 5), (17, 4), (21, 5))
put(place, 'w', (9, 2), (16, 2), (2, 10), (3, 11), (15, 11), (11, 11), (22, 10), (2, 2), (7, 4), (22, 5))
# Animaux : 3 poules (c blanche, h rousse) qui picorent sur la place, un chat qui dort devant la maison, un chien
animaux_place = ['c 9 9', 'c 15 10', 'h 14 4', 'k 6 7', 'd 17 8']

TAILLES_MAISONS = {'M': (8, 3), 'N': (5, 3), 'T': (5, 3), 'R': (5, 3), 'S': (8, 3), 'L': (8, 3), 'K': (8, 3), 'U': (7, 3), 'Z': (9, 5)}

def degager_maisons(g):
    """Retire du plan tout décor (fleurs, tonneaux...) posé SOUS une maison."""
    for y in range(H):
        for x in range(W):
            if g[y][x] in TAILLES_MAISONS:
                w, h = TAILLES_MAISONS[g[y][x]]
                for dy in range(h):
                    for dx in range(w):
                        if (dx, dy) != (0, 0) and x + dx < W and y + dy < H and g[y + dy][x + dx] != ':':
                            g[y + dy][x + dx] = '.'

def bordure(g, haut=True, bas=True, trou=None):
    """Forêt en haut et en bas : une rangée d'arbres ronds 3x3 (vert, roux, fleuri). Les sorties sont creusées ensuite par ouvrir() (`trou` n'est plus utilisé)."""
    for k, x in enumerate(range(0, 22, 3)):
        if haut: put(g, 'AaPa'[k % 4], (x, 0))
        if bas: put(g, 'aPAa'[k % 4], (x, 11))
    put(g, 'b', (24, 12), (24, 13), (24, 0), (24, 1), (24, 2))


bordure(place)   # (la place est construite plus haut ; sa forêt est posée ici ; les sorties N/O/E/S sont creusées par finaliser)

# --- VILLAGE OUEST (1,2) : deux maisons au nord, un coin potager/marché au sud.
#     Entrée par l'est (la place). L'ouest mène à la ferme (pas encore construite) : fermé par des buissons.
ouest = vide()
chemin(ouest, 3, 24, 6, 8)                                  # (l'ouest est fermé : pas de chemin jusqu'au bord)
chemin(ouest, 4, 5, 6, 6); chemin(ouest, 16, 17, 6, 6)       # devant les portes
bordure(ouest)
maison(ouest, 'M', 3, 2); maison(ouest, 'R', 15, 2)   # portes en (5,6) et (17,6) ; le couloir nord/sud (colonnes 11-13) reste libre
for (x, y) in [(0, 2), (0, 4), (21, 2), (23, 4), (0, 10), (22, 10)]:
    put(ouest, 'A' if x % 2 == 0 else 'a', (x, y))
put(ouest, 'P', (8, 2), (18, 3))
put(ouest, 'E', (5, 10)); put(ouest, 'o', (9, 11), (17, 10), (17, 11))
put(ouest, 'j', (9, 5), (21, 5))
put(ouest, 'f', (2, 6 - 1), (7, 4), (19, 5), (3, 11)); put(ouest, 'g', (8, 5), (10, 3), (20, 4), (6, 11), (5, 10))
put(ouest, 'w', (2, 5), (11, 4), (18, 5), (4, 10), (21, 12))
pnjs_ouest = [
    "Woman 10 9 haut | Colette | [fragment_gauche] Tu as rapporté l'aile ?! Vue du ciel, elle a la forme d'une plume géante, dit-on. // Moi, je savais bien que tu réussirais. ## [plume2] Il paraît que tu as allumé des braseros dans le noir ? Tu n'as pas peur de te brûler les moustaches ! ## Oh, tu es la nouvelle recrue ! Tout le village parle de ton épreuve d'adoubement. // On raconte que le donjon sous le temple a la forme d'un grand coq. // Un coq dans un donjon... Moi, je préfère ceux de ma basse-cour !",
    "OldMan 9 7 droite | Vieux Gaspard | [fragment_gauche] Une aile entière... Ton père n'a jamais dépassé la quatrième plume. // Il serait fier. Moi aussi, petite. ## [plume3] Tu as réveillé le chant du coq, alors ? // Les cloches ne mentent jamais : écoute bien avant de frapper. ## Le coq chante chaque aube depuis mille ans. // S'il se taisait un jour, le royaume tremblerait. // Ton père tenait la lance avant toi. Garde-la bien, petite.",
    "Boy 20 8 gauche | Tom | [plume4] On dit que des statues de pierre surveillent la quatrième plume ! // Moi, je me serais caché derrière un pilier. Et toi ? ## Tu as une vraie lance de la garde ! Tu me la prêtes ? // ... Non ? Tant pis. // Un conseil : n'embête pas les poules. Elles se vengent.",
]
animaux_ouest = ['c 6 10', 'h 20 9', 'c 16 10']

# --- VILLAGE EST (3,2) : la CASERNE de la garde royale (bâtiment beige au nord, bannières rouges).
#     Entrée par l'ouest (la place). L'est mène à la maison du héros (pas encore construite) : fermé.
est = vide()
chemin(est, 0, 21, 6, 8)                                      # (l'est est fermé)
chemin(est, 17, 19, 6, 6)                                     # devant la porte de la caserne
bordure(est)
grande(est, 15, 2); put(est, 'j', (8, 3), (14, 3))        # caserne 7x4 : porte en (18,6) ; le couloir nord/sud (colonnes 11-13) reste libre
put(est, 'o', (6, 3), (6, 4), (18, 3), (19, 4))
for (x, y) in [(0, 2), (0, 4), (2, 9), (22, 2), (22, 9), (20, 11)]:
    put(est, 'A' if y % 4 == 0 else 'a', (x, y))
put(est, 'P', (3, 2), (21, 5))
put(est, 'E', (4, 10)); put(est, 'o', (8, 10), (19, 9))
put(est, 'g', (9, 5), (16, 5), (13, 10), (2, 6)); put(est, 'f', (7, 5), (17, 4), (12, 11))
put(est, 'w', (8, 4), (15, 4), (14, 10), (23, 10), (1, 7))
pnjs_est = [
    "KnightGold 16 7 gauche | Capitaine Aubrac | [fin_paix] Recrue ! Le Gardien du blason m'a parlé de toi. // Tu as baissé ta lance devant lui... Il faut plus de courage pour cela que pour frapper. // Agenouille-toi. ... Par le coq qui chante à l'aube, je te fais GARDE DU ROYAUME. // Bienvenue dans la Garde. Ta mère va être si fière ! ## [fin_combat] Recrue ! Le Gardien du blason m'a parlé de toi. // Tu l'as vaincu en l'observant, sans colère. C'est ainsi que se bat un garde. // Agenouille-toi. ... Par le coq qui chante à l'aube, je te fais GARDE DU ROYAUME. // Bienvenue dans la Garde. Ta mère va être si fière ! ## [fragment_gauche] Une aile complète ! Je n'y croyais plus. // Mais ce n'est que la moitié du blason : l'aile droite t'attend, et au centre, l'épreuve finale. // Repose-toi, recrue. Tu l'as mérité. ## [capitaine_vu] Alors, cette épreuve ? Le temple est au nord du village. // Souviens-toi : observer, réfléchir, et frapper seulement ce qui doit l'être. ## Te voilà enfin, recrue ! L'épreuve d'adoubement t'attend au temple, au nord du village. // Deux ailes et un corps : voilà la forme du donjon. Observe, réfléchis. // Un garde ne se bat pas pour rien : il comprend d'abord. Va, et reviens avec l'honneur. >> capitaine_vu",
    "Villager3 7 7 droite | Soldat Merle | [plume4] La quatrième plume ? Des sentinelles qui tournent la tête ? Brr. Reste dans l'ombre, c'est le conseil d'un vétéran. ## Dix ans de garde et je n'ai jamais vu le fond du donjon. // Les anciens disent que les plumes de l'aile gauche sont de plus en plus longues. Je ne sais pas ce que ça veut dire !",
    "Villager 6 9 haut | Marchande Rosine | Des pommes ! Des pommes de la ferme ! // Les gardes sont mes meilleurs clients... et les pires payeurs.",
]
animaux_est = ['d 20 7', 'c 12 11']
passages_est = ["18 6 InterieurCaserne 12 9"]   # porte de la caserne (maison beige en (10,2)) ; l'intérieur est en bas de la carte

# --- FERME (3,3) : pattes du coq, au sud-est. Entrée par l'ouest (la rivière), sortie nord vers le village est.
#     Enclos à poules à DROITE (clôtures `e`/`z`, cases `k` = intérieur, entrée au sud en (17..18, 8)),
#     grange fermée à gauche, la fermière lance la CHASSE AUX POULES (cases `s` = où apparaissent les poules).
ferme = vide()
chemin(ferme, 0, 13, 6, 8)
chemin(ferme, 17, 18, 9, 11)                                   # petit chemin vers l'entrée de l'enclos
bordure(ferme)
for x in (15, 17, 19, 21): put(ferme, 'e', (x, 3))             # clôture du haut (cases 15 à 22)
put(ferme, 'e', (15, 8), (19, 8)); put(ferme, 'z', (21, 8), (22, 8))   # bas : entrée aux cases 17 et 18
for y in range(4, 8): put(ferme, 'z', (15, y), (22, y))         # côtés
for y in range(4, 8):
    for x in range(16, 22): put(ferme, 'k', (x, y))
put(ferme, 'n', (16, 9))                                       # panneau de l'enclos
maison(ferme, 'L', 3, 2)                                       # grange : porte en (5,6)
put(ferme, 's', (12, 3), (8, 9), (10, 10), (6, 10), (3, 10), (1, 7))
for (x, y) in [(0, 2), (0, 10), (8, 11), (23, 10), (12, 11)]:
    put(ferme, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(ferme, 'x', (9, 3), (10, 3)); put(ferme, 'o', (1, 9), (5, 11))
put(ferme, 'f', (8, 4), (13, 9), (20, 10), (8, 10)); put(ferme, 'g', (8, 3), (14, 10), (2, 7)); put(ferme, 'w', (10, 9), (2, 3), (19, 10), (22, 10))
pnjs_ferme = ["Villager5 12 5 bas | Fermière Jeanne | Oh, par tous les coqs ! Mes poules se sont échappées de l'enclos ! // Tu peux me les ramener ? Approche-toi d'une poule et appuie sur Espace pour la prendre dans tes bras. // Puis appuie encore sur Espace pour la lancer : par-dessus la clôture, ou par l'entrée au sud ! // 5 poules, 60 secondes. Prête ? C'est parti ! | poules"]
passages_ferme = ["5 6 ! La grange est fermée à clé."]
animaux_ferme = ['c 7 9', 'h 12 9']

# --- MAISON DU HÉROS (1,3) : pattes du coq, au sud-ouest. Entrée par le nord (village ouest) et l'est (la rivière).
#     Le jeu commence DANS la maison.
heros = vide()
chemin(heros, 5, 24, 6, 8)
bordure(heros)
maison(heros, 'N', 4, 2)                                      # la maison bleue : porte en (6,6)
put(heros, 'j', (10, 4), (2, 4))
for (x, y) in [(0, 2), (0, 10), (22, 3), (22, 9), (19, 11), (3, 11)]:
    put(heros, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(heros, 'P', (18, 2), (20, 5), (21, 10))
put(heros, 'o', (14, 4), (16, 9))
put(heros, 'f', (8, 3), (15, 5), (10, 10), (18, 9)); put(heros, 'g', (9, 5), (14, 5), (6, 10), (20, 9))
put(heros, 'w', (13, 3), (8, 11), (17, 6), (4, 9), (21, 7))
animaux_heros = ['c 15 7', 'k 10 6']
passages_heros = ["6 6 InterieurHeros 12 9"]

# --- RIVIÈRE (2,3) : pattes du coq, au centre-sud. Une rivière (rangées 3-4) coupe la carte d'ouest en est ;
#     un pont (colonnes 11-13) relie la place au sud. Les chemins ouest/est (maison du héros, ferme) sont sous la rivière.
riviere = vide()
# la rivière serpente : rangées de l'eau selon la colonne (le pont, colonnes 11-13, reste en rangées 2-4)
def rangees_eau(x):
    return (3, 4, 5) if x <= 3 else (2, 3, 4) if x <= 20 else (1, 2, 3)
for x in range(W):
    for y in rangees_eau(x): put(riviere, '~', (x, y))
for x in (11, 12, 13):
    put(riviere, '=', (x, 2), (x, 3), (x, 4))
bordure(riviere, haut=False, bas=False)
chemin(riviere, 11, 13, 0, 1); chemin(riviere, 11, 13, 5, 13); chemin(riviere, 0, 24, 6, 8)
for (x, y) in [(0, 10), (2, 12), (21, 11), (22, 9), (3, 0), (19, 0)]:
    put(riviere, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(riviere, 'r', (7, 10), (17, 10)); put(riviere, 'u', (8, 5), (16, 5)); put(riviere, 'n', (10, 5))
put(riviere, 'f', (6, 2), (18, 2), (9, 11), (15, 9)); put(riviere, 'g', (7, 9), (4, 5), (19, 5)); put(riviere, 'w', (9, 2), (15, 1), (5, 11), (20, 9), (2, 5))
for x in range(W):                      # (l'eau passe avant les décors : on retire ce qui est tombé dedans)
    for y in rangees_eau(x):
        if riviere[y][x] != '=': riviere[y][x] = '~'
animaux_riviere = ['c 6 9', 'd 19 6']
pnjs_riviere = ["Villager4 6 5 haut | Pêcheur Bastien | Chut ! Tu fais fuir les poissons. // Cette rivière coupe le pays en deux. Le pont est tout ce qu'il y a de plus sûr... enfin, je crois. // Au sud, c'est la route du royaume. Mais la garde en interdit l'accès aux recrues."]

# --- ROUTE DU SUD (2,4) : la queue du coq. La route du royaume est BARRÉE (clôture + garde) jusqu'à la fin de l'épreuve.
route = vide()
chemin(route, 11, 13, 0, 10)
bordure(route, haut=False)
for x in (9, 11, 13, 15): put(route, 'e', (x, 11))             # la barrière
put(route, 'z', (8, 11), (17, 11))
# RELIEF : la route passe dans un petit canyon, deux terrasses de chaque côté (escaliers pour y monter)
terrasses_route = ["0 2 8 8", "17 2 8 8"]
escaliers_route = ["3 7", "20 7"]
put(route, 'f', (9, 4), (15, 6), (2, 3), (21, 3)); put(route, 'g', (9, 8), (15, 3), (5, 4), (19, 5)); put(route, 'w', (10, 6), (14, 8), (9, 1), (3, 5), (22, 4))
put(route, 'n', (10, 10)); put(route, 'u', (6, 3), (18, 3))
animaux_route = ['c 9 6']
pnjs_route = ["Villager3 12 9 bas | Garde de la route | [epreuve_reussie] Garde du royaume ! La route est ouverte pour toi... mais pas encore aujourd'hui : le capitaine veut te voir. ## Halte ! Cette route mène au royaume. // Elle est fermée aux recrues. Passe d'abord l'épreuve d'adoubement, au temple."]

# --- VERGER (1,1) : l'aile gauche du coq, entre le temple (nord) et le village ouest (sud).
verger = vide()
chemin(verger, 11, 13, 0, 13)
bordure(verger)
for y in (3, 7):                                       # le verger : arbres ronds à gauche, en quinconce
    for k, x in enumerate((0, 3, 6)):
        put(verger, 'a' if (k + y) % 2 else 'A', (x, y + (k % 2)))
for k, x in enumerate((15, 18, 21)):                   # et sous la terrasse, à droite
    put(verger, 'P' if k == 1 else 'A', (x, 8 + (k % 2)))
put(verger, 'B', (9, 4), (14, 8), (10, 9))
put(verger, 'u', (10, 6), (14, 10)); put(verger, 'n', (10, 7))
put(verger, 'f', (10, 2), (14, 2), (10, 12), (17, 2), (21, 3)); put(verger, 'g', (14, 9), (10, 5), (19, 2), (20, 4)); put(verger, 'w', (14, 5), (10, 10), (14, 12), (18, 3), (21, 2))
# RELIEF : une terrasse (verger en hauteur) à droite, avec son escalier
terrasses_verger = ["16 1 7 6"]
escaliers_verger = ["18 4"]
animaux_verger = ['c 8 6', 'h 15 6']
pnjs_verger = ["OldMan 10 8 droite | Jardinier Anselme | Mes pommiers ont vu passer bien des recrues. // Ceux qui montent au temple de l'aile gauche passent toujours par ici. // Prends ton temps : l'épreuve ne se gagne pas en courant. ... Quoique tu aies un joli coup de jarret."]

# --- TERRAIN DE LA GARDE (3,1) : l'aile droite du coq, entre le temple (nord) et la caserne (sud).
terrain = vide()
chemin(terrain, 11, 13, 0, 13)
bordure(terrain)
# RELIEF : l'estrade d'entraînement de la garde, à gauche, avec son escalier
terrasses_terrain = ["1 2 8 7"]
escaliers_terrain = ["4 6"]
put(terrain, 'o', (2, 3), (7, 3), (7, 5)); put(terrain, 'x', (2, 5), (6, 3))     # tonneaux et caisses sur l'estrade
put(terrain, 'j', (15, 6), (21, 6))
for k, (x, y) in enumerate([(15, 8), (18, 9), (21, 7), (16, 2), (20, 2)]):
    put(terrain, 'A' if k % 2 else 'a', (x, y))
put(terrain, 'f', (10, 10), (14, 3), (3, 5)); put(terrain, 'g', (10, 2), (14, 11), (6, 6)); put(terrain, 'w', (14, 8), (10, 6), (5, 4))
pnjs_terrain = ["Villager3 3 4 droite | Soldat Hugues | Un, deux ! Un, deux ! Le matin, la garde s'entraîne ici. // Les recrues ne sont pas obligées de venir. Mais les meilleures le font."]
animaux_terrain = ['d 14 7']


def interieur(porte, meubles, haut, gauche=6, droite=17, bas=10):
    """Une pièce rectangulaire : mur du haut = 2 rangées (pans de 2 cases : lettres de `haut`), côtés et bas = murs pleins."""
    g = [[' '] * W for _ in range(H)]
    for y in range(3, bas + 1):
        for x in range(gauche, droite + 1):
            mur = y < 5 or y == bas or x in (gauche, droite)
            g[y][x] = '#' if mur else '.'
    for i, lettre in enumerate(haut): g[3][gauche + 1 + 2 * i] = lettre
    g[bas][porte] = 'm'
    for (c, x, y) in meubles: g[y][x] = c
    return g

int_heros = interieur(12, [('L', 7, 5), ('S', 14, 5), ('q', 11, 5), ('t', 9, 7), ('T', 14, 8), ('C', 13, 8), ('o', 7, 9), ('p', 16, 7)],
                      ['w', 'y', 'z', 'v', 'x'])
pnjs_int_heros = ["Woman 10 7 bas | Maman | [epreuve_reussie] Garde du royaume ! Ma fille, garde du royaume ! // Ton père aurait été si fier de toi. Viens, le repas de fête est prêt ! ## [fragment_gauche] Ma fille, la moitié du blason ! Je vais préparer un grand repas. // Mais d'abord, va te reposer. ## [capitaine_vu] Le capitaine t'a parlé ? Alors file au temple, et fais attention à toi ! ## Bien dormi ? Aujourd'hui, c'est ton grand jour ! // Le capitaine Aubrac t'attend à la caserne, à l'est de la place du village. // N'oublie pas la lance de ton père : elle est posée près de la porte. ... Ah, tu l'as déjà. Brave petite !"]
int_caserne = interieur(12, [('G', 7, 5), ('G', 10, 5), ('H', 13, 5), ('J', 15, 7), ('F', 7, 8), ('M', 9, 8), ('D', 15, 8)],
                        ['w', 'z', 'x', 'w', 'x'])
pnjs_int_caserne = ["Villager3 13 7 gauche | Soldat Gilles | Ici dorment les recrues de la garde royale. // Ne touche pas aux lits, on dit qu'ils sont habités... par des puces."]

FERMEE = "La porte est fermée à clé."
ferme_place = ["5 6 ! " + FERMEE, "20 6 ! " + FERMEE]
ferme_ouest = ["5 6 ! " + FERMEE, "17 6 InterieurStand 12 9"]   # la maison rouge est le STAND DE TIR

# STAND DE TIR (maison rouge du village ouest) : les pots du jeu apparaissent sur les cases `c` (rangée du fond)
int_stand = interieur(12, [('t', 9, 7), ('o', 7, 5), ('q', 16, 5), ('p', 7, 9), ('U', 8, 8)], ['w', 'y', 'x', 'y', 'w'])
for x in (9, 11, 13, 15): int_stand[5][x] = 'c'
pnjs_int_stand = ["Villager4 14 8 gauche | Maître Tirard | Approchez, approchez ! Le grand jeu du stand de la Garde ! // Des pots vont apparaître sur l'étagère du fond. Casse-les à coups de lance avant qu'ils ne disparaissent ! // 30 secondes, 8 pots pour le bronze, 14 pour l'argent, 20 pour l'or. Prête ? C'est parti ! | tir"]


# --- LE CHEMIN DU TEMPLE : GRAND CHEMIN (2,1) -> PARVIS (2,0) -> TEMPLE DE L'AILE GAUCHE (1,0)
def foret_cotes(g, x0, x1):
    """Remplit de forêt les colonnes en dehors du passage x0..x1 (chemin qui traverse tout l'écran)."""
    for y in range(0, 13, 2):
        for x in range(0, 24, 2):
            if x + 1 < x0 or x > x1:
                put(g, 'A' if (x // 2 + y // 2) % 2 == 0 else 'a', (x, y if (x // 2) % 2 == 0 else min(y + 1, 12)))
    put(g, 'b', (24, 0), (24, 1), (24, 12), (24, 13))

grand = vide()
chemin(grand, 11, 13, 0, 13)
bordure(grand)                                                 # (les côtés sont tenus par les deux collines : voir terrasses_grand)
put(grand, 'A', (0, 9)); put(grand, 'a', (21, 9))   # un arbre au pied de chaque colline
put(grand, 'f', (9, 4), (15, 8)); put(grand, 'g', (9, 9), (15, 3)); put(grand, 'w', (9, 6), (15, 10), (9, 12))
put(grand, 'n', (10, 7))                                       # panneau (décor)
animaux_grand = ['c 10 4']

def parvis_commun():
    """Le parvis, commun aux deux versions : chemins, forêt du bord, bannières, fleurs."""
    g = vide()
    chemin(g, 11, 13, 6, 13)                                  # vient du sud
    chemin(g, 0, 24, 6, 8)                                    # vers l'ouest : temple de l'aile gauche ; vers l'est : temple de l'aile droite
    put(g, 'j', (7, 4), (17, 4)); put(g, 'o', (6, 5), (18, 5))
    bordure(g)
    for (x, y) in [(0, 2), (0, 4), (0, 10), (22, 2), (22, 4), (22, 9), (20, 11)]:
        put(g, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
    put(g, 'f', (8, 9), (16, 9)); put(g, 'w', (6, 10), (19, 10)); put(g, 'g', (14, 5))
    return g

# AVANT : une forêt dense (rangées 1-4) cache le corps du coq ; au bout du petit chemin, la STÈLE du coq (Y),
#         avec les empreintes des deux ailes. On s'en approche en montant : avec les 2 fragments -> cérémonie (world.gd).
parvis = parvis_commun()
for y in (1, 3):
    for x in range(7, 18, 2):
        put(parvis, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
chemin(parvis, 12, 12, 5, 5); put(parvis, 'Y', (12, 5))
passages_parvis = ["12 6 $stele"]

# APRÈS (drapeau corps_revele) : la forêt s'est écartée, le CORPS DU COQ (bâtiment en forme de coq Z, 9x5, porte en (12,4)) se dresse ;
#         la stèle, avec les deux ailes, s'est rangée à gauche du passage.
parvis_revele = parvis_commun()
for y in range(0, 4):                       # mêmes arbres que ceux qui s'écartent pendant la cérémonie (world.gd : colonnes 7-18, rangées 0-3)
    for x in range(7, 19): parvis_revele[y][x] = '.'
put(parvis_revele, 'Z', (8, 0)); chemin(parvis_revele, 12, 12, 5, 5); put(parvis_revele, 'y', (10, 5))
passages_parvis_revele = ["12 4 @corps:Arene 12 11 Le corps du coq. Au fond de la grande salle, quelqu'un t'attend...", "10 6 $stele"]

temple_g = vide()
chemin(temple_g, 11, 24, 6, 8)                                 # vient de l'est (le parvis) ; sortie sud vers le verger
chemin(temple_g, 12, 12, 5, 5)                                 # devant la porte du temple
put(temple_g, 'U', (9, 4))                                     # temple de l'aile gauche (arche + marches) : porte en (12,6) -> donjon
put(temple_g, 'j', (7, 3), (17, 3)); put(temple_g, 'o', (6, 4), (18, 4))
bordure(temple_g)
put(temple_g, 'b', (0, 6), (0, 7), (0, 8))                     # l'ouest : fermé
for (x, y) in [(0, 2), (0, 4), (0, 10), (22, 2), (22, 9), (3, 9)]:
    put(temple_g, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(temple_g, 'P', (20, 2), (3, 2)); put(temple_g, 'f', (8, 9), (16, 9)); put(temple_g, 'g', (10, 5), (14, 5)); put(temple_g, 'w', (6, 10), (19, 10))
passages_temple_g = ["12 6 @donjon:Vestibule 12 10 La grande porte du donjon se referme derrière toi... Il faudra finir l'épreuve pour ressortir."]

# --- TEMPLE DE L'AILE DROITE (3,0) : le symétrique du temple de l'aile gauche (chemin venant de l'ouest)
temple_d = vide()
chemin(temple_d, 0, 13, 6, 8)                                  # vient de l'ouest (le parvis)
chemin(temple_d, 12, 12, 5, 5)                                 # devant la porte du temple
put(temple_d, 'U', (9, 4))                                     # même arche que l'aile gauche : porte en (12,6) -> aile droite
put(temple_d, 'j', (7, 3), (17, 3)); put(temple_d, 'o', (6, 4), (18, 4))
bordure(temple_d)
put(temple_d, 'b', (24, 6), (24, 7), (24, 8))                  # l'est (falaise, plus tard) : fermé
for (x, y) in [(1, 2), (1, 9), (22, 2), (22, 4), (22, 10), (19, 9)]:
    put(temple_d, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(temple_d, 'P', (20, 2), (3, 2)); put(temple_d, 'f', (8, 9), (16, 9)); put(temple_d, 'g', (10, 5), (14, 5)); put(temple_d, 'w', (6, 10), (19, 10))
passages_temple_d = ["12 6 @aile_droite:Vestibule 12 10 La grande porte se referme derrière toi... L'aile droite du blason : ici, tout est inversé."]

terrasses_grand, escaliers_grand = ["0 1 8 8", "17 1 8 8"], ["3 6", "20 6"]          # le cou du coq : deux collines de chaque côté du grand chemin
terrasses_parvis, escaliers_parvis = ["0 0 6 6", "19 0 6 6"], ["3 3", "21 3"]            # la tête : deux petites terrasses qui encadrent le parvis
terrasses_est, escaliers_est = ["0 0 9 6"], ["3 3"]                                       # le village est : une colline au nord-ouest, la caserne en bas à droite
# décor SUR les terrasses (fleurs, souches, cailloux : rien de plus gros, les arbres sont retirés des terrasses)
put(grand, 'f', (2, 3), (6, 5), (19, 4), (23, 6)); put(grand, 'g', (4, 2), (5, 6), (21, 3), (18, 6)); put(grand, 'w', (3, 4), (6, 3), (22, 4), (19, 2))
put(grand, 'u', (2, 6), (23, 2)); put(grand, 'r', (6, 6), (18, 3))
for _g in (parvis, parvis_revele):
    put(_g, 'f', (2, 1), (22, 1)); put(_g, 'w', (3, 1), (21, 3)); put(_g, 'g', (4, 2), (20, 1)); put(_g, 'u', (1, 3), (20, 3))
put(est, 'f', (2, 2), (6, 3)); put(est, 'g', (4, 1), (7, 3)); put(est, 'w', (1, 2), (5, 3)); put(est, 'u', (7, 2), (2, 3)); put(est, 'r', (6, 1))

# COFFRES et SECRETS sur les terrasses : ("x y drapeau | texte") et ("sx sy cx cy drapeau | texte" : rocher fissuré en (sx,sy), coffre caché en (cx,cy)). Chaque coffre donne un INSIGNE de la Garde (9 en tout, voir Etat.TOTAL_INSIGNES).
INS = "Un insigne de la Garde ! (%d / 9)"
COFFRES = {
    'GrandChemin': (["4 3 insigne_gc1 | " + INS], ["20 3 22 5 insigne_gc2 | " + INS]),
    'Parvis': (["2 2 insigne_pa1 | " + INS], ["21 2 23 2 insigne_pa2 | " + INS]),
    'VillageEst': (["5 2 insigne_ve1 | " + INS], []),
    'Verger': (["21 3 insigne_vg1 | " + INS], []),
    'TerrainGarde': (["5 4 insigne_tg1 | " + INS], []),
    'RouteSud': (["2 4 insigne_rs1 | " + INS], ["19 4 22 5 insigne_rs2 | " + INS]),
}
ecrans = [
    # --- ailes (y=0)
    ('TempleGauche', (1, 0), temple_g, {'passages': passages_temple_g, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg', 'indice': "Le temple de l'aile gauche. Derrière cette porte, l'épreuve t'attend."}),
    ('Parvis', (2, 0), parvis, {'terrasses': terrasses_parvis, 'escaliers': escaliers_parvis, 'passages': passages_parvis, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg',
        'drapeau_revele': 'corps_revele', 'layout_revele': [''.join(r) for r in parvis_revele], 'passages_revele': passages_parvis_revele,
        'indice': "Une stèle se dresse devant la forêt. Un coq y est gravé, ses ailes creusées dans la pierre..."}),
    ('TempleDroit', (3, 0), temple_d, {'passages': passages_temple_d, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg', 'indice': "Le temple de l'aile droite. Derrière cette porte, la seconde moitié de l'épreuve."}),
    # --- cou et ailes basses (y=1)
    ('Verger', (1, 1), verger, {'animaux': animaux_verger, 'pnjs': pnjs_verger, 'terrasses': terrasses_verger, 'escaliers': escaliers_verger}),
    ('GrandChemin', (2, 1), grand, {'animaux': animaux_grand, 'terrasses': terrasses_grand, 'escaliers': escaliers_grand}),
    ('TerrainGarde', (3, 1), terrain, {'animaux': animaux_terrain, 'pnjs': pnjs_terrain, 'terrasses': terrasses_terrain, 'escaliers': escaliers_terrain}),
    # --- corps (y=2)
    ('VillageOuest', (1, 2), ouest, {'animaux': animaux_ouest, 'pnjs': pnjs_ouest, 'passages': ferme_ouest}),
    ('PlaceDuCoq', (2, 2), place, {'animaux': animaux_place, 'passages': ferme_place}),
    ('VillageEst', (3, 2), est, {'animaux': animaux_est, 'pnjs': pnjs_est, 'passages': passages_est, 'terrasses': terrasses_est, 'escaliers': escaliers_est}),
    # --- pattes (y=3)
    ('MaisonHeros', (1, 3), heros, {'animaux': animaux_heros, 'passages': passages_heros}),
    ('Riviere', (2, 3), riviere, {'animaux': animaux_riviere, 'pnjs': pnjs_riviere}),
    ('Ferme', (3, 3), ferme, {'pnjs': pnjs_ferme, 'animaux': animaux_ferme, 'passages': passages_ferme, 'minijeu': 'poules'}),
    # --- queue (y=4)
    ('RouteSud', (2, 4), route, {'animaux': animaux_route, 'pnjs': pnjs_route, 'terrasses': terrasses_route, 'escaliers': escaliers_route}),
]
for _n, _gr, _g, _p in ecrans:
    if _n in COFFRES:
        _p['coffres'], _p['secrets'] = COFFRES[_n]

# Intérieurs : en bas de la carte (rangée 5), dans une scène à part (Scenes/interieur.tscn)
interieurs = [
    ('InterieurHeros', (4, 5), int_heros, {'pnjs': pnjs_int_heros, 'passages': ["12 10 MaisonHeros 6 7", "14 6 $records"],
        'indice': "Tu te réveilles chez toi. Aujourd'hui, c'est ton adoubement ! Parle à Maman, puis rejoins le capitaine à la caserne (à l'est de la place du village)."}),
    ('InterieurStand', (1, 5), int_stand, {'pnjs': pnjs_int_stand, 'passages': ["12 10 VillageOuest 17 7"], 'minijeu': 'tir'}),
    ('InterieurCaserne', (3, 5), int_caserne, {'pnjs': pnjs_int_caserne, 'passages': ["12 10 VillageEst 18 7"], 'style': 'caserne'}),
]
depart = (4 * 400 + 9 * 16 + 8, 5 * 224 + 6 * 16 + 3)   # nouvelle partie : dans la maison du héros, à côté du lit


# Sorties de chaque écran (N, S, E, O) ; `profondeurs` = longueur du chemin creusé quand ce n'est pas la valeur par défaut (voir ouvrir())
SORTIES = {
    'TempleGauche': ('ES', temple_g), 'Parvis': ('SOE', parvis), 'TempleDroit': ('OS', temple_d),
    'Verger': ('NS', verger), 'GrandChemin': ('NS', grand), 'TerrainGarde': ('NS', terrain),
    'VillageOuest': ('NES', ouest), 'PlaceDuCoq': ('NOES', place), 'VillageEst': ('NOS', est),
    'MaisonHeros': ('NE', heros), 'Riviere': ('NOES', riviere), 'Ferme': ('NO', ferme), 'RouteSud': ('N', route),
}
PROFONDEURS = {'PlaceDuCoq': {'N': 4, 'S': 4, 'E': 6, 'O': 6}, 'Riviere': {'N': 2}, 'Parvis': {'S': 6, 'O': 12, 'E': 12}}
RELIEF = {'GrandChemin': (terrasses_grand, escaliers_grand), 'Parvis': (terrasses_parvis, escaliers_parvis), 'VillageEst': (terrasses_est, escaliers_est), 'Verger': (terrasses_verger, escaliers_verger), 'TerrainGarde': (terrasses_terrain, escaliers_terrain), 'RouteSud': (terrasses_route, escaliers_route)}
for _nom, (_s, _g) in SORTIES.items():
    finaliser(_g, _s, PROFONDEURS.get(_nom), *RELIEF.get(_nom, ((), ())))
finaliser(parvis_revele, 'SOE', PROFONDEURS['Parvis'], terrasses_parvis, escaliers_parvis)


def ecrire_scene():
    out = '''[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://Scripts/world.gd" id="1"]
[ext_resource type="PackedScene" path="res://Scenes/exterieur.tscn" id="2"]
[ext_resource type="PackedScene" path="res://Scenes/player.tscn" id="3"]
[ext_resource type="PackedScene" path="res://Scenes/interieur.tscn" id="4"]

; FICHIER GÉNÉRÉ par Outils/generer_village.py : modifie les plans là-bas, pas ici.

[node name="World" type="Node2D"]
script = ExtResource("1")
musique = "res://Assets/Musique/First Light in the Village.mp3"
donjon = false

'''
    for nom, (gx, gy), g, props in ecrans + interieurs:
        out += '[node name="%s" parent="." instance=ExtResource("%s")]\n' % (nom, "4" if nom.startswith("Interieur") else "2")
        out += 'grille = Vector2i(%d, %d)\n' % (gx, gy)
        for k, v in props.items():
            if isinstance(v, list):   # liste de textes -> PackedStringArray
                out += '%s = PackedStringArray(%s)\n' % (k, ', '.join('"%s"' % e for e in v))
            else:
                out += '%s = "%s"\n' % (k, v)
        out += 'layout = %s\n\n' % sortie(g)
    out += '''[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % depart
    with open(os.path.join(RACINE, "Scenes/village.tscn"), "w", encoding="utf-8") as f:
        f.write(out)
    print("village.tscn écrit :", [e[0] for e in ecrans + interieurs])


# --- Aperçu (même logique que Scripts/exterieur.gd) ---------------------------------------
def touffe(g, x, y, gx, couvertes):
    if (x * 37 + y * 91 + gx * 13) % 6 != 0 or g[y][x] != '.' or (x, y) in couvertes:
        return False
    est = lambda xx, yy: g[min(max(yy, 0), H - 1)][min(max(xx, 0), W - 1)] == ':'
    return not any(est(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


def apercu(fichier):
    from PIL import Image
    pack = os.path.join(RACINE, "Assets/Ninja_adventure/Backgrounds/Tilesets/")
    planches = {"SOL": Image.open(pack + "TilesetFloor.png").convert("RGBA"),
                "NATURE": Image.open(pack + "TilesetNature.png").convert("RGBA"),
                "MAISONS": Image.open(pack + "TilesetHouse.png").convert("RGBA")}
    tuiles = os.path.join(RACINE, "Assets/Gemini/tuiles/")
    # Objets Gemini : lettre -> (image, emprise en cases) (même table que Scripts/exterieur.gd::OBJETS_G)
    gem = {"A": ("v_arbre_a", 2, 2), "a": ("v_arbre_b", 2, 2), "P": ("v_sapin", 2, 2), "b": ("v_buisson", 1, 1), "B": ("v_buisson_baies", 1, 1),
           "f": ("v_tournesol", 1, 1), "g": ("v_fleur_rouge", 1, 1), "w": ("v_marguerite", 1, 1), "o": ("v_tonneau", 1, 1),
           "x": ("v_caisse", 1, 1), "n": ("v_panneau", 1, 1), "u": ("v_souche", 1, 1), "r": ("v_roche", 2, 2), "j": ("v_banniere", 1, 2),
           "W": ("v_puits", 2, 2), "e": ("v_cloture", 2, 1), "z": ("v_poteau", 1, 1), "M": ("v_maison_orange", 5, 4), "N": ("v_maison_bleue", 5, 4), "T": ("v_maison_chaume", 5, 4),
           "R": ("v_maison_rouge", 5, 4), "S": ("v_maison_pierre", 5, 4), "K": ("v_maison_caserne", 7, 4), "L": ("v_maison_bois", 5, 4)}
    objets = {"Q": ("tuile:girouette_mat", None)}
    xs = [e[1][0] for e in ecrans]; ys = [e[1][1] for e in ecrans]
    mx, my = min(xs), min(ys)
    img = Image.new("RGBA", ((max(xs) - mx + 1) * 400, (max(ys) - my + 1) * 224), (0, 0, 0, 255))

    def region(planche, r, dest):
        x, y, w, h = r
        img.alpha_composite(planches[planche].crop((x * 16, y * 16, (x + w) * 16, (y + h) * 16)), dest)

    for nom, (gx, gy), g, props in ecrans:
        ox, oy = (gx - mx) * 400, (gy - my) * 224
        est = lambda x, y: g[min(max(y, 0), H - 1)][min(max(x, 0), W - 1)] == ':'
        for y in range(H):
            for x in range(W):
                d = (ox + x * 16, oy + y * 16)
                if est(x, y):
                    bits = (1 if est(x, y - 1) else 0) | (2 if est(x, y + 1) else 0) | (4 if est(x - 1, y) else 0) | (8 if est(x + 1, y) else 0)
                    if bits == 15:
                        nom_t = "v_chemin_f%d" % ((1 if not est(x + 1, y - 1) else 0) | (2 if not est(x - 1, y - 1) else 0) | (4 if not est(x + 1, y + 1) else 0) | (8 if not est(x - 1, y + 1) else 0))
                    else:
                        nom_t = "v_chemin_%d" % bits
                else:
                    h = (x * 73 + y * 151 + gx * 31 + gy * 17) % 13
                    nom_t = "v_herbe_sol_%d" % (h + 1) if h < 2 else "v_herbe_sol"
                img.alpha_composite(Image.open(tuiles + nom_t + ".png").convert("RGBA"), d)
        for y in range(H):
            for x in range(W):
                c = g[y][x]; d = (ox + x * 16, oy + y * 16)
                if c in gem:
                    nom_g, ew, eh = gem[c]
                    im_g = Image.open(tuiles + nom_g + ".png").convert("RGBA")
                    img.alpha_composite(im_g, (round(ox + (x + ew / 2) * 16 - im_g.width / 2), round(oy + (y + eh) * 16 - im_g.height)))
                elif c in objets:
                    planche, r = objets[c]
                    if planche.startswith("tuile:"):
                        img.alpha_composite(Image.open(tuiles + planche[6:] + ".png").convert("RGBA"), d)
                    else:
                        region(planche, r, d)
                elif c == "E":
                    region("MAISONS", (16, 16, 3, 1), (d[0], d[1] + 16))
                    region("MAISONS", (16, 13, 3, 1), d)
        couvertes = set()
        for y in range(H):
            for x in range(W):
                c = g[y][x]
                taille = {"E": (3, 2), "Q": (3, 4)}.get(c) or ((gem[c][1], gem[c][2]) if c in gem else None)
                if taille:
                    couvertes |= {(x + i, y + j) for i in range(taille[0]) for j in range(taille[1])}
        for y in range(H):   # le coq de la girouette, au sommet du mât
            for x in range(W):
                if g[y][x] == "Q":
                    coq = Image.open(tuiles + "girouette_coq.png").convert("RGBA")
                    img.alpha_composite(coq, (ox + x * 16 + 24 - coq.width // 2, oy + y * 16 + 17 - coq.height))
        for y in range(H):
            for x in range(W):
                if touffe(g, x, y, gx, couvertes):
                    gh = Image.open(tuiles + ["v_herbe_1", "v_herbe_2"][(x * 7 + y * 3) % 2] + ".png").convert("RGBA")
                    img.alpha_composite(gh, (ox + x * 16 + (16 - gh.width) // 2, oy + y * 16 + 16 - gh.height))
        for ligne in props.get('pnjs', []):
            tete = ligne.split('|')[0].split()
            sheet = Image.open(os.path.join(RACINE, "Assets/Ninja_adventure/Actor/Character/%s/SeparateAnim/Idle.png" % tete[0])).convert("RGBA")
            f = ["bas", "haut", "gauche", "droite"].index(tete[3])
            img.alpha_composite(sheet.crop((f * 16, 0, f * 16 + 16, 16)), (ox + int(tete[1]) * 16, oy + int(tete[2]) * 16 - 3))
        for ligne in props.get('animaux', []):
            c, x, y = ligne.split()
            fich = {"c": "Chicken/SpriteSheetWhite", "h": "Chicken/SpriteSheetBrown", "k": "Cat/SpriteSheet", "d": "Dog/SpriteSheet"}[c]
            a = Image.open(os.path.join(RACINE, "Assets/Ninja_adventure/Actor/Animal/%s.png" % fich)).convert("RGBA").crop((0, 0, 16, 16))
            img.alpha_composite(a, (ox + int(x) * 16, oy + int(y) * 16 - 3))
    img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(fichier)
    print("aperçu écrit :", fichier)


if __name__ == "__main__":
    ecrire_scene()
    if len(sys.argv) > 1:
        apercu(sys.argv[1])
