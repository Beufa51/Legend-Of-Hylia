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
        for y in range(5, 9): g[y][23] = 'D'; g[y][24] = 'D'   # porte de 2 x 4 cases
    if est_ferme:
        for y in range(5, 9): g[y][23] = '#'; g[y][24] = '#'
    return g


e1 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 1 est obtenue
e2 = epine(porte_est=True)            # la porte est s'ouvre quand la plume 2 est obtenue
e3 = epine(est_ferme=True, tige=False)  # provisoire (plumes 3 à 5 à construire)

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

salles = [
    ('Vestibule', (0, 1), vest, (0.92, 0.97, 1.05), {'drapeau_cristal': 'vestibule_cristal', 'drapeau_porte': 'vestibule_cristal'}),
    ('Entree', (0, 0), ent, (1.0, 0.96, 0.88), {}),
    ('Epine1', (1, 0), e1, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume1'}),
    ('Plume1', (1, -1), p1, (0.90, 0.96, 1.08), {'drapeau_plaque': 'p1_plaque', 'drapeau_porte': 'p1_plaque', 'drapeau_gemme': 'plume1'}),
    ('Epine2', (2, 0), e2, (0.86, 0.90, 0.96), {'drapeau_porte': 'plume2'}),
    ('Plume2a', (2, -1), p2a, (1.0, 1.0, 1.0), {'sombre': 'true', 'drapeau_braseros': 'p2_braseros', 'drapeau_porte': 'p2_braseros'}),
    ('Plume2b', (2, -2), p2b, (1.04, 0.98, 0.9), {'drapeau_cristal': 'p2_cristal', 'drapeau_porte': 'p2_cristal', 'drapeau_gemme': 'plume2'}),
    ('Epine3', (3, 0), e3, (0.86, 0.90, 0.96), {}),
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
    for k, v in ex.items(): out += ('%s = %s\n' % (k, v)) if v == 'true' else ('%s = "%s"\n' % (k, v))
    out += 'layout = %s\n' % sortie(g)
out += '''
[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % depart
open(os.path.join(RACINE, 'Scenes', 'world.tscn'), 'w', encoding='utf-8').write(out)
print("world.tscn écrit :", [s[0] for s in salles])
