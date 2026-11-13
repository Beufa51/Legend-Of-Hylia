"""Outil de développement : écrit Scenes/aile_droite.tscn (AILE DROITE du donjon) à partir des plans ci-dessous.
Usage : python3 Outils/generer_aile_droite.py
Lettres des plans : voir l'en-tête de Scripts/room.gd. Une salle = 25 x 14 cases ; murs du bord de 2 cases.

L'aile droite est le MIROIR de l'aile gauche (voir generer_monde.py) :
  vestibule (0,1) -> entrée (0,0) -> épine qui part vers l'OUEST (-1..-5, 0) avec 5 plumes qui montent,
  de plus en plus longues de DROITE à GAUCHE. Drapeaux : plumeD1..plumeD4, fragment_droite.
Mécaniques (1 nouvelle par plume) : 1 plots orange/bleus, 2 dalles de couleur, 3 glace, 4 reflet (faites) ; prévue : 5 combinaison.
"""
import os
W, H, E = 25, 14, 2
RACINE = os.path.join(os.path.dirname(__file__), "..")


def vide(): return [['#'] * W for _ in range(H)]
def sol(g, x0, x1, y0, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): g[y][x] = '.'
def put(g, c, *pts):
    for (x, y) in pts: g[y][x] = c
def sortie(g): return 'PackedStringArray(' + ', '.join('"' + ''.join(r) + '"' for r in g) + ')'

ECHANGE = {'<': '>', '>': '<', 'M': 'N', 'N': 'M'}
def miroir(g):
    """Retourne le plan gauche-droite (les sentinelles et les miroirs changent de sens)."""
    return [[ECHANGE.get(c, c) for c in reversed(ligne)] for ligne in g]


# --- Vestibule (0,1) : on entre ici depuis le temple de l'aile droite. Leçon : LA CLÉ. La porte de bois du nord (E)
#     est fermée à clé ; la clé est dans le coffre (Q), qu'on ouvre d'un coup de lance.
vest = vide(); sol(vest, 2, 22, 2, 11); sol(vest, 11, 13, 0, 1)
for x in (11, 12, 13): vest[0][x] = 'E'; vest[1][x] = 'E'
put(vest, 'Q', (19, 8))
for x in (11, 12, 13): vest[12][x] = 'H'; vest[13][x] = 'H'   # grande porte du sud = sortie (s'ouvre avec le fragment)
put(vest, 'B', (6, 4), (18, 4)); put(vest, 'V', (3, 10), (21, 10), (7, 9), (17, 9), (3, 3), (21, 3))
put(vest, 'S', (9, 6)); put(vest, 'O', (15, 6))
for x in range(11, 14):
    for y in range(2, 12): put(vest, 'T', (x, y))

# --- Entrée (0,0) : grande salle, porte au sud (vers le vestibule) et sortie à l'OUEST (rangées 5-8).
#     Leçon : LE LEVIER. La grille de l'ouest (D) s'ouvre quand on bascule le levier (J) d'un coup de lance.
#     Deux bassins d'eau (~) décorent la salle.
ent = vide(); sol(ent, 2, 22, 2, 11); sol(ent, 0, 1, 5, 8); sol(ent, 11, 13, 12, 13)
for y in range(5, 9): ent[y][1] = 'D'
put(ent, 'B', (3, 3), (21, 3), (3, 10), (21, 10)); put(ent, 'O', (5, 4)); put(ent, 'S', (19, 4))
put(ent, 'V', (4, 11), (20, 11), (21, 6))
put(ent, 'J', (4, 9))
for x in range(6, 19): put(ent, 'T', (x, 6), (x, 7))
for y in (9, 10):
    for x in (7, 8, 9, 15, 16, 17): put(ent, '~', (x, y))


# --- Épine : couloir horizontal (rangées 5-8) + tige vers le haut (colonnes 11-13). Plan écrit « à l'endroit »
#     (comme l'aile gauche) puis retourné par miroir() : la porte se retrouve à l'OUEST (colonne 1).
def epine(porte=False, ferme=False, tige=True):
    g = vide(); sol(g, 0, 24, 5, 8)
    if tige: sol(g, 11, 13, 0, 4)
    put(g, 'B', (6, 5), (18, 5))
    for x in range(2, 23):
        if not (11 <= x <= 13): put(g, 'T', (x, 7))
    if porte:
        for y in range(5, 9): g[y][23] = 'D'
    if ferme:
        for y in range(5, 9): g[y][23] = '#'; g[y][24] = '#'
    return miroir(g)


