"""Outil de développement : écrit Scenes/aile_droite.tscn (AILE DROITE du donjon) à partir des plans ci-dessous.
Usage : python3 Outils/generer_aile_droite.py
Lettres des plans : voir l'en-tête de Scripts/room.gd. Une salle = 25 x 14 cases ; murs du bord de 2 cases.

L'aile droite est le MIROIR de l'aile gauche (voir generer_monde.py) :
  vestibule (0,1) -> entrée (0,0) -> épine qui part vers l'OUEST (-1..-5, 0) avec 5 plumes qui montent,
  de plus en plus longues de DROITE à GAUCHE. Drapeaux : plumeD1..plumeD4, fragment_droite.
Mécaniques (1 nouvelle par plume) : 1 plots orange/bleus, 2 sol fragile (faites) ; prévues : 3 glace, 4 reflet, 5 combinaison.
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


# --- Vestibule (0,1) : on entre ici depuis le temple de l'aile droite. Pas d'énigme : la porte du nord est ouverte.
vest = vide(); sol(vest, 2, 22, 2, 11); sol(vest, 11, 13, 0, 1)
for x in (11, 12, 13): vest[12][x] = 'H'; vest[13][x] = 'H'   # grande porte du sud = sortie (s'ouvre avec le fragment)
put(vest, 'B', (6, 4), (18, 4)); put(vest, 'V', (3, 10), (21, 10), (7, 9), (17, 9), (3, 3), (21, 3))
put(vest, 'S', (9, 6)); put(vest, 'O', (15, 6))
for x in range(11, 14):
    for y in range(2, 12): put(vest, 'T', (x, y))

# --- Entrée (0,0) : grande salle, porte au sud (vers le vestibule) et sortie à l'OUEST (rangées 5-8)
ent = vide(); sol(ent, 2, 22, 2, 11); sol(ent, 0, 1, 5, 8); sol(ent, 11, 13, 12, 13)
put(ent, 'B', (3, 3), (21, 3), (3, 10), (21, 10)); put(ent, 'O', (5, 4)); put(ent, 'S', (19, 4))
put(ent, 'V', (4, 11), (20, 11), (3, 6), (21, 6))
for x in range(6, 19): put(ent, 'T', (x, 6), (x, 7))


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
e3 = epine(ferme=True, tige=False)   # PROVISOIRE : cul-de-sac tant que la plume D3 n'est pas construite

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

# --- PLUME D2 : « LE SOL FRAGILE ». Les dalles z s'effondrent quand on les quitte : il faut passer sur TOUTES,
#     une seule fois chacune. Erreur (sortir du champ trop tôt, ou impasse) = les dalles se reforment ; tomber dans un trou = retour en bas.
def retour_d2(n):   # bas de l'écran n de la plume D2 (case (12,12)), en position dans le monde
    return 'Vector2(%d, %d)' % (-2 * 400 + 12 * 16 + 8, -224 * n + 194)

# D2a (en bas) : leçon. Un champ de 5 x 4 dalles traverse la salle ; un serpentin suffit.
p2a = vide(); sol(p2a, 2, 22, 2, 3); sol(p2a, 2, 22, 8, 11); sol(p2a, 11, 13, 12, 13); sol(p2a, 11, 13, 0, 1)
for x in (11, 12, 13): p2a[0][x] = 'D'; p2a[1][x] = 'D'
for y in range(4, 8):
    for x in range(10, 15): p2a[y][x] = 'z'
put(p2a, 'V', (3, 11), (21, 11), (3, 2), (21, 2)); put(p2a, 'S', (8, 9)); put(p2a, 'O', (16, 9)); put(p2a, 'B', (5, 9), (19, 9))

# D2b (la pointe) : 34 dalles autour de 2 piliers ; on entre par le bas. Dès que toutes sont foulées, la grille de l'alcôve
#     s'ouvre et les dalles se raffermissent (on peut alors marcher partout). Solutions vérifiées par un solveur.
p2b = vide(); sol(p2b, 2, 22, 2, 4); sol(p2b, 2, 22, 10, 11); sol(p2b, 11, 13, 12, 13)
for x in range(2, 23): p2b[5][x] = '#'
for x in (11, 12, 13): p2b[5][x] = 'D'
put(p2b, 'G', (12, 3)); put(p2b, 'B', (9, 3), (15, 3))
for x in range(10, 15): put(p2b, 'T', (x, 4))
for y in range(6, 10):
    for x in range(8, 17): p2b[y][x] = 'z'
put(p2b, '#', (10, 7), (14, 8))
put(p2b, 'V', (3, 11), (21, 11), (3, 10), (21, 10)); put(p2b, 'S', (5, 2)); put(p2b, 'O', (19, 2))

salles = [
    ('Vestibule', (0, 1), vest, (0.98, 0.95, 1.06), {'drapeau_porte2': 'fragment_droite',
        'indice': "L'aile droite du blason. Ici, tout est inversé : l'épine part vers l'ouest."}),
    ('Entree', (0, 0), ent, (1.0, 0.94, 0.92), {}),
    ('Epine1', (-1, 0), e1, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD1'}),
    ('PlumeD1', (-1, -1), p1, (0.98, 0.94, 1.06), {'drapeau_gemme': 'plumeD1',
        'indice': "Ce cristal commande les plots de couleur : un coup de lance, et les levés se baissent... et les baissés se lèvent !"}),
    ('Epine2', (-2, 0), e2, (0.90, 0.88, 0.98), {'drapeau_porte': 'plumeD2'}),
    ('PlumeD2a', (-2, -1), p2a, (1.0, 0.97, 0.92), {'drapeau_fragile': 'd2_sol1', 'drapeau_porte': 'd2_sol1', 'retour': retour_d2(1),
        'indice': "Dalles fragiles : chacune s'effondre quand tu la quittes. Passe sur TOUTES, une seule fois chacune, pour ouvrir la grille."}),
    ('PlumeD2b', (-2, -2), p2b, (0.98, 0.95, 0.9), {'drapeau_fragile': 'd2_sol2', 'drapeau_porte': 'd2_sol2', 'retour': retour_d2(2),
        'drapeau_gemme': 'plumeD2', 'indice': "Plus de dalles, et deux piliers au milieu. Choisis bien ta première dalle et trace ton chemin avant de partir..."}),
    ('Epine3', (-3, 0), e3, (0.90, 0.88, 0.98), {}),
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
