"""Outil de développement : fabrique les BÂTIMENTS VUS DU CIEL pour la vue mode 7 (Scripts/mode7.gd).
Usage : python3 Outils/fabriquer_plans_mode7.py [apercu.png]
  - plan_aile_gauche.png / plan_aile_droite.png : le VRAI plan des salles de chaque aile (lu dans Scenes/world.tscn et
    Scenes/aile_droite.tscn), 2 px par case : murs en relief (pierre éclairée en haut à gauche), sols dallés.
  - plan_corps.png : le corps du donjon = la silhouette du coq de pierre du blason (sans les ailes), dessinée comme un
    bâtiment (enceinte épaisse + salles), 2x plus grand que le blason.
  - Assets/Gemini/tuiles/v_corps_coq.png : ce même corps vu du PARVIS (lettre Z de exterieur.gd).
  - plans_mode7.json : taille de chaque image et position de la RACINE de chaque aile (centre de la salle d'entrée),
    autour de laquelle l'aile pivote pour s'emboîter sur le corps.
À RELANCER après toute modification des plans des ailes (generer_monde.py / generer_aile_droite.py)."""
import json
import os
import re
import sys
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "embleme")
P = 2                       # pixels par case
W, H = 25, 14               # cases par salle
MUR = (78, 76, 94, 255)
MUR_CLAIR = (128, 126, 142, 255)
MUR_SOMBRE = (50, 48, 62, 255)
SOL = (176, 168, 148, 255)
SOL_JOINT = (150, 142, 124, 255)


def lire_salles(scene):
    """[(grille, layout)] des salles d'une scène .tscn."""
    texte = open(os.path.join(RACINE, "Scenes", scene), encoding="utf-8").read()
    salles = []
    for bloc in texte.split("[node name=")[1:]:
        m = re.search(r"layout = PackedStringArray\((.*)\)", bloc)
        if not m:
            continue
        g = re.search(r"grille = Vector2i\((-?\d+), (-?\d+)\)", bloc)
        grille = (int(g.group(1)), int(g.group(2))) if g else (0, 0)
        salles.append((grille, re.findall(r'"([^"]+)"', m.group(1))))
    return salles


