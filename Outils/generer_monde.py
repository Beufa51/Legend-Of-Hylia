"""Outil de développement : écrit Scenes/world.tscn (aile gauche) à partir des plans ci-dessous.
Usage : python3 Outils/generer_monde.py
Lettres des plans : voir l'en-tête de Scripts/room.gd. Une salle = 25 x 14 cases ; murs du bord de 2 cases."""
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


# --- Vestibule (0,1) : on commence ici. Leçon : frapper le cristal avec la lance ouvre la porte du nord.
vest = vide(); sol(vest, 2, 22, 2, 11); sol(vest, 11, 13, 0, 1)
for x in (11, 12, 13): vest[0][x] = 'D'; vest[1][x] = 'D'   # porte de 3 x 2 cases
for x in (11, 12, 13): vest[12][x] = 'H'; vest[13][x] = 'H'   # grande porte du sud = sortie du donjon (s'ouvre avec le fragment)
put(vest, 'K', (12, 7))
put(vest, 'B', (6, 4), (18, 4)); put(vest, 'V', (3, 10), (21, 10), (7, 9), (17, 9), (3, 3), (21, 3))
for x in range(11, 14):
    for y in range(8, 12): put(vest, 'T', (x, y))

# --- Entrée (0,0) : grande salle, porte au sud (vers le vestibule) et sortie à l'est (rangées 5-8)
ent = vide(); sol(ent, 2, 22, 2, 11); sol(ent, 23, 24, 5, 8); sol(ent, 11, 13, 12, 13)
put(ent, 'B', (3, 3), (21, 3), (3, 10), (21, 10)); put(ent, 'S', (5, 4)); put(ent, 'O', (19, 4))
put(ent, 'V', (4, 11), (20, 11), (3, 6), (21, 6))
for x in range(6, 19): put(ent, 'T', (x, 6), (x, 7))


# --- Épine : couloir horizontal (rangées 5-8) + tige vers le haut (colonnes 11-13)
def epine(est_ferme=False, porte_est=False, tige=True):
    g = vide(); sol(g, 0, 24, 5, 8)
    if tige: sol(g, 11, 13, 0, 4)
    put(g, 'B', (6, 5), (18, 5))
    for x in range(2, 23):
        if not (11 <= x <= 13): put(g, 'T', (x, 7))
    if porte_est:
        for y in range(5, 9): g[y][23] = 'D'   # porte de 1 x 4 cases
    if est_ferme:
        for y in range(5, 9): g[y][23] = '#'; g[y][24] = '#'
    return g


e1 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 1 est obtenue
e2 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 2 est obtenue
e3 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 3 est obtenue
e4 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 4 est obtenue
e5 = epine(est_ferme=True)            # dernière épine : fermée à l'est, la tige monte vers la plume 5 (pointe de l'aile)

# --- Plume 1 : bloc + bouton (leçon : pousser un bloc ; le pot sert à dégager le chemin)
p1 = vide(); sol(p1, 2, 22, 2, 11); sol(p1, 11, 13, 12, 13)
for x in range(2, 23): p1[5][x] = '#'
for x in (11, 12, 13): p1[5][x] = 'D'
put(p1, 'G', (12, 3)); put(p1, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p1, 'T', (x, 4))
put(p1, 'P', (5, 6)); put(p1, 'X', (16, 9)); put(p1, 'V', (10, 9), (3, 11), (21, 11)); put(p1, 'S', (20, 7)); put(p1, 'O', (3, 7))
for (x, y) in [(8, 7), (8, 8)]: p1[y][x] = '#'

# --- Plume 2, écran du bas : SALLE SOMBRE. 4 braseros (L) à allumer à la lance, tous en même temps
#     (chacun s'éteint au bout de 14 s). Leçon : la lance allume ; on s'organise dans le noir.
p2a = vide(); sol(p2a, 2, 22, 2, 11); sol(p2a, 11, 13, 12, 13); sol(p2a, 11, 13, 0, 1)
for x in (11, 12, 13): p2a[0][x] = 'D'; p2a[1][x] = 'D'
put(p2a, 'L', (4, 3), (20, 3), (4, 10), (20, 10))
for (x0, y0) in [(8, 4), (16, 4), (8, 8), (16, 8)]:
    for dx in (0, 1):
        for dy in (0, 1): p2a[y0 + dy][x0 + dx] = '#'
put(p2a, 'V', (12, 6), (6, 7), (18, 7), (3, 6), (21, 6))

