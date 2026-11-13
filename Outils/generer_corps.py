"""Outil de développement : écrit Scenes/corps.tscn (le CORPS DU COQ = salle du GARDIEN, fin du jeu).
Usage : python3 Outils/generer_corps.py
On y entre par le parvis révélé (porte du bâtiment en forme de coq, voir generer_village.py).
Une seule grande salle « Arene » : le Gardien (Scripts/gardien.gd) attend au fond, sur le tapis.
Les statues (S) et les braseros (B) servent d'obstacles : le Gardien s'y assomme quand il fonce.
Lettres des plans : voir l'en-tête de Scripts/room.gd. Une salle = 25 x 14 cases ; murs du bord de 2 cases.
"""
import os
W, H = 25, 14
RACINE = os.path.join(os.path.dirname(__file__), "..")


def sortie(g): return 'PackedStringArray(' + ', '.join('"' + ''.join(r) + '"' for r in g) + ')'


arene = [['#'] * W for _ in range(H)]
for y in range(2, 12):
    for x in range(2, 23):
        arene[y][x] = '.'
for y in range(12, 14):            # la grande porte du bas (retour au parvis)
    for x in range(11, 14):
        arene[y][x] = '.'
for y in range(4, 12):             # tapis rouge jusqu'au Gardien
    for x in range(11, 14):
        arene[y][x] = 'T'
for (x, y) in [(6, 5), (18, 5), (6, 9), (18, 9)]:
    arene[y][x] = 'S'              # statues de chevaliers : obstacles
for (x, y) in [(3, 3), (21, 3), (3, 10), (21, 10)]:
    arene[y][x] = 'B'              # braseros dans les coins
arene[2][8] = 'O'; arene[2][16] = 'O'   # statues d'oiseau au fond

passages = ['%d 13 @village:Parvis 12 5' % x for x in (11, 12, 13)]
GARDIEN = (12 * 16 + 8, 3 * 16 + 11)     # au fond de la salle, pieds sur la case (12,3)
JOUEUR = (12 * 16 + 8, 11 * 16 + 3)      # case (12,11) (seulement si on lance la scène directement)

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
passages = PackedStringArray(%s)
layout = %s

[node name="Gardien" type="CharacterBody2D" parent="."]
position = Vector2(%d, %d)
script = ExtResource("4")

[node name="Player" parent="." instance=ExtResource("3")]
position = Vector2(%d, %d)

[node name="Camera2D" type="Camera2D" parent="."]
''' % (', '.join('"%s"' % p for p in passages), sortie(arene), GARDIEN[0], GARDIEN[1], JOUEUR[0], JOUEUR[1])
open(os.path.join(RACINE, 'Scenes', 'corps.tscn'), 'w', encoding='utf-8').write(out)
print("corps.tscn écrit")
for r in arene:
    print(''.join(r))