e1 = epine(porte=True)            # la porte ouest s'ouvre quand la plume D1 est obtenue
e2 = epine(porte=True)            # la porte ouest s'ouvre quand la plume D2 est obtenue
# Dans l'épine 2, deux colonnes de PICS (Z) barrent le couloir entre l'entrée (à l'est) et la tige de la plume D2 :
# elles sortent à tour de rôle ; il faut passer au bon moment. Touché = retour à l'entrée de l'épine (23,6).
for y in range(5, 9):
    for x in (16, 19): e2[y][x] = 'Z'
RETOUR_E2 = 'Vector2(%d, %d)' % (-2 * 400 + 23 * 16 + 8, 6 * 16 + 3)
e3 = epine(porte=True)            # la porte ouest s'ouvre quand la plume D3 est obtenue
e4 = epine(porte=True)            # la porte ouest s'ouvre quand la plume D4 est obtenue
e5 = epine(ferme=True, tige=False)   # PROVISOIRE : cul-de-sac tant que la plume D5 n'est pas construite

# --- PLUME D1 : « LES PLOTS ». Leçon : le cristal commute les plots orange (o) et bleus (u).
#     Au départ : orange LEVÉS (la barrière de la rangée 9 bloque), bleus BAISSÉS (la grille bleue du nord est ouverte).
#     1) Frapper le cristal depuis le sud : la barrière orange se baisse... mais les bleus se lèvent au nord.
#     2) Passer, puis frapper le cristal DE L'AUTRE CÔTÉ : la barrière orange se relève derrière soi, les bleus se baissent.
p1 = vide(); sol(p1, 2, 22, 2, 11); sol(p1, 11, 13, 12, 13)
for x in range(2, 23): p1[5][x] = '#'
for x in (11, 12, 13): p1[5][x] = 'u'                       # « porte » de plots bleus vers l'alcôve de la plume
put(p1, 'G', (12, 3)); put(p1, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p1, 'T', (x, 4))
for x in range(2, 23): p1[9][x] = 'o'                       # barrière de plots orange
put(p1, 'K', (12, 9))                                       # le cristal, DANS la barrière : on le frappe des deux côtés
put(p1, 'V', (3, 11), (21, 11), (3, 6), (21, 6)); put(p1, 'S', (6, 7)); put(p1, 'O', (18, 7))
for x in range(10, 15): put(p1, 'T', (x, 11))

# --- PLUME D2 : « LES DALLES DE COULEUR » (façon Zelda). Chaque pas sur une dalle z la retourne : rouge -> bleue,
#     bleue -> rouge. Il faut rendre TOUTES les dalles bleues (donc passer une seule fois sur chacune, ou un nombre impair de fois).
#     R remet tout en rouge. Toutes bleues : la grille s'ouvre et les dalles restent bleues.
def retour_d2(n):   # bas de l'écran n de la plume D2 (case (12,12)), en position dans le monde
    return 'Vector2(%d, %d)' % (-2 * 400 + 12 * 16 + 8, -224 * n + 194)

# D2a (en bas) : leçon. Un champ de 5 x 4 dalles traverse la salle ; un serpentin suffit (on peut aussi sortir et revenir).
p2a = vide(); sol(p2a, 2, 22, 2, 3); sol(p2a, 2, 22, 8, 11); sol(p2a, 11, 13, 12, 13); sol(p2a, 11, 13, 0, 1)
for x in (11, 12, 13): p2a[0][x] = 'D'; p2a[1][x] = 'D'
for y in range(4, 8):
    for x in range(10, 15): p2a[y][x] = 'z'
put(p2a, 'V', (3, 11), (21, 11), (3, 2), (21, 2)); put(p2a, 'S', (8, 9)); put(p2a, 'O', (16, 9)); put(p2a, 'B', (5, 9), (19, 9))

# D2b (la pointe) : 34 dalles autour de 2 piliers, une seule entrée (par le bas). Dès que toutes sont bleues, la grille de l'alcôve
#     s'ouvre. Il existe des chemins qui passent une seule fois par chaque dalle (vérifié par un solveur).
p2b = vide(); sol(p2b, 2, 22, 2, 4); sol(p2b, 2, 22, 10, 11); sol(p2b, 11, 13, 12, 13)
for x in range(2, 23): p2b[5][x] = '#'
for x in (11, 12, 13): p2b[5][x] = 'D'
put(p2b, 'G', (12, 3)); put(p2b, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p2b, 'T', (x, 4))
for y in range(6, 10):
    for x in range(8, 17): p2b[y][x] = 'z'
put(p2b, '#', (10, 7), (14, 8))
put(p2b, 'V', (3, 11), (21, 11), (3, 10), (21, 10)); put(p2b, 'S', (5, 2)); put(p2b, 'O', (19, 2))