# --- Plume 2, écran du haut (la pointe) : un cristal à frapper ouvre la porte de l'alcôve où est la plume
p2b = vide(); sol(p2b, 2, 22, 2, 11); sol(p2b, 11, 13, 12, 13)
for x in range(2, 23): p2b[5][x] = '#'
for x in (11, 12, 13): p2b[5][x] = 'D'
put(p2b, 'G', (12, 3)); put(p2b, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p2b, 'T', (x, 4))
put(p2b, 'K', (4, 8)); put(p2b, 'S', (20, 7)); put(p2b, 'O', (3, 11)); put(p2b, 'V', (21, 11), (12, 9), (8, 7))

# --- PLUME 3 : « LE CHANT DU COQ ». Frapper la statue du coq (C) : elle chante une mélodie et chaque cloche
#     s'allume quand sa note passe. Il faut rejouer la mélodie sur les cloches (1 à 5) avec la lance.
def plume_bas_haut(g):
    """Salle d'une plume avec une ouverture en bas (vers l'écran du dessous) et une grille en haut."""
    sol(g, 2, 22, 2, 11); sol(g, 11, 13, 12, 13); sol(g, 11, 13, 0, 1)
    for x in (11, 12, 13): g[0][x] = 'D'; g[1][x] = 'D'

# 3a (en bas) : leçon, 3 cloches, 3 notes
p3a = vide(); plume_bas_haut(p3a)
put(p3a, 'C', (12, 8))
for y in (9, 10, 11): put(p3a, 'T', (11, y), (12, y), (13, y))
put(p3a, '3', (6, 5)); put(p3a, '2', (18, 5)); put(p3a, '1', (12, 4))
put(p3a, 'B', (3, 3), (21, 3)); put(p3a, 'V', (3, 11), (21, 11), (4, 8)); put(p3a, 'S', (20, 8))

# 3b (au milieu) : 4 cloches, 4 notes ; la cloche 3 est dans une niche, cachée derrière un bloc à pousser
p3b = vide(); plume_bas_haut(p3b)
put(p3b, 'C', (12, 9))
for y in (10, 11): put(p3b, 'T', (11, y), (12, y), (13, y))
put(p3b, '#', (16, 2), (18, 2)); put(p3b, '3', (17, 2)); put(p3b, 'X', (17, 3))
put(p3b, '2', (5, 4)); put(p3b, '1', (5, 9)); put(p3b, '4', (19, 9))
put(p3b, '#', (8, 6), (16, 6))
put(p3b, 'V', (3, 11), (21, 11), (21, 3)); put(p3b, 'O', (3, 2)); put(p3b, 'B', (9, 2))

# 3c (la pointe) : SALLE SOMBRE, 5 cloches, 5 notes : il faut repérer dans le noir les cloches qui s'allument.
#     La mélodie ouvre l'alcôve où se trouve la plume.
p3c = vide(); sol(p3c, 2, 22, 2, 11); sol(p3c, 11, 13, 12, 13)
for x in range(2, 23): p3c[5][x] = '#'
for x in (11, 12, 13): p3c[5][x] = 'D'
put(p3c, 'G', (12, 3)); put(p3c, 'V', (5, 3), (19, 3), (3, 2), (21, 2))
for x in range(10, 15): put(p3c, 'T', (x, 4))
put(p3c, 'C', (12, 9))
put(p3c, '3', (4, 7)); put(p3c, '1', (8, 10)); put(p3c, '5', (16, 10)); put(p3c, '2', (20, 7)); put(p3c, '4', (16, 6))
put(p3c, 'V', (3, 11), (21, 11))

# --- PLUME 4 : « LES SENTINELLES ». Des statues de garde (^ v < >) surveillent les cases éclairées devant elles.
#     Le regard s'arrête aux obstacles. Repéré = un garde te ramène à l'entrée de la plume (bas de 4a).
def plume_ouverte(g):
    """Salle d'une plume ouverte en bas et en haut (pas de grille : les sentinelles suffisent)."""
    sol(g, 11, 13, 12, 13); sol(g, 11, 13, 0, 1)

# 4a (en bas) : leçon. Une sentinelle fixe surveille le passage ; on passe dans l'ombre du pilier (à droite).
p4a = vide(); plume_ouverte(p4a); sol(p4a, 2, 22, 2, 11)
for y in range(3, 8):
    for x in list(range(2, 7)) + list(range(14, 23)): p4a[y][x] = '#'
put(p4a, '>', (6, 5)); put(p4a, '#', (11, 4), (11, 5), (11, 6))
put(p4a, 'B', (3, 2), (21, 2)); put(p4a, 'V', (3, 11), (21, 11), (4, 8), (20, 8)); put(p4a, 'S', (8, 9), (16, 9))