def peindre(plan, taille):
    """plan : dict (x, y) -> 1 sol / 2 mur. Dessine des murs en relief et des sols dallés."""
    im = Image.new("RGBA", (taille[0] * P, taille[1] * P), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for (x, y), v in plan.items():
        x0, y0 = x * P, y * P
        if v == 1:
            d.rectangle([x0, y0, x0 + P - 1, y0 + P - 1], fill=SOL_JOINT if (x % 3 == 0 or y % 3 == 0) else SOL)
        else:
            haut = plan.get((x, y - 1)) != 2
            gauche = plan.get((x - 1, y)) != 2
            bas = plan.get((x, y + 1)) != 2
            d.rectangle([x0, y0, x0 + P - 1, y0 + P - 1], fill=MUR)
            if haut or gauche:
                d.point((x0, y0), fill=MUR_CLAIR)
            if bas:
                d.line([(x0, y0 + P - 1), (x0 + P - 1, y0 + P - 1)], fill=MUR_SOMBRE)
    return im


def plan_aile(scene):
    salles = lire_salles(scene)
    gx = [s[0][0] for s in salles]
    gy = [s[0][1] for s in salles]
    mini = (min(gx), min(gy))
    taille = ((max(gx) - mini[0] + 1) * W, (max(gy) - mini[1] + 1) * H)
    plan = {}
    for (sx, sy), layout in salles:
        bx, by = (sx - mini[0]) * W, (sy - mini[1]) * H
        for y, ligne in enumerate(layout):
            for x, c in enumerate(ligne):
                if c not in "#R":
                    plan[(bx + x, by + y)] = 1
    # murs : seulement ceux qui touchent un sol (à 2 cases près), pour que la FORME des salles se voie
    murs = {}
    for (x, y) in list(plan):
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                c = (x + dx, y + dy)
                if c not in plan and 0 <= c[0] < taille[0] and 0 <= c[1] < taille[1]:
                    murs[c] = 2
    plan.update(murs)
    racine = ((0 - mini[0]) * W + W / 2.0, (0 - mini[1]) * H + H / 2.0)   # centre de la salle d'entrée (0,0)
    return peindre(plan, taille), [racine[0] * P, racine[1] * P]


def plan_corps():
    """La silhouette du coq de pierre (sans ses ailes) devient un bâtiment : enceinte + salles."""
    socle = Image.open(os.path.join(SORTIE, "blason_socle.png")).convert("RGBA")
    l, h = socle.size
    px = socle.load()
    pierre = lambda c: c[3] > 0 and c[0] > 60 and abs(c[0] - c[2]) < 30   # gris (pas le noir des empreintes, pas l'or)
    forme = {(x, y) for y in range(h) for x in range(l) if pierre(px[x, y])}
    # 1 pixel du blason = 1 case ; enceinte = bord de la forme (2 cases), murs intérieurs tous les 9 cases
    plan = {}
    for (x, y) in forme:
        bord = any((x + dx, y + dy) not in forme for dx in (-2, 0, 2) for dy in (-2, 0, 2))
        cloison = (x % 9 == 0 or y % 9 == 0) and (x + y) % 5 != 0     # quelques passages dans les cloisons
        plan[(x, y)] = 2 if (bord or cloison) else 1
    return peindre(plan, (l, h))


def batiment_parvis(corps):
    """Le corps du coq VU DU PARVIS (lettre Z de exterieur.gd, emprise 9x5 = 144x80, porte en colonne 4) :
    le même bâtiment en forme de coq que dans le mode 7 (vu d'en haut, en 3/4), posé sur une façade de briques avec une grande
    arche sombre au milieu. Image 144x92 : la case du bas = la façade et la porte."""
    l, h = 144, 92
    im = Image.new("RGBA", (l, h), (0, 0, 0, 0))
    toit = corps.resize((140, 74), Image.NEAREST)
    ombre = Image.new("RGBA", toit.size, (0, 0, 0, 0))
    ombre.paste((0, 0, 0, 90), mask=toit.split()[3])
    im.alpha_composite(ombre, (4, 4))
    im.alpha_composite(toit, (2, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([38, 70, 105, 91], fill=MUR, outline=MUR_SOMBRE)                # façade de briques
    for y in range(72, 91, 4):
        for x in range(39 + (y // 4 % 2) * 4, 105, 8):
            d.line([(x, y), (min(x + 5, 104), y)], fill=MUR_CLAIR)
    d.rectangle([64, 74, 79, 91], fill=(16, 14, 24, 255))                       # la grande porte (sombre)
    d.ellipse([64, 68, 79, 82], fill=(16, 14, 24, 255))
    d.arc([62, 66, 81, 84], 180, 360, fill=(200, 170, 90, 255))                 # cintre doré
    d.line([(63, 75), (63, 91)], fill=(200, 170, 90, 255)); d.line([(80, 75), (80, 91)], fill=(200, 170, 90, 255))
    return im


def main():
    gauche, racine_g = plan_aile("world.tscn")
    droite, racine_d = plan_aile("aile_droite.tscn")
    corps = plan_corps()
    gauche.save(os.path.join(SORTIE, "plan_aile_gauche.png"))
    droite.save(os.path.join(SORTIE, "plan_aile_droite.png"))
    corps.save(os.path.join(SORTIE, "plan_corps.png"))
    batiment_parvis(corps).save(os.path.join(RACINE, "Assets", "Gemini", "tuiles", "v_corps_coq.png"))
    infos = {"aile_gauche": {"taille": list(gauche.size), "racine": racine_g},
             "aile_droite": {"taille": list(droite.size), "racine": racine_d},
             "corps": {"taille": list(corps.size)}}
    json.dump(infos, open(os.path.join(SORTIE, "plans_mode7.json"), "w"), indent=1)
    print(json.dumps(infos))
    if len(sys.argv) > 1:   # aperçu : le coq COMPLET vu de haut (ailes pivotées et emboîtées, comme en fin de mode 7)
        apercu = Image.new("RGBA", (1024, 768), (82, 140, 66, 255))
        origine = (268, 128)
        apercu.alpha_composite(corps, origine)
        for im, racine, pivot, sens in ((gauche, racine_g, (196, 122), -1), (droite, racine_d, (292, 122), 1)):
            mise = im.resize((int(im.width * 0.4), int(im.height * 1.0)), Image.NEAREST)
            r = (racine[0] * 0.4, racine[1] * 1.0)
            grand = Image.new("RGBA", (1600, 1600), (0, 0, 0, 0))
            grand.alpha_composite(mise, (int(800 - r[0]), int(800 - r[1])))
            tourne = grand.rotate(90 * -sens, resample=Image.NEAREST, center=(800, 800))   # Godot -90° = sens anti-horaire
            apercu.alpha_composite(tourne, (int(origine[0] + pivot[0] - 800), int(origine[1] + pivot[1] - 800)))
        apercu.save(sys.argv[1])


main()