# --- PLUME D3 : « LA GLACE ». Sur la glace (i), on glisse tout droit jusqu'à un obstacle (ou jusqu'au sol normal).
#     Un bloc poussé sur la glace glisse aussi. Un plot BAISSÉ n'est pas glissant : on s'arrête dessus.
#     R = retour au début de la salle (on peut se coincer). Les 3 salles ont été vérifiées par un solveur (mêmes règles) :
#     3a = 3 glissades ; 3b = 12 coups dont 2 poussées (impossible sans le bloc) ; 3c = 13 coups (impossible sans le cristal).
def retour_d3(n):   # bas de l'écran n de la plume D3 (case (12,11), sol normal), en position dans le monde
    return 'Vector2(%d, %d)' % (-3 * 400 + 12 * 16 + 8, -224 * n + 11 * 16 + 3)

def champ_de_glace(g):
    """Glace sur les rangées 3 à 10, sol normal rangée 11, entrée en bas, sortie en haut (rangées 0-2, colonnes 11-13)."""
    for y in range(3, 11):
        for x in range(2, 23): g[y][x] = 'i'
    sol(g, 2, 22, 11, 11); sol(g, 11, 13, 12, 13); sol(g, 11, 13, 0, 2)

# D3a (leçon) : monter, glisser à droite contre le rocher, remonter. La colonne du milieu est fermée en bas.
p3a = vide(); champ_de_glace(p3a)
put(p3a, '#', (11, 10), (12, 10), (13, 10), (13, 3), (6, 7), (18, 6), (16, 9))
put(p3a, 'V', (2, 11), (22, 11)); put(p3a, 'S', (5, 11)); put(p3a, 'O', (19, 11))

# D3b : la sortie ne s'atteint qu'en remontant la colonne 12 ; aucun rocher ne permet de s'y arrêter : il faut
#      d'abord pousser le BLOC (il monte jusqu'au rocher (16,5)), puis le pousser à gauche (il s'arrête contre (10,6)).
p3b = vide(); champ_de_glace(p3b)
put(p3b, '#', (12, 10), (11, 3), (13, 3), (16, 5), (17, 5), (10, 6), (4, 8), (20, 9), (6, 4))
put(p3b, 'X', (16, 9))
put(p3b, 'V', (2, 11), (22, 11)); put(p3b, 'O', (5, 11))

# D3c (la pointe) : glace + PLOTS + CRISTAL. L'alcôve de la plume (rangées 2-3) ne s'ouvre que par (12,4), qu'on atteint
#      en remontant la colonne 12. Le cristal (21,8) se frappe depuis la glace : il lève le plot bleu (13,8), qui devient la butée.
p3c = vide()
sol(p3c, 9, 15, 2, 3); put(p3c, '.', (12, 4))
for y in range(5, 11):
    for x in range(2, 23): p3c[y][x] = 'i'
sol(p3c, 2, 22, 11, 11); sol(p3c, 11, 13, 12, 13)
put(p3c, '#', (12, 10), (11, 5), (13, 5), (7, 6), (18, 9), (4, 9), (20, 5), (2, 7))
put(p3c, 'o', (16, 7), (9, 9), (5, 8)); put(p3c, 'u', (13, 8), (10, 6)); put(p3c, 'K', (21, 8))
put(p3c, 'G', (12, 2)); put(p3c, 'B', (9, 2), (15, 2))
for x in range(10, 15): put(p3c, 'T', (x, 3))
put(p3c, 'V', (2, 11), (22, 11))

# --- PLUME D4 : « LE REFLET ». Un double fantôme (part de la case r) fait les mêmes gestes que le joueur, gauche et droite
#     INVERSÉES. Bloqué par un mur pendant que le joueur avance, il se décale. Dalles du reflet (a) : toutes occupées en même
#     temps (joueur + reflet) = drapeau ; le reflet enfonce aussi les boutons (P). R = retour au début (reflet compris).
#     Vérifié par un solveur (modèle par cases) : 4a = 6 coups, 4b = 9, 4c = 41, 4d = 30.
def retour_d4(n):   # bas de l'écran n de la plume D4 (case (12,11)), en position dans le monde
    return 'Vector2(%d, %d)' % (-4 * 400 + 12 * 16 + 8, -224 * n + 11 * 16 + 3)

def salle_reflet(sortie):
    """Salle ouverte en bas ; en haut (rangées 0-1, colonnes 11-13) une porte de la lettre `sortie`."""
    g = vide(); sol(g, 2, 22, 2, 11); sol(g, 11, 13, 12, 13); sol(g, 11, 13, 0, 1)
    for x in (11, 12, 13): g[0][x] = sortie; g[1][x] = sortie
    return g

