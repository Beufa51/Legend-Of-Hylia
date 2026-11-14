"""Outil de développement : écrit Scenes/corps.tscn (le DONJON FINAL du coq : queue, corps et salle du GARDIEN).
Usage : python3 Outils/generer_corps.py
On y entre par la façade de la QUEUE (écran « Queue » du village, voir generer_village.py). Trois écrans empilés vers le haut :
  Vestibule (0,2) = la queue du coq (hall d'entrée) -> Couloir (0,1) = on entre dans le corps -> Arene (0,0) = le boss.
Les grilles descendent vers le bas de l'écran : monter à l'écran = aller vers y plus petit. L'arène reste en (0,0) (le Gardien y a ses coordonnées).
Dans l'arène : le Gardien (Scripts/gardien.gd) attend au fond, sur le tapis.
Les statues (S) et les braseros (B) servent d'obstacles : le Gardien s'y assomme quand il fonce.
Lettres des plans : voir l'en-tête de Scripts/room.gd. Une salle = 25 x 14 cases ; murs du bord de 2 cases.
"""
import os
W, H = 25, 14
RACINE = os.path.join(os.path.dirname(__file__), "..")


def sortie(g): return 'PackedStringArray(' + ', '.join('"' + ''.join(r) + '"' for r in g) + ')'


# --- ARÈNE (0,0) : la COUR du château (voir Coq_forteresse.jpg) : un octogone d'herbe ceint d'un chemin de pierre, braseros, statues ; le Gardien attend au fond.
arene = [['#'] * W for _ in range(H)]
for y in range(2, 12):
    for x in range(2, 23):
        coupe = min((x - 2) + (y - 2), (22 - x) + (y - 2), (x - 2) + (11 - y), (22 - x) + (11 - y)) < 3   # coins coupés : octogone
        arene[y][x] = '#' if coupe else '.'
for y in range(4, 10):             # l'herbe de la cour
    for x in range(5, 20):
        arene[y][x] = ';'
for y in range(2, 12):             # l'herbe déborde sur le chemin de pierre de la cour : des plaques, pas un cadre régulier
    for x in range(2, 23):
        if arene[y][x] == '.' and (x * 7 + y * 13 + x * y) % 4 == 0 and not (11 <= x <= 13):
            arene[y][x] = ';'
for y in range(3, 12):             # chemin de pierre jusqu'au Gardien
    for x in range(11, 14):
        arene[y][x] = '.'
for y in range(12, 14):            # la grande porte du bas (retour au parvis)
    for x in range(11, 14):
        arene[y][x] = '.'
for (x, y) in [(6, 5), (18, 5), (6, 8), (18, 8)]:
    arene[y][x] = 'S'              # statues de chevaliers : obstacles
for (x, y) in [(4, 4), (20, 4), (3, 6), (21, 6), (4, 9), (20, 9)]:
    arene[y][x] = 'B'              # SIX braseros autour de la cour (comme sur l'image)
arene[2][8] = 'O'; arene[2][16] = 'O'   # statues d'oiseau au fond

def vide():
    g = [['#'] * W for _ in range(H)]
    return g


def sol(g, x0, x1, y0, y1, c='.'):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[y][x] = c


# --- COULOIR (0,1) : on est entré dans le CORPS : le passage voûté dans l'épaisseur du donjon rond. PEINT (Outils/fabriquer_vestibule.py::masque_couloir) :
# couloir droit de 3 cases, trois arcs de voûte, deux alcôves de garde (statue + flamme) ; tapis rouge au milieu.
import sys
sys.path.insert(0, os.path.dirname(__file__))
import fabriquer_vestibule
fabriquer_vestibule.fabriquer(fabriquer_vestibule.masque_couloir(), "fond_couloir", lumieres=((136, 88), (264, 88)), nervures=(40, 104, 168))
couloir = [list(r) for r in fabriquer_vestibule.plan(fabriquer_vestibule.masque_couloir())]
for y in range(H):
    for x in (11, 12, 13):
        if couloir[y][x] == '.':
            couloir[y][x] = 'T'
