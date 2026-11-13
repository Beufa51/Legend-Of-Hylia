"""Outil de développement : écrit Scenes/village.tscn (carte extérieure) à partir des plans ci-dessous.
Usage : python3 Outils/generer_village.py [apercu.png]
  - sans argument : écrit Scenes/village.tscn
  - avec un nom de fichier : écrit AUSSI un aperçu image de tous les écrans (même logique que Scripts/exterieur.gd)
Lettres des plans : voir l'en-tête de Scripts/exterieur.gd. Un écran = 25 x 14 cases.

Carte prévue (5 x 3 écrans) :
           x=0             x=1              x=2                x=3              x=4
  y=0   Bois (secret)   Temple aile G    Parvis + CORPS     Temple aile D    Falaise
  y=1   Rivière         Chemin forêt     Grand chemin       Chemin           Cascade
  y=2   Ferme           Village ouest    PLACE DU COQ       Village est      Maison du héros
"""
import os
import sys

W, H = 25, 14
RACINE = os.path.join(os.path.dirname(__file__), "..")


def vide(): return [['.'] * W for _ in range(H)]
def put(g, c, *pts):
    for (x, y) in pts: g[y][x] = c
def maison(g, c, x, y):
    """Une maison 7x4 (sprite agrandi x1,3). On donne l'ANCIENNE position (coin haut-gauche d'une maison 5x4) : la nouvelle est décalée de (-1, +1),
    donc la porte est au même x et UNE rangée plus bas (x+2, y+4). La caserne/le temple (K, 7x4) ne se décale que d'une rangée : voir `grande`."""
    put(g, c, (x - 1, y + 1))
def grande(g, x, y):
    """La grande maison K (7x4) : porte en (x+3, y+4) ; on donne le x du coin et l'ANCIENNE rangée y."""
    put(g, 'K', (x, y + 1))
def chemin(g, x0, x1, y0, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): g[y][x] = ':'
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
put(place, 'Q', (11, 4)); put(place, 'j', (9, 5), (15, 5))   # girouette 3x4 au centre
# Marché (en bas à gauche) et puits (en bas à droite)
put(place, 'E', (4, 9)); put(place, 'o', (7, 10), (3, 9))
put(place, 'W', (18, 9)); put(place, 'o', (21, 10))
# Fleurs (f tournesol, g fleur rouge, w marguerite) : par petits massifs
put(place, 'f', (8, 2), (9, 3), (16, 3), (22, 9), (10, 11))
put(place, 'g', (15, 2), (14, 11), (8, 3), (2, 6), (7, 5), (17, 4), (21, 5))
put(place, 'w', (9, 2), (16, 2), (2, 10), (3, 11), (15, 11), (11, 11), (22, 10), (2, 2), (7, 4), (22, 5))
# Animaux : 3 poules (c blanche, h rousse) qui picorent sur la place, un chat qui dort devant la maison, un chien
animaux_place = ['c 9 9', 'c 15 10', 'h 14 4', 'k 6 5', 'd 17 8']

