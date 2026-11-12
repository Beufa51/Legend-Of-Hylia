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
chemin(place, 4, 5, 5, 5); chemin(place, 19, 20, 5, 5)   # devant les portes des maisons
# Bordure d'arbres en haut et en bas, ouverture au nord (colonnes 10-14)
for x in (0, 2, 4, 6, 8, 15, 17, 19, 21, 23):
    put(place, 'A' if x % 4 == 0 else 'a', (x, 0))
for x in range(0, 24, 2):
    put(place, 'a' if x % 4 == 0 else 'A', (x, 12))
put(place, 'b', (24, 12), (24, 13))
# Côtés : arbres, ouvertures ouest/est (rangées 6-8)
for (x, y) in [(0, 2), (0, 4), (0, 9), (23, 2), (23, 4), (23, 9)]:
    put(place, 'P' if y == 4 else 'A', (x, y))
put(place, 'b', (0, 11), (1, 11), (23, 11), (24, 11))
# Sortie nord provisoirement fermée (l'écran voisin n'existe pas encore) ; ouest et est sont ouvertes
put(place, 'b', (11, 0), (12, 0), (13, 0))   # nord encore fermé (grand chemin pas construit)
# Maisons (portes en bas : colonnes 4 et 20)
put(place, 'M', (3, 2)); put(place, 'N', (18, 2))
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

def bordure(g, haut=True, bas=True):
    """Arbres en haut et en bas de l'écran."""
    for x in range(0, 24, 2):
        if haut: put(g, 'A' if x % 4 == 0 else 'a', (x, 0))
        if bas: put(g, 'a' if x % 4 == 0 else 'A', (x, 12))
    put(g, 'b', (24, 12), (24, 13), (24, 0), (24, 1))


# --- VILLAGE OUEST (1,2) : deux maisons au nord, un coin potager/marché au sud.
#     Entrée par l'est (la place). L'ouest mène à la ferme (pas encore construite) : fermé par des buissons.
ouest = vide()
chemin(ouest, 0, 24, 6, 8)
chemin(ouest, 4, 5, 5, 5); chemin(ouest, 13, 14, 5, 5)       # devant les portes
bordure(ouest)
put(ouest, 'b', (0, 6), (0, 7), (0, 8))                      # ferme pas encore construite
put(ouest, 'M', (3, 2)); put(ouest, 'N', (12, 2))
for (x, y) in [(0, 2), (0, 4), (21, 2), (23, 4), (0, 10), (22, 10)]:
    put(ouest, 'A' if x % 2 == 0 else 'a', (x, y))
put(ouest, 'P', (8, 2), (18, 3))
put(ouest, 'E', (13, 10)); put(ouest, 'o', (10, 11), (17, 10), (17, 11))
put(ouest, 'j', (9, 5), (16, 5))
put(ouest, 'f', (2, 6 - 1), (7, 4), (19, 5), (3, 11)); put(ouest, 'g', (8, 5), (10, 3), (20, 4), (6, 11), (5, 10))
put(ouest, 'w', (2, 5), (11, 4), (18, 5), (4, 10), (21, 12))
pnjs_ouest = [
    "Woman 10 9 haut | Colette | Oh, tu es la nouvelle recrue ! Tout le village parle de ton épreuve d'adoubement. // On raconte que le donjon sous le temple a la forme d'un grand coq. // Un coq dans un donjon... Moi, je préfère ceux de ma basse-cour !",
    "OldMan 8 6 droite | Vieux Gaspard | Le coq chante chaque aube depuis mille ans. // S'il se taisait un jour, le royaume tremblerait. // Ton père tenait la lance avant toi. Garde-la bien, petite.",
    "Boy 18 5 gauche | Tom | Tu as une vraie lance de la garde ! Tu me la prêtes ? // ... Non ? Tant pis. // Un conseil : n'embête pas les poules. Elles se vengent.",
]
animaux_ouest = ['c 6 10', 'h 20 9', 'c 15 12']

# --- VILLAGE EST (3,2) : la CASERNE de la garde royale (bâtiment beige au nord, bannières rouges).
#     Entrée par l'ouest (la place). L'est mène à la maison du héros (pas encore construite) : fermé.
est = vide()
chemin(est, 0, 24, 6, 8)
chemin(est, 11, 13, 5, 5)                                     # devant la porte de la caserne
bordure(est)
put(est, 'b', (24, 6), (24, 7), (24, 8))                      # maison du héros pas encore construite
put(est, 'N', (10, 2)); put(est, 'j', (8, 2), (15, 2))        # caserne : maison beige + bannières
put(est, 'o', (6, 3), (6, 4), (18, 3), (19, 4))
for (x, y) in [(0, 2), (0, 4), (2, 9), (22, 2), (22, 9), (20, 11)]:
    put(est, 'A' if y % 4 == 0 else 'a', (x, y))