for (x, y) in [(8, 5), (16, 5)]:
    couloir[y][x] = 'B'                # flammes dans les alcôves
for (x, y) in [(9, 7), (15, 7)]:
    couloir[y][x] = 'S'                # statues de gardes dans les alcôves

# --- VESTIBULE (0,2) : la QUEUE du coq (voir Coq_forteresse.jpg) : CINQ COULOIRS DE TERRE qui se rejoignent à la porte d'entrée (en bas) et s'écartent
# en éventail vers le donjon rond ; une flamme brûle au bout de chacun ; seul le couloir du milieu continue vers le corps.
# L'éventail est PEINT (Outils/fabriquer_vestibule.py) : le plan ne sert qu'aux collisions ; tapis rouge sur le couloir du milieu, flammes au bout des 4 couloirs extérieurs.
import sys
sys.path.insert(0, os.path.dirname(__file__))
import fabriquer_vestibule
fabriquer_vestibule.fabriquer()
vestibule = [list(r) for r in fabriquer_vestibule.plan()]
for y in range(H):
    for x in (11, 12, 13):
        if vestibule[y][x] == '.':
            vestibule[y][x] = 'T'
for (x, y) in [(3, 2), (7, 2), (17, 2), (21, 2)]:
    vestibule[y][x] = 'B'
for (x, y) in [(10, 10), (14, 10)]:
    vestibule[y][x] = 'O'                      # coqs de pierre qui gardent l'entrée
passages_vestibule = ['%d 13 @village:Queue 12 12' % x for x in (11, 12, 13)]

GARDIEN = (12 * 16 + 8, 3 * 16 + 11)     # au fond de la salle, pieds sur la case (12,3)
JOUEUR = (12 * 16 + 8, 2 * 224 + 11 * 16 + 3)   # case (12,11) du vestibule (seulement si on lance la scène directement)

out = '''[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://Scripts/world.gd" id="1"]
[ext_resource type="PackedScene" path="res://Scenes/room.tscn" id="2"]
[ext_resource type="PackedScene" path="res://Scenes/player.tscn" id="3"]
[ext_resource type="Script" path="res://Scripts/gardien.gd" id="4"]

; FICHIER GÉNÉRÉ par Outils/generer_corps.py : modifie le plan là-bas, pas ici.

[node name="World" type="Node2D"]
script = ExtResource("1")
musique = "res://Assets/Ninja_adventure/Audio/Musics/24 - Final Area.ogg"
cote = "corps"

[node name="Arene" parent="." instance=ExtResource("2")]
teinte = Color(0.9, 0.95, 1.1, 1)
ciel_ouvert = true
ciel_etoile = true
layout = %s

[node name="Couloir" parent="." instance=ExtResource("2")]
grille = Vector2i(0, 1)
teinte = Color(1.0, 0.93, 0.85, 1)
fond_image = \"fond_couloir\"
layout = %s

[node name="Vestibule" parent="." instance=ExtResource("2")]
grille = Vector2i(0, 2)
teinte = Color(0.92, 0.95, 1.1, 1)
ciel_ouvert = true
fond_image = \"fond_vestibule\"
passages = PackedStringArray(%s)
layout = %s

[node name="Gardien" type="CharacterBody2D" parent="."]
position = Vector2(%d, %d)
script = ExtResource("4")

[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % (sortie(arene), sortie(couloir), ', '.join('"%s"' % p for p in passages_vestibule), sortie(vestibule), GARDIEN[0], GARDIEN[1], JOUEUR[0], JOUEUR[1])
open(os.path.join(RACINE, 'Scenes', 'corps.tscn'), 'w', encoding='utf-8').write(out)
print("corps.tscn écrit : Vestibule (0,2) -> Couloir (0,1) -> Arene (0,0)")