TAILLES_MAISONS = {'M': (7, 4), 'N': (7, 4), 'T': (7, 4), 'R': (7, 4), 'S': (7, 4), 'L': (7, 4), 'K': (7, 4), 'U': (7, 4)}

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
    """Forêt dense en haut et en bas : une rangée d'arbres 2x2 + une rangée décalée (seulement si la case est vide).
    `trou` = (x0, x1) : colonnes laissées ouvertes (un chemin qui sort de l'écran)."""
    def ouvert(x): return trou is not None and x <= trou[1] and x + 1 >= trou[0]
    for x in range(0, 24, 2):
        if haut and not ouvert(x): put(g, 'A' if (x // 2) % 2 == 0 else 'a', (x, 0))
        if bas and not ouvert(x): put(g, 'a' if (x // 2) % 2 == 0 else 'A', (x, 12))
    for x in range(1, 23, 2):   # rangée décalée, vers l'intérieur de l'écran
        if haut and not ouvert(x) and g[1][x] == '.': put(g, 'a' if (x // 2) % 2 == 0 else 'A', (x, 1))
        if bas and not ouvert(x) and g[11][x] == '.': put(g, 'A' if (x // 2) % 2 == 0 else 'a', (x, 11))
    put(g, 'b', (24, 12), (24, 13), (24, 0), (24, 1))


bordure(place, trou=(10, 14))   # (la place est construite plus haut ; sa forêt est posée ici)

# --- VILLAGE OUEST (1,2) : deux maisons au nord, un coin potager/marché au sud.
#     Entrée par l'est (la place). L'ouest mène à la ferme (pas encore construite) : fermé par des buissons.
ouest = vide()
chemin(ouest, 0, 24, 6, 8)
chemin(ouest, 4, 5, 6, 6); chemin(ouest, 13, 14, 6, 6)       # devant les portes
bordure(ouest)
maison(ouest, 'M', 3, 2); maison(ouest, 'R', 12, 2)   # portes en (5,6) et (14,6)
for (x, y) in [(0, 2), (0, 4), (21, 2), (23, 4), (0, 10), (22, 10)]:
    put(ouest, 'A' if x % 2 == 0 else 'a', (x, y))
put(ouest, 'P', (8, 2), (18, 3))
put(ouest, 'E', (13, 10)); put(ouest, 'o', (10, 11), (17, 10), (17, 11))
put(ouest, 'j', (9, 5), (16, 5))
put(ouest, 'f', (2, 6 - 1), (7, 4), (19, 5), (3, 11)); put(ouest, 'g', (8, 5), (10, 3), (20, 4), (6, 11), (5, 10))
put(ouest, 'w', (2, 5), (11, 4), (18, 5), (4, 10), (21, 12))
pnjs_ouest = [
    "Woman 10 9 haut | Colette | [fragment_gauche] Tu as rapporté l'aile ?! Vue du ciel, elle a la forme d'une plume géante, dit-on. // Moi, je savais bien que tu réussirais. ## [plume2] Il paraît que tu as allumé des braseros dans le noir ? Tu n'as pas peur de te brûler les moustaches ! ## Oh, tu es la nouvelle recrue ! Tout le village parle de ton épreuve d'adoubement. // On raconte que le donjon sous le temple a la forme d'un grand coq. // Un coq dans un donjon... Moi, je préfère ceux de ma basse-cour !",
    "OldMan 9 7 droite | Vieux Gaspard | [fragment_gauche] Une aile entière... Ton père n'a jamais dépassé la quatrième plume. // Il serait fier. Moi aussi, petite. ## [plume3] Tu as réveillé le chant du coq, alors ? // Les cloches ne mentent jamais : écoute bien avant de frapper. ## Le coq chante chaque aube depuis mille ans. // S'il se taisait un jour, le royaume tremblerait. // Ton père tenait la lance avant toi. Garde-la bien, petite.",
    "Boy 18 5 gauche | Tom | [plume4] On dit que des statues de pierre surveillent la quatrième plume ! // Moi, je me serais caché derrière un pilier. Et toi ? ## Tu as une vraie lance de la garde ! Tu me la prêtes ? // ... Non ? Tant pis. // Un conseil : n'embête pas les poules. Elles se vengent.",
]
animaux_ouest = ['c 6 10', 'h 20 9', 'c 15 12']

# --- VILLAGE EST (3,2) : la CASERNE de la garde royale (bâtiment beige au nord, bannières rouges).
#     Entrée par l'ouest (la place). L'est mène à la maison du héros (pas encore construite) : fermé.
est = vide()
chemin(est, 0, 24, 6, 8)
chemin(est, 11, 13, 6, 6)                                     # devant la porte de la caserne
bordure(est)
grande(est, 10, 2); put(est, 'j', (8, 3), (18, 3))        # caserne 7x4 : porte en (13,6)
put(est, 'o', (6, 3), (6, 4), (18, 3), (19, 4))
for (x, y) in [(0, 2), (0, 4), (2, 9), (22, 2), (22, 9), (20, 11)]:
    put(est, 'A' if y % 4 == 0 else 'a', (x, y))
put(est, 'P', (3, 2), (21, 5))
put(est, 'E', (4, 10)); put(est, 'o', (8, 10), (19, 9))
put(est, 'g', (9, 5), (16, 5), (13, 10), (2, 6)); put(est, 'f', (7, 5), (17, 4), (12, 11))
put(est, 'w', (8, 4), (15, 4), (14, 10), (23, 10), (1, 7))
pnjs_est = [
    "KnightGold 16 6 gauche | Capitaine Aubrac | [fragment_gauche] Une aile complète ! Je n'y croyais plus. // Mais ce n'est que la moitié du blason : l'aile droite t'attend, et au centre, l'épreuve finale. // Repose-toi, recrue. Tu l'as mérité. ## [capitaine_vu] Alors, cette épreuve ? Le temple est au nord du village. // Souviens-toi : observer, réfléchir, et frapper seulement ce qui doit l'être. ## Te voilà enfin, recrue ! L'épreuve d'adoubement t'attend au temple, au nord du village. // Deux ailes et un corps : voilà la forme du donjon. Observe, réfléchis. // Un garde ne se bat pas pour rien : il comprend d'abord. Va, et reviens avec l'honneur. >> capitaine_vu",
    "Villager3 7 7 droite | Soldat Merle | [plume4] La quatrième plume ? Des sentinelles qui tournent la tête ? Brr. Reste dans l'ombre, c'est le conseil d'un vétéran. ## Dix ans de garde et je n'ai jamais vu le fond du donjon. // Les anciens disent que les plumes de l'aile gauche sont de plus en plus longues. Je ne sais pas ce que ça veut dire !",
    "Villager 6 9 haut | Marchande Rosine | Des pommes ! Des pommes de la ferme ! // Les gardes sont mes meilleurs clients... et les pires payeurs.",
]
animaux_est = ['d 20 7', 'c 12 11']
passages_est = ["13 6 InterieurCaserne 12 9"]   # porte de la caserne (maison beige en (10,2)) ; l'intérieur est en bas de la carte

# --- FERME (0,2) : tout à l'ouest. Enclos à poules (clôtures `e`/`z`, cases `k` = intérieur, entrée au sud en (5..6, 8)),
#     grange fermée, la fermière lance la CHASSE AUX POULES (cases `s` = où apparaissent les 6 poules).
ferme = vide()
chemin(ferme, 11, 24, 6, 8)
chemin(ferme, 5, 6, 9, 11)                                     # petit chemin vers l'entrée de l'enclos
bordure(ferme)
put(ferme, 'b', (0, 6), (0, 7), (0, 8))                        # l'ouest : le fleuve, plus tard
for x in (3, 5, 7, 9): put(ferme, 'e', (x, 3))                 # clôture du haut (cases 3 à 10)
put(ferme, 'e', (3, 8), (7, 8)); put(ferme, 'z', (9, 8), (10, 8))   # bas : entrée aux cases 5 et 6
for y in range(4, 8): put(ferme, 'z', (3, y), (10, y))          # côtés
for y in range(4, 8):
    for x in range(4, 10): put(ferme, 'k', (x, y))
put(ferme, 'n', (4, 9))                                        # panneau de l'enclos
maison(ferme, 'L', 17, 2)                                      # grange : porte en (19,6)
put(ferme, 's', (13, 3), (15, 5), (14, 10), (18, 10), (21, 10), (23, 7))
for (x, y) in [(0, 2), (0, 4), (0, 10), (12, 11), (23, 2)]:
    put(ferme, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(ferme, 'x', (12, 4), (13, 4)); put(ferme, 'o', (22, 6), (21, 11))
put(ferme, 'f', (11, 2), (16, 9), (3, 10), (8, 10)); put(ferme, 'g', (12, 3), (20, 9), (2, 7)); put(ferme, 'w', (14, 9), (2, 3), (10, 10), (22, 9))
pnjs_ferme = ["Villager5 12 5 bas | Fermière Jeanne | Oh, par tous les coqs ! Mes poules se sont échappées de l'enclos ! // Tu peux me les ramener ? Approche-toi d'une poule et appuie sur Espace pour la prendre dans tes bras. // Puis appuie encore sur Espace pour la lancer : par-dessus la clôture, ou par l'entrée au sud ! // 5 poules, 60 secondes. Prête ? C'est parti ! | poules"]
passages_ferme = ["19 6 ! La grange est fermée à clé."]

# --- MAISON DU HÉROS (4,2) : tout à l'est du village, au bout du chemin. Le jeu commence DANS la maison.
heros = vide()
chemin(heros, 0, 14, 6, 8)
bordure(heros)
put(heros, 'b', (24, 6), (24, 7), (24, 8))                    # l'est : falaise plus tard
maison(heros, 'N', 11, 2)                                     # la maison bleue : porte en (13,6)
put(heros, 'j', (9, 3), (16, 3))
for (x, y) in [(0, 2), (0, 4), (0, 10), (22, 3), (22, 9), (19, 11), (3, 11)]:
    put(heros, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(heros, 'P', (18, 2), (20, 5), (21, 10))
put(heros, 'o', (9, 4), (14, 4), (16, 9))
put(heros, 'f', (8, 3), (15, 5), (10, 10), (18, 9)); put(heros, 'g', (9, 5), (14, 5), (6, 10), (20, 9))
put(heros, 'w', (13, 3), (8, 11), (17, 6), (4, 9), (21, 7))
animaux_heros = ['c 15 7', 'k 10 6']
passages_heros = ["13 6 InterieurHeros 12 9"]

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
pnjs_int_heros = ["Woman 10 7 bas | Maman | [fragment_gauche] Ma fille, la moitié du blason ! Je vais préparer un grand repas. // Mais d'abord, va te reposer. ## [capitaine_vu] Le capitaine t'a parlé ? Alors file au temple, et fais attention à toi ! ## Bien dormi ? Aujourd'hui, c'est ton grand jour ! // Le capitaine Aubrac t'attend à la caserne, à l'ouest, tout près d'ici. // N'oublie pas la lance de ton père : elle est posée près de la porte. ... Ah, tu l'as déjà. Brave petite !"]
int_caserne = interieur(12, [('G', 7, 5), ('G', 10, 5), ('H', 13, 5), ('J', 15, 5), ('F', 7, 8), ('M', 9, 8), ('D', 15, 8)],
                        ['w', 'z', 'x', 'w', 'x'])
pnjs_int_caserne = ["Villager3 14 7 gauche | Soldat Gilles | Ici dorment les recrues de la garde royale. // Ne touche pas aux lits, on dit qu'ils sont habités... par des puces."]

FERMEE = "La porte est fermée à clé."
ferme_place = ["5 6 ! " + FERMEE, "20 6 ! " + FERMEE]
ferme_ouest = ["5 6 ! " + FERMEE, "14 6 InterieurStand 12 9"]   # la maison rouge est le STAND DE TIR

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
foret_cotes(grand, 9, 15)
put(grand, 'f', (9, 4), (15, 8)); put(grand, 'g', (9, 9), (15, 3)); put(grand, 'w', (9, 6), (15, 10), (9, 12))
put(grand, 'n', (10, 7))                                       # panneau (décor)
animaux_grand = ['c 10 4']

def parvis_commun():
    """Le parvis, commun aux deux versions : chemins, forêt du bord, bannières, fleurs."""
    g = vide()
    chemin(g, 11, 13, 6, 13)                                  # vient du sud
    chemin(g, 0, 24, 6, 8)                                    # vers l'ouest : temple de l'aile gauche ; vers l'est : temple de l'aile droite
    put(g, 'j', (7, 4), (17, 4)); put(g, 'o', (6, 5), (18, 5))
    bordure(g, trou=(11, 13))
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

# APRÈS (drapeau corps_revele) : la forêt s'est écartée, le CORPS DU COQ (grand temple, porte en (12,4)) se dresse ;
#         la stèle, avec les deux ailes, s'est rangée à gauche du passage.
parvis_revele = parvis_commun()
for y in range(0, 4):                       # mêmes arbres que ceux qui s'écartent pendant la cérémonie (world.gd : colonnes 7-18, rangées 0-3)
    for x in range(7, 19): parvis_revele[y][x] = '.'
put(parvis_revele, 'U', (9, 1)); chemin(parvis_revele, 12, 12, 5, 5); put(parvis_revele, 'y', (10, 5))
passages_parvis_revele = ["12 4 ! Le corps du coq... L'épreuve finale se prépare (prochaine étape de la construction).", "10 6 $stele"]

temple_g = vide()
chemin(temple_g, 11, 24, 6, 8)                                 # vient de l'est (le parvis)
chemin(temple_g, 12, 12, 5, 5)                                 # devant la porte du temple
put(temple_g, 'U', (9, 3))                                     # temple de l'aile gauche (arche + marches) : porte en (12,6) -> donjon
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
put(temple_d, 'U', (9, 3))                                     # même arche que l'aile gauche : porte en (12,6) -> aile droite
put(temple_d, 'j', (7, 3), (17, 3)); put(temple_d, 'o', (6, 4), (18, 4))
bordure(temple_d)
put(temple_d, 'b', (24, 6), (24, 7), (24, 8))                  # l'est (falaise, plus tard) : fermé
for (x, y) in [(1, 2), (1, 9), (22, 2), (22, 4), (22, 10), (19, 9)]:
    put(temple_d, 'A' if (x + y) % 4 == 0 else 'a', (x, y))
put(temple_d, 'P', (20, 2), (3, 2)); put(temple_d, 'f', (8, 9), (16, 9)); put(temple_d, 'g', (10, 5), (14, 5)); put(temple_d, 'w', (6, 10), (19, 10))
passages_temple_d = ["12 6 @aile_droite:Vestibule 12 10 La grande porte se referme derrière toi... L'aile droite du blason : ici, tout est inversé."]

ecrans = [
    ('Ferme', (0, 2), ferme, {'pnjs': pnjs_ferme, 'passages': passages_ferme, 'minijeu': 'poules'}),
    ('PlaceDuCoq', (2, 2), place, {'animaux': animaux_place, 'passages': ferme_place}),
    ('VillageOuest', (1, 2), ouest, {'animaux': animaux_ouest, 'pnjs': pnjs_ouest, 'passages': ferme_ouest}),
    ('VillageEst', (3, 2), est, {'animaux': animaux_est, 'pnjs': pnjs_est, 'passages': passages_est}),
    ('MaisonHeros', (4, 2), heros, {'animaux': animaux_heros, 'passages': passages_heros}),
    ('GrandChemin', (2, 1), grand, {'animaux': animaux_grand}),
    ('Parvis', (2, 0), parvis, {'passages': passages_parvis, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg',
        'drapeau_revele': 'corps_revele', 'layout_revele': [''.join(r) for r in parvis_revele], 'passages_revele': passages_parvis_revele,
        'indice': "Une stèle se dresse devant la forêt. Un coq y est gravé, ses ailes creusées dans la pierre..."}),
    ('TempleDroit', (3, 0), temple_d, {'passages': passages_temple_d, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg', 'indice': "Le temple de l'aile droite. Derrière cette porte, la seconde moitié de l'épreuve."}),
    ('TempleGauche', (1, 0), temple_g, {'passages': passages_temple_g, 'musique_ecran': 'res://Assets/Musique/13_magic_temple.ogg', 'indice': "Le temple de l'aile gauche. Derrière cette porte, l'épreuve t'attend."}),
]
# Intérieurs : en bas de la carte (rangée 5), dans une scène à part (Scenes/interieur.tscn)
interieurs = [
    ('InterieurHeros', (4, 5), int_heros, {'pnjs': pnjs_int_heros, 'passages': ["12 10 MaisonHeros 13 7", "14 6 $records"],
        'indice': "Tu te réveilles chez toi. Aujourd'hui, c'est ton adoubement ! Parle à Maman, puis rejoins le capitaine à la caserne (à l'ouest)."}),
    ('InterieurStand', (1, 5), int_stand, {'pnjs': pnjs_int_stand, 'passages': ["12 10 VillageOuest 14 7"], 'minijeu': 'tir'}),
    ('InterieurCaserne', (3, 5), int_caserne, {'pnjs': pnjs_int_caserne, 'passages': ["12 10 VillageEst 13 7"], 'style': 'caserne'}),
]
depart = (4 * 400 + 9 * 16 + 8, 5 * 224 + 6 * 16 + 3)   # nouvelle partie : dans la maison du héros, à côté du lit


for _g in (place, ouest, est, heros, ferme, parvis, parvis_revele, temple_g, temple_d):
    degager_maisons(_g)


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