put(est, 'P', (3, 2), (21, 5))
put(est, 'E', (4, 10)); put(est, 'o', (8, 10), (19, 9))
put(est, 'g', (9, 5), (16, 5), (13, 10), (2, 6)); put(est, 'f', (7, 5), (17, 4), (12, 11))
put(est, 'w', (8, 4), (15, 4), (14, 10), (23, 10), (1, 7))
pnjs_est = [
    "KnightGold 15 5 gauche | Capitaine Aubrac | Te voilà enfin, recrue ! L'épreuve d'adoubement t'attend au temple, au nord du village. // Deux ailes et un corps : voilà la forme du donjon. Observe, réfléchis. // Un garde ne se bat pas pour rien : il comprend d'abord. Va, et reviens avec l'honneur.",
    "Villager3 7 7 droite | Soldat Merle | Dix ans de garde et je n'ai jamais vu le fond du donjon. // Les anciens disent que les plumes de l'aile gauche sont de plus en plus longues. Je ne sais pas ce que ça veut dire !",
    "Villager 6 9 haut | Marchande Rosine | Des pommes ! Des pommes de la ferme ! // Les gardes sont mes meilleurs clients... et les pires payeurs.",
]
animaux_est = ['d 20 7', 'c 12 11']

ecrans = [
    ('PlaceDuCoq', (2, 2), place, {'animaux': animaux_place}),
    ('VillageOuest', (1, 2), ouest, {'animaux': animaux_ouest, 'pnjs': pnjs_ouest}),
    ('VillageEst', (3, 2), est, {'animaux': animaux_est, 'pnjs': pnjs_est}),
]
depart = (2 * 400 + 12 * 16 + 8, 2 * 224 + 10 * 16 + 3)   # nouvelle partie : au sud de la statue


def ecrire_scene():
    out = '''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://Scripts/world.gd" id="1"]
[ext_resource type="PackedScene" path="res://Scenes/exterieur.tscn" id="2"]
[ext_resource type="PackedScene" path="res://Scenes/player.tscn" id="3"]

; FICHIER GÉNÉRÉ par Outils/generer_village.py : modifie les plans là-bas, pas ici.

[node name="World" type="Node2D"]
script = ExtResource("1")
musique = "res://Assets/Ninja_adventure/Audio/Musics/20 - Good Time.ogg"
donjon = false

'''
    for nom, (gx, gy), g, props in ecrans:
        out += '[node name="%s" parent="." instance=ExtResource("2")]\n' % nom
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
    print("village.tscn écrit :", [e[0] for e in ecrans])


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
    objets = {"A": ("NATURE", (16, 0, 2, 2)), "a": ("NATURE", (18, 0, 2, 2)), "P": ("NATURE", (0, 0, 2, 2)),
              "b": ("NATURE", (0, 10, 1, 1)), "f": ("NATURE", (0, 11, 1, 1)), "g": ("NATURE", (3, 11, 1, 1)),
              "w": ("NATURE", (6, 11, 1, 1)),
              "M": ("MAISONS", (0, 0, 4, 3)), "N": ("MAISONS", (4, 0, 4, 3)), "o": ("MAISONS", (16, 15, 1, 1)),
              "j": ("MAISONS", (23, 20, 1, 2)), "Q": ("tuile:girouette_mat", None), "W": ("tuile:puits", None)}
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
                    n, s, o, e = est(x, y - 1), est(x, y + 1), est(x - 1, y), est(x + 1, y)
                    if n and s and o and e:
                        t = (16, 8) if not est(x + 1, y + 1) else (17, 8) if not est(x - 1, y + 1) else \
                            (16, 9) if not est(x + 1, y - 1) else (17, 9) if not est(x - 1, y - 1) else (12, 8)
                    else:
                        col = 0 if (not o and e) else 2 if (o and not e) else 1
                        lig = 0 if (not n and s) else 2 if (n and not s) else 1
                        t = (11 + col, 7 + lig)
                else:
                    h = (x * 73 + y * 151 + gx * 31 + gy * 17) % 13
                    t = [(12, 12), (13, 12), (14, 12), (15, 12)][h] if h < 4 else (11, 12)
                region("SOL", (t[0], t[1], 1, 1), d)
        for y in range(H):
            for x in range(W):
                c = g[y][x]; d = (ox + x * 16, oy + y * 16)
                if c in objets:
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
                taille = {"E": (3, 2), "Q": (3, 4), "W": (2, 2)}.get(c) or (objets[c][1][2:] if c in objets and objets[c][1] else None)
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
                    t = [(3, 10), (7, 10), (9, 10)][(x * 7 + y * 3) % 3]
                    region("NATURE", (t[0], t[1], 1, 1), (ox + x * 16, oy + y * 16))
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