# 4b : deux sentinelles qui tournent la tête (toutes les 2 s et toutes les 3 s) : observer le rythme, courir au bon moment.
p4b = vide(); plume_ouverte(p4b); sol(p4b, 6, 18, 2, 8); sol(p4b, 2, 22, 10, 11)
for x in (7, 17): p4b[9][x] = '.'
put(p4b, '^', (12, 6)); put(p4b, 'v', (12, 3))
put(p4b, 'V', (3, 11), (21, 11), (2, 10), (22, 10)); put(p4b, 'B', (9, 11), (15, 11))

# 4c : un long couloir surveillé : pousser le bloc devant soi pour rester caché derrière lui.
p4c = vide(); plume_ouverte(p4c); sol(p4c, 2, 22, 8, 11); sol(p4c, 2, 22, 2, 2)
sol(p4c, 12, 12, 6, 7); sol(p4c, 6, 12, 5, 5); sol(p4c, 7, 7, 3, 4)
put(p4c, '>', (5, 5)); put(p4c, 'X', (11, 5))
put(p4c, 'V', (3, 11), (21, 11), (3, 8), (21, 8)); put(p4c, 'S', (8, 8), (16, 8)); put(p4c, 'B', (3, 2), (21, 2))

# 4d (la pointe) : SALLE SOMBRE. Deux sentinelles se font face et gardent le passage vers la plume.
#     Une flamme attire leur regard : le brasero de gauche fait tourner la tête de la sentinelle de gauche,
#     celui de droite la sentinelle de droite. Les deux allumés -> le passage du milieu n'est plus surveillé.
#     La rangée du bas (11) n'est jamais vue : on peut aller allumer les braseros sans risque.
p4d = vide(); sol(p4d, 2, 22, 6, 11); sol(p4d, 11, 13, 12, 13); sol(p4d, 2, 22, 2, 4); sol(p4d, 12, 12, 5, 5)
put(p4d, '>', (7, 7)); put(p4d, '<', (17, 7)); put(p4d, 'L', (3, 10), (21, 10)); put(p4d, 'G', (12, 3))
put(p4d, 'V', (3, 2), (21, 2), (2, 6), (22, 6))
for x in range(10, 15): put(p4d, 'T', (x, 4))
RETOUR_P4 = 'Vector2(1800, -30)'   # entrée de la plume 4 (bas de l'écran 4a, case (12,12))
REPOS_P4 = 'plume4'                # une fois la plume obtenue, les sentinelles ne surveillent plus

# --- PLUME 5 : « LE PIVOT ». Un soleil (R) incrusté dans le mur lance un rayon de lumière. Les miroirs (M = /, N = \\)
#     pivotent d'un coup de lance. Il faut guider le rayon jusqu'au réceptacle (Y).
def plume_grille(g):
    """Écran de plume : ouvert en bas, grille D en haut."""
    sol(g, 2, 22, 2, 11); sol(g, 11, 13, 12, 13); sol(g, 11, 13, 0, 1)
    for x in (11, 12, 13): g[0][x] = 'D'; g[1][x] = 'D'

# 5a (leçon) : 1 miroir. Le rayon part vers le haut ; un coup de lance et il descend vers le réceptacle.
p5a = vide(); plume_grille(p5a)
put(p5a, 'R', (1, 4)); put(p5a, 'M', (17, 4)); put(p5a, 'Y', (17, 9))
put(p5a, 'V', (3, 11), (21, 11), (21, 2)); put(p5a, 'S', (6, 8)); put(p5a, 'B', (3, 2))

# 5b : 3 miroirs et un faux chemin : le rayon monte tout droit vers le haut... mais un pilier l'arrête.
#      Il faut le faire descendre, longer le bas de la salle et remonter à droite.
p5b = vide(); plume_grille(p5b)
put(p5b, 'R', (1, 9)); put(p5b, 'M', (11, 9), (11, 11)); put(p5b, 'N', (20, 11)); put(p5b, 'Y', (20, 4))
put(p5b, '#', (11, 5), (10, 5), (12, 5))
put(p5b, 'V', (3, 3), (21, 2), (3, 11)); put(p5b, 'O', (16, 7)); put(p5b, 'B', (6, 3))

