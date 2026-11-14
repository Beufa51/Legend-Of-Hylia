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
for y in range(3, 12):             # chemin de pierre jusqu'au Gardien
    for x in range(11, 14):
        arene[y][x] = '.'
for y in range(12, 14):            # la grande porte du bas (retour au parvis)
    for x in range(11, 14):
        arene[y][x] = '.'
for (x, y) in [(6, 5), (18, 5), (6, 8), (18, 8)]:
    arene[y][x] = 'S'              # statues de chevaliers : obstacles
for (x, y) in [(4, 4), (20, 4), (4, 9), (20, 9)]:
    arene[y][x] = 'B'              # braseros aux angles de la cour
arene[2][8] = 'O'; arene[2][16] = 'O'   # statues d'oiseau au fond

def vide():
    g = [['#'] * W for _ in range(H)]
    return g


def sol(g, x0, x1, y0, y1, c='.'):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            g[y][x] = c


# --- COULOIR (0,1) : on est entré dans le CORPS. Un long couloir de 5 cases, braseros le long des murs, tapis au centre.
couloir = vide()
sol(couloir, 10, 14, 2, 11)            # le couloir : 5 cases de large (les ouvertures du haut et du bas : 3 cases, comme les autres salles)
sol(couloir, 11, 13, 0, 13, 'T')
for (x, y) in [(10, 3), (14, 3), (10, 7), (14, 7), (10, 11), (14, 11)]:
    couloir[y][x] = 'B'

# --- VESTIBULE (0,2) : la QUEUE du coq (voir Coq_forteresse.jpg) : CINQ COULOIRS DE TERRE qui se rejoignent à la porte d'entrée (en bas) et s'écartent
# en éventail vers le donjon rond ; une flamme brûle au bout de chacun ; seul le couloir du milieu continue vers le corps.
vestibule = vide()
for y in range(2, 12):
    t = (11 - y) / 9.0                         # 0 en bas (couloirs serrés) -> 1 en haut (écartés)
    for dx in (-9.0, -4.5, 0.0, 4.5, 9.0):
        c = 12 + dx * (0.12 + 0.88 * t)
        for x in range(25):
            if abs(x - c) <= 1.15:
                vestibule[y][x] = ','
sol(vestibule, 11, 13, 0, 1, ',')              # sortie du haut vers le couloir du corps
sol(vestibule, 11, 13, 12, 13, ',')            # porte d'entrée (en bas)
sol(vestibule, 9, 15, 10, 11, ',')             # petit parvis derrière la porte : les couloirs se rejoignent
for (x, y) in [(3, 2), (7, 2), (17, 2), (21, 2)]:
    vestibule[y][x] = 'B'                      # flammes au bout des couloirs extérieurs
for (x, y) in [(8, 10), (16, 10)]:
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
teinte = Color(1.04, 0.96, 0.86, 1)
layout = %s

[node name="Couloir" parent="." instance=ExtResource("2")]
grille = Vector2i(0, 1)
teinte = Color(1.0, 0.93, 0.85, 1)
layout = %s

[node name="Vestibule" parent="." instance=ExtResource("2")]
grille = Vector2i(0, 2)
teinte = Color(1.06, 0.95, 0.84, 1)
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