# D4a (leçon) : 4 pas à droite et 2 en haut, et chacun est sur sa dalle.
p4a = salle_reflet('D'); put(p4a, 'r', (6, 4)); put(p4a, 'a', (16, 9), (2, 2))
put(p4a, 'V', (22, 11), (2, 11)); put(p4a, 'B', (20, 3)); put(p4a, 'S', (9, 7))

# D4b : il faut un décalage vertical : bloquer le reflet sous le mur (15-21, 3) pendant qu'on monte.
p4b = salle_reflet('D'); put(p4b, 'r', (12, 5)); put(p4b, 'a', (6, 8), (18, 4))
for x in range(15, 22): p4b[3][x] = '#'
put(p4b, '#', (4, 5), (8, 10), (20, 9)); put(p4b, 'V', (2, 11), (22, 11))

# D4c : le reflet doit entrer dans la niche du bouton (P), en haut à gauche (ouverte seulement par (5,3)) : la herse du haut s'ouvre.
p4c = salle_reflet('H'); put(p4c, 'r', (19, 9)); put(p4c, 'P', (3, 3))
put(p4c, '#', (2, 5), (3, 5), (4, 5), (5, 5), (5, 4), (5, 2))
put(p4c, '#', (8, 3), (8, 4), (8, 7), (9, 7), (10, 7), (15, 9), (16, 9), (17, 6), (18, 6), (21, 4), (14, 3))
put(p4c, 'V', (22, 11), (2, 11))

# D4d (pointe, SOMBRE) : le reflet enfonce le bouton (P) -> la herse H de l'enclos s'ouvre ; le joueur sur la dalle de l'enclos
#      ET le reflet sur l'autre -> la grille D de l'alcôve s'ouvre -> plume.
p4d = vide(); sol(p4d, 2, 22, 6, 11); sol(p4d, 11, 13, 12, 13)
sol(p4d, 9, 15, 2, 4); put(p4d, 'D', (11, 5), (12, 5), (13, 5))
for x in range(16, 23): p4d[8][x] = '#'
put(p4d, 'H', (18, 8), (19, 8), (20, 8)); put(p4d, '#', (16, 6), (16, 7))
put(p4d, 'a', (21, 6), (4, 10)); put(p4d, 'P', (3, 6)); put(p4d, 'r', (8, 9))
put(p4d, '#', (6, 7), (7, 7), (10, 10), (13, 7), (5, 9))
put(p4d, 'G', (12, 3)); put(p4d, 'B', (9, 2), (15, 2))
for x in range(10, 15): put(p4d, 'T', (x, 4))