# 5c : le bloc COUPE le rayon. Au départ, le bloc est posé en plein dans le rayon (on voit le rayon s'arrêter dessus).
#      Le pousser jusqu'au bouton (à droite) fait d'une pierre deux coups : le rayon passe ET la grille H s'ouvre.
p5c = vide(); plume_grille(p5c)
put(p5c, 'R', (1, 4)); put(p5c, 'N', (18, 4)); put(p5c, 'X', (18, 6)); put(p5c, 'P', (21, 6))
for x in range(15, 23): p5c[9][x] = '#'
for y in (10, 11): p5c[y][15] = '#'
for x in (17, 18, 19): p5c[9][x] = 'H'
put(p5c, 'Y', (18, 11))
put(p5c, 'V', (3, 11), (3, 2), (21, 2), (16, 11)); put(p5c, 'S', (8, 8)); put(p5c, 'B', (6, 10))

# 5d : SALLE SOMBRE, 3 miroirs (+ 2 leurres). Le rayon est la seule vraie lumière : il éclaire le chemin qu'on lui fait prendre.
p5d = vide(); plume_grille(p5d)
put(p5d, 'R', (1, 10)); put(p5d, 'N', (6, 10), (6, 3)); put(p5d, 'M', (17, 3), (12, 7)); put(p5d, 'N', (20, 10)); put(p5d, 'Y', (17, 8))
put(p5d, '#', (9, 6), (9, 7), (14, 5), (14, 6), (20, 5))
put(p5d, 'V', (3, 2), (21, 2), (3, 6))

# 5e (POINTE DE L'AILE) : le coq ne chante qu'au soleil. Dégager le bloc du rayon, régler 2 miroirs pour éclairer
#      la statue : elle chante. Rejouer la mélodie sur les cloches : l'alcôve s'ouvre -> FRAGMENT de l'aile gauche (W).
p5e = vide(); sol(p5e, 2, 22, 2, 11); sol(p5e, 11, 13, 12, 13)
for x in range(2, 23): p5e[5][x] = '#'
for x in (11, 12, 13): p5e[5][x] = 'D'
put(p5e, 'W', (12, 3)); put(p5e, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p5e, 'T', (x, 4))
put(p5e, 'R', (1, 10)); put(p5e, 'X', (5, 10)); put(p5e, 'N', (9, 10), (9, 7)); put(p5e, 'C', (16, 7))
put(p5e, '1', (4, 7)); put(p5e, '2', (20, 10)); put(p5e, '3', (14, 10)); put(p5e, '4', (20, 7))
put(p5e, 'V', (21, 6), (3, 6))

salles = [
    ('Vestibule', (0, 1), vest, (0.92, 0.97, 1.05), {'drapeau_cristal': 'vestibule_cristal', 'drapeau_porte': 'vestibule_cristal', 'drapeau_porte2': 'fragment_gauche'}),
    ('Entree', (0, 0), ent, (1.0, 0.96, 0.88), {}),
    ('Epine1', (1, 0), e1, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume1'}),
    ('Plume1', (1, -1), p1, (0.90, 0.96, 1.08), {'drapeau_plaque': 'p1_plaque', 'drapeau_porte': 'p1_plaque', 'drapeau_gemme': 'plume1'}),
    ('Epine2', (2, 0), e2, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume2'}),
    ('Plume2a', (2, -1), p2a, (1.0, 1.0, 1.0), {'sombre': 'true', 'drapeau_braseros': 'p2_braseros', 'drapeau_porte': 'p2_braseros'}),
    ('Plume2b', (2, -2), p2b, (1.04, 0.98, 0.9), {'drapeau_cristal': 'p2_cristal', 'drapeau_porte': 'p2_cristal', 'drapeau_gemme': 'plume2'}),
    ('Epine3', (3, 0), e3, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume3'}),
    ('Plume3a', (3, -1), p3a, (1.04, 0.98, 0.9), {'melodie': '132', 'drapeau_melodie': 'p3_chant1', 'drapeau_porte': 'p3_chant1',
        'indice': 'Frappe la statue du coq : écoute son chant, puis rejoue-le sur les cloches.'}),
    ('Plume3b', (3, -2), p3b, (1.02, 0.96, 0.92), {'melodie': '2413', 'drapeau_melodie': 'p3_chant2', 'drapeau_porte': 'p3_chant2'}),
    ('Plume3c', (3, -3), p3c, (1.0, 1.0, 1.0), {'sombre': 'true', 'melodie': '31524', 'drapeau_melodie': 'p3_chant3',
        'drapeau_porte': 'p3_chant3', 'drapeau_gemme': 'plume3',
        'indice': 'Dans le noir, guette les cloches qui s\'allument quand le coq chante.'}),
    ('Epine4', (4, 0), e4, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume4'}),
    ('Plume4a', (4, -1), p4a, (0.94, 0.96, 1.04), {'retour': RETOUR_P4, 'drapeau_repos': REPOS_P4,
        'indice': 'Ce garde de pierre est une SENTINELLE : ne passe pas dans son cône de vision. Les murs te cachent.'}),
    ('Plume4b', (4, -2), p4b, (0.96, 0.95, 1.02), {'retour': RETOUR_P4, 'drapeau_repos': REPOS_P4,
        'periodes_sentinelles': 'PackedFloat32Array(2, 3)',
        'indice': 'Elles tournent la tête : observe leur rythme. Maj ou K pour courir.'}),
    ('Plume4c', (4, -3), p4c, (0.98, 0.94, 1.0), {'retour': RETOUR_P4, 'drapeau_repos': REPOS_P4}),
    ('Plume4d', (4, -4), p4d, (1.0, 1.0, 1.0), {'sombre': 'true', 'retour': RETOUR_P4, 'drapeau_repos': REPOS_P4,
        'drapeau_gemme': 'plume4', 'duree_braseros': '14.0',
        'indice': 'Une flamme attire le regard des sentinelles. Allume les braseros pour détourner leurs yeux.'}),
    ('Epine5', (5, 0), e5, (0.86, 0.90, 0.96), {}),
    ('Plume5a', (5, -1), p5a, (1.05, 1.0, 0.9), {'drapeau_rayon': 'p5_rayon1', 'drapeau_porte': 'p5_rayon1',
        'indice': 'Frappe le MIROIR à la lance pour le faire pivoter : guide le rayon jusqu\'au soleil éteint.'}),
    ('Plume5b', (5, -2), p5b, (1.04, 0.99, 0.92), {'drapeau_rayon': 'p5_rayon2', 'drapeau_porte': 'p5_rayon2',
        'indice': 'Le chemin le plus court n\'est pas toujours le bon...'}),
    ('Plume5c', (5, -3), p5c, (1.03, 0.98, 0.94), {'drapeau_plaque': 'p5_bouton', 'drapeau_porte2': 'p5_bouton',
        'drapeau_rayon': 'p5_rayon3', 'drapeau_porte': 'p5_rayon3',
        'indice': 'Un bloc arrête la lumière... et un bouton attend un bloc.'}),
    ('Plume5d', (5, -4), p5d, (1.0, 1.0, 1.0), {'sombre': 'true', 'drapeau_rayon': 'p5_rayon4', 'drapeau_porte': 'p5_rayon4'}),
    ('Plume5e', (5, -5), p5e, (1.08, 1.0, 0.88), {'chanteur_au_soleil': 'true', 'melodie': '3142', 'drapeau_melodie': 'p5_chant',
        'drapeau_porte': 'p5_chant', 'drapeau_gemme': 'fragment_gauche',
        'indice': 'La pointe de l\'aile. Au sommet, le fragment attend le chant du coq...'}),
]
depart = (200, 224 + 180)   # le joueur commence dans le vestibule (0,1)

out = '''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://Scripts/world.gd" id="1"]
[ext_resource type="PackedScene" path="res://Scenes/room.tscn" id="2"]
[ext_resource type="PackedScene" path="res://Scenes/player.tscn" id="3"]

; FICHIER GÉNÉRÉ par Outils/generer_monde.py : modifie les plans là-bas, pas ici.
; AILE GAUCHE (en construction) : vestibule (0,1) -> entrée (0,0) -> épine horizontale (1..5, 0) avec 5 plumes qui montent.

[node name="World" type="Node2D"]
script = ExtResource("1")
'''
for nom, (gx, gy), g, c, ex in salles:
    out += '\n[node name="%s" parent="." instance=ExtResource("2")]\n' % nom
    if (gx, gy) != (0, 0): out += 'grille = Vector2i(%d, %d)\n' % (gx, gy)
    out += 'teinte = Color(%s, %s, %s, 1)\n' % c
    for k, v in ex.items():
        # Écrit sans guillemets : booléens, Vector2, tableaux et nombres à virgule (ex. 14.0).
        # ATTENTION : une mélodie comme "132" doit rester un TEXTE (sinon Godot ne la lit pas).
        brut = v == 'true' or v.startswith(('Vector2(', 'PackedFloat32Array(')) or ('.' in v and v.replace('.', '').isdigit())
        out += ('%s = %s\n' % (k, v)) if brut else ('%s = "%s"\n' % (k, v))
    out += 'layout = %s\n' % sortie(g)
out += '''
[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % depart
open(os.path.join(RACINE, 'Scenes', 'world.tscn'), 'w', encoding='utf-8').write(out)
print("world.tscn écrit :", [s[0] for s in salles])