salles = [
    ('Vestibule', (0, 1), vest, (0.98, 0.95, 1.06), {'drapeau_porte2': 'fragment_droite',
        'drapeau_coffre': 'd_cle_vestibule', 'drapeau_cle': 'd_cle_vestibule', 'drapeau_serrure': 'd_porte_vestibule',
        'indice': "L'aile droite du blason. La porte est fermée à clé... ce coffre, peut-être ? Un coup de lance l'ouvre."}),
    ('Entree', (0, 0), ent, (1.0, 0.94, 0.92), {'drapeau_levier': 'd_levier_entree', 'drapeau_porte': 'd_levier_entree',
        'indice': "Un levier ! Bascule-le d'un coup de lance pour ouvrir la grille de l'ouest."}),
    ('Epine1', (-1, 0), e1, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD1'}),
    ('PlumeD1', (-1, -1), p1, (0.98, 0.94, 1.06), {'drapeau_gemme': 'plumeD1',
        'indice': "Ce cristal commande les plots de couleur : un coup de lance, et les levés se baissent... et les baissés se lèvent !"}),
    ('Epine2', (-2, 0), e2, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD2', 'retour': RETOUR_E2,
        'indice': "Des pics ! Observe leur rythme : passe quand ils sont rentrés."}),
    ('PlumeD2a', (-2, -1), p2a, (1.0, 0.97, 0.92), {'drapeau_fragile': 'd2_sol1', 'drapeau_porte': 'd2_sol1', 'retour': retour_d2(1),
        'indice': "Chaque pas retourne une dalle : rouge -> bleue, bleue -> rouge. Rends-les TOUTES bleues pour ouvrir la grille."}),
    ('PlumeD2b', (-2, -2), p2b, (0.98, 0.95, 0.9), {'drapeau_fragile': 'd2_sol2', 'drapeau_porte': 'd2_sol2', 'retour': retour_d2(2),
        'drapeau_gemme': 'plumeD2', 'indice': "Plus de dalles, deux piliers, et une seule entrée : repasser sur une dalle bleue la remet en rouge. Trace ton chemin avant de partir..."}),
    ('Epine3', (-3, 0), e3, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD3'}),
    ('PlumeD3a', (-3, -1), p3a, (0.92, 0.98, 1.08), {'retour': retour_d3(1),
        'indice': "De la glace ! Une fois lancé, tu glisses tout droit jusqu'à un obstacle. R pour recommencer."}),
    ('PlumeD3b', (-3, -2), p3b, (0.9, 0.97, 1.1), {'retour': retour_d3(2),
        'indice': "Aucun rocher au bon endroit... Un bloc poussé sur la glace glisse, lui aussi."}),
    ('PlumeD3c', (-3, -3), p3c, (0.94, 0.96, 1.1), {'retour': retour_d3(3), 'drapeau_gemme': 'plumeD3',
        'indice': "Un plot baissé n'est pas glissant : on s'y arrête. Et le cristal fait monter les plots bleus..."}),
    ('Epine4', (-4, 0), e4, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD4'}),
    ('PlumeD4a', (-4, -1), p4a, (0.96, 0.94, 1.08), {'retour': retour_d4(1), 'drapeau_reflet': 'd4_reflet1', 'drapeau_porte': 'd4_reflet1',
        'indice': "Ton REFLET ! Il fait tes gestes, mais la gauche et la droite inversées. Mettez-vous chacun sur une dalle."}),
    ('PlumeD4b', (-4, -2), p4b, (0.95, 0.93, 1.06), {'retour': retour_d4(2), 'drapeau_reflet': 'd4_reflet2', 'drapeau_porte': 'd4_reflet2',
        'indice': "Quand un mur arrête ton reflet, toi tu continues : vous vous décalez. R pour recommencer."}),
    ('PlumeD4c', (-4, -3), p4c, (0.94, 0.95, 1.08), {'retour': retour_d4(3), 'drapeau_plaque': 'd4_bouton', 'drapeau_porte2': 'd4_bouton',
        'indice': "Le bouton est hors de ta portée... mais pas de celle de ton reflet."}),
    ('PlumeD4d', (-4, -4), p4d, (1.0, 1.0, 1.0), {'sombre': 'true', 'retour': retour_d4(4), 'drapeau_plaque': 'd4_bouton2', 'drapeau_porte2': 'd4_bouton2',
        'drapeau_reflet': 'd4_reflet3', 'drapeau_porte': 'd4_reflet3', 'drapeau_gemme': 'plumeD4',
        'indice': "Dans le noir, ton reflet luit. Un bouton, une herse, deux dalles..."}),
    ('Epine5', (-5, 0), e5, (0.90, 0.88, 0.98), {}),
]
depart = (200, 224 + 180)   # (seulement si on lance la scène directement : sinon on arrive par le temple)

out = '''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://Scripts/world.gd" id="1"]
[ext_resource type="PackedScene" path="res://Scenes/room.tscn" id="2"]
[ext_resource type="PackedScene" path="res://Scenes/player.tscn" id="3"]

; FICHIER GÉNÉRÉ par Outils/generer_aile_droite.py : modifie les plans là-bas, pas ici.
; AILE DROITE (en construction) : vestibule (0,1) -> entrée (0,0) -> épine vers l'ouest (-1..-5, 0), 5 plumes qui montent.

[node name="World" type="Node2D"]
script = ExtResource("1")
cote = "droite"
'''
for nom, (gx, gy), g, c, ex in salles:
    out += '\n[node name="%s" parent="." instance=ExtResource("2")]\n' % nom
    if (gx, gy) != (0, 0): out += 'grille = Vector2i(%d, %d)\n' % (gx, gy)
    out += 'teinte = Color(%s, %s, %s, 1)\n' % c
    for k, v in ex.items():
        # Même règle que generer_monde.py : les mélodies ("132") restent des TEXTES.
        brut = v == 'true' or v.startswith(('Vector2(', 'PackedFloat32Array(')) or ('.' in v and v.replace('.', '').isdigit())
        out += ('%s = %s\n' % (k, v)) if brut else ('%s = "%s"\n' % (k, v.replace('"', '\\"')))
    out += 'layout = %s\n' % sortie(g)
out += '''
[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % depart
open(os.path.join(RACINE, 'Scenes', 'aile_droite.tscn'), 'w', encoding='utf-8').write(out)
print("aile_droite.tscn écrit :", [s[0] for s in salles])
