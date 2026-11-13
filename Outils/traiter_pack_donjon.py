"""Outil de développement : prend des sprites du pack donjon Craftpix (Assets/PNG/, licence craftpix.net : usage dans un jeu OK)
et les écrit dans Assets/Gemini/tuiles/ sous les noms que room.gd utilise déjà.
Usage : python3 Outils/traiter_pack_donjon.py [apercu.png]
ORDRE : à lancer APRÈS traiter_gemini.py (qui réécrit les anciennes images vase_1, brasero_*, torche_*).

Images produites :
  brasero_1..6.png  (20x26 : la case de 16x16 est en BAS au centre -> décalage (-2,-10) dans room.gd / brasero.gd)
  brasero_eteint.png (même taille : la flamme est retirée, il reste des braises)
  torche_1..6.png   (12x24 : torche murale animée)
  vase_1.png (bleu), vase_2.png (brun) (16x16, posés au fond de la case)
  MURS ET SOL (mêmes noms que ceux de traiter_gemini.py, qu'ils remplacent) : mur_fond, mur_bord_n/s/e/o, mur_coin_*, mur_dot_*,
  + nouvelles : mur_face_haut/bas (+ _g/_d = bouts), pilier (16x24), sol_plat(_b/_c/_d)
  PORTES ET OBJETS : arche_herse_1..5, arche_bois_1..5 (48x32), arche_basse_1..5 (48x16), coffre_1..5 (20x22),
  levier_1..5 (16x16), cle (12x8), pics_1..5 (16x24), eau_1/2 (16x16)
"""
import os
import sys
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
PACK = os.path.join(RACINE, "Assets", "PNG")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
OPAQUE = 200   # on ne garde que les pixels presque opaques (le halo du pack est remplacé par nos propres lueurs)


def nettoyer(im):
    """Supprime le halo semi-transparent."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] < OPAQUE:
                px[x, y] = (0, 0, 0, 0)
    return im


def animation(fichier, x0, x1, nb, taille):
    """Découpe `nb` images (une par rangée de 48 px) dans la colonne x0..x1 ; toutes alignées pareil
    (même boîte englobante), posées en bas au centre d'une image de `taille`."""
    planche = nettoyer(Image.open(os.path.join(PACK, fichier)))
    images = [planche.crop((x0, r * 48, x1, r * 48 + 48)) for r in range(nb)]
    boite = None
    for im in images:
        b = im.getbbox()
        boite = b if boite is None else (min(boite[0], b[0]), min(boite[1], b[1]), max(boite[2], b[2]), max(boite[3], b[3]))
    sortie = []
    for im in images:
        morceau = im.crop(boite)
        toile = Image.new("RGBA", taille, (0, 0, 0, 0))
        toile.alpha_composite(morceau, ((taille[0] - morceau.width) // 2, taille[1] - morceau.height))
        sortie.append(toile)
    return sortie


def sans_flamme(im):
    """Brasero éteint : les pixels de flamme (clairs, jaunes/orangés) deviennent un fond de cuve sombre,
    avec quelques braises rouges."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r > 140 and r > b + 60:   # flamme
                px[x, y] = (0, 0, 0, 0)
    # la cuve : sous la ligne où commence le métal, on remplit le creux d'un brun très sombre
    haut_metal = None
    for y in range(im.height):
        if any(px[x, y][3] for x in range(im.width)):
            haut_metal = y
            break
    if haut_metal is not None:
        for y in range(haut_metal, im.height):
            ligne = [x for x in range(im.width) if px[x, y][3]]
            if len(ligne) >= 2:
                for x in range(ligne[0], ligne[-1] + 1):
                    if not px[x, y][3]:
                        px[x, y] = (40, 30, 30, 255)
    for (x, y) in [(8, 13), (11, 14), (10, 12)]:   # braises
        if 0 <= x < im.width and 0 <= y < im.height and px[x, y][3]:
            px[x, y] = (200, 70, 30, 255)
    return im


def vase(boite):
    planche = Image.open(os.path.join(PACK, "Objects.png")).convert("RGBA")
    morceau = planche.crop((boite[0], boite[1], boite[2] + 1, boite[3] + 1))
    toile = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    toile.alpha_composite(morceau, ((16 - morceau.width) // 2, 16 - morceau.height))
    return toile


# --- Murs et sol (walls_floor.png, cases de 16 px) --------------------------------------------
def case(x, y, fichier="walls_floor.png"):
    planche = Image.open(os.path.join(PACK, fichier)).convert("RGBA")
    return planche.crop((x * 16, y * 16, x * 16 + 16, y * 16 + 16))


def calque(piece, fond):
    """Ce qui, dans `piece`, diffère du mur sombre uni `fond` (le rebord de briques), sur fond transparent."""
    out = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    a, f, o = piece.load(), fond.load(), out.load()
    for y in range(16):
        for x in range(16):
            if a[x, y] != f[x, y]:
                o[x, y] = a[x, y]
    return out


def coin_seul(im, cote_x, cote_y, n=5):
    """Ne garde que le carré de n x n pixels dans le coin demandé (angle rentrant)."""
    out = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    x0 = 0 if cote_x == "o" else 16 - n
    y0 = 0 if cote_y == "n" else 16 - n
    out.paste(im.crop((x0, y0, x0 + n, y0 + n)), (x0, y0))
    return out


def murs_et_sol(images):
    fond = case(1, 1)                       # dessus du mur : sombre uni
    images["mur_fond"] = fond
    bords = {"n": case(1, 0), "s": case(1, 2), "o": case(0, 1), "e": case(2, 1)}
    for k, piece in bords.items():
        images["mur_bord_" + k] = calque(piece, fond)
    coins = {"no": case(0, 0), "ne": case(2, 0), "so": case(0, 2), "se": case(2, 2)}
    for k, piece in coins.items():
        images["mur_coin_" + k] = calque(piece, fond)
        # angle rentrant : du sol seulement en diagonale -> un petit bout de rebord dans le coin
        images["mur_dot_" + k] = coin_seul(images["mur_coin_" + k], k[1], k[0])
    # Face de briques (mur vu de face, quand le sol est juste en dessous) : milieu, bout gauche, bout droit
    for nom, rang in (("haut", 3), ("bas", 4)):
        images["mur_face_" + nom] = case(1, rang)
        images["mur_face_%s_g" % nom] = case(0, rang)
        images["mur_face_%s_d" % nom] = case(2, rang)
    # Pilier isolé (1 case) : petit dessus sombre bordé + face de briques ; image 16x24 (8 px au-dessus de sa case)
    dessus = Image.new("RGBA", (16, 16))
    for (k, x, y) in (("no", 0, 0), ("ne", 8, 0), ("so", 0, 8), ("se", 8, 8)):
        dessus.paste(coins[k].crop((x, y, x + 8, y + 8)), (x, y))
    pilier = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    pilier.paste(dessus.crop((0, 0, 16, 5)), (0, 0))
    pilier.paste(dessus.crop((0, 11, 16, 16)), (0, 5))
    pilier.alpha_composite(case(1, 4).crop((0, 2, 16, 16)), (0, 10))
    images["pilier"] = pilier
    # Sol : gris-bleu uni (comme ALttP) ; variantes rares : dalles gravées
    # (decorative_cracks_floor.png contient des TROUS, pas des fissures : non utilisé)
    uni = case(1, 10)
    images["sol_plat"] = uni
    images["sol_plat_b"] = uni
    images["sol_plat_c"] = case(0, 21)
    images["sol_plat_d"] = case(1, 22)


# --- Portes, coffre, levier, clé, pics, eau -----------------------------------------------------
def elargir(im, ajout=16):
    """Élargit une arche de 32 px à 48 px en répétant ses colonnes du milieu (le cintre devient un peu plus plat)."""
    milieu = im.width // 2
    out = Image.new("RGBA", (im.width + ajout, im.height), (0, 0, 0, 0))
    out.paste(im.crop((0, 0, milieu, im.height)), (0, 0))
    bande = im.crop((milieu - ajout // 2, 0, milieu + ajout // 2, im.height))
    out.paste(bande, (milieu, 0))
    out.paste(im.crop((milieu, 0, im.width, im.height)), (milieu + ajout, 0))
    return out


def objets_animes(images):
    planche = Image.open(os.path.join(PACK, "doors_lever_chest_animation.png")).convert("RGBA")
    for f in range(5):
        # Arches 48x32 (porte du mur du haut, 3 cases x 2) : herse sur fond sombre, porte de bois
        images["arche_herse_%d" % (f + 1)] = elargir(planche.crop((f * 32, 64, f * 32 + 32, 96)))
        images["arche_bois_%d" % (f + 1)] = elargir(planche.crop((f * 32, 96, f * 32 + 32, 128)))
        # Porte basse 48x16 (mur intérieur d'une rangée) : le bas de l'arche à herse
        images["arche_basse_%d" % (f + 1)] = images["arche_herse_%d" % (f + 1)].crop((0, 16, 48, 32))
        # Coffre (20x22, la case 16x16 en bas au centre) : fermé -> ouvert, plein d'or
        images["coffre_%d" % (f + 1)] = planche.crop((f * 32 + 6, 128, f * 32 + 26, 150))
        # Levier 16x16 : penché à gauche -> penché à droite
        images["levier_%d" % (f + 1)] = planche.crop((f * 16, 176, f * 16 + 16, 192))
    objets = Image.open(os.path.join(PACK, "Objects.png")).convert("RGBA")
    images["cle"] = objets.crop((50, 0, 62, 8))
    # Pics (trap_animation.png) : 5 états, de « trous » à « pics sortis » ; 16x24 (8 px au-dessus de la case)
    pics = Image.open(os.path.join(PACK, "trap_animation.png")).convert("RGBA")
    base = pics.crop((64, 24, 80, 48))   # état 1 : les trous seuls
    for k in range(5):
        im = pics.crop((64, 24 + 80 * k, 80, 48 + 80 * k))
        px, b0 = im.load(), base.load()
        for y in range(8):   # au-dessus de la case : on ne garde que les pointes qui dépassent
            for x in range(16):
                if px[x, y] == b0[x, y]:
                    px[x, y] = (0, 0, 0, 0)
        images["pics_%d" % (k + 1)] = im
    # Eau : 2 cases de la dernière rangée de Water_coasts_animation.png (on les alterne doucement)
    eau = Image.open(os.path.join(PACK, "Water_coasts_animation.png")).convert("RGBA")
    images["eau_1"] = eau.crop((0, 432, 16, 448))
    images["eau_2"] = eau.crop((16, 432, 32, 448))


def main():
    images = {}
    murs_et_sol(images)
    objets_animes(images)
    braseros = animation("fire_animation.png", 130, 172, 6, (20, 26))
    for i, im in enumerate(braseros):
        images["brasero_%d" % (i + 1)] = im
    images["brasero_eteint"] = sans_flamme(braseros[0])
    for i, im in enumerate(animation("fire_animation.png", 40, 70, 6, (12, 24))):
        images["torche_%d" % (i + 1)] = im
    images["vase_1"] = vase((210, 67, 220, 82))   # vase bleu moyen (11x16)
    images["vase_2"] = vase((258, 67, 268, 82))   # vase brun moyen
    for nom, im in images.items():
        im.save(os.path.join(SORTIE, nom + ".png"))
    print("écrit :", sorted(images))
    if len(sys.argv) > 1:   # aperçu : toutes les images côte à côte, agrandies x4, sur un sol gris
        images = {k: v for k, v in images.items() if not k.startswith(("mur_", "sol_"))}
        largeur = sum(im.width + 4 for im in images.values())
        apercu = Image.new("RGBA", (largeur, 34), (92, 105, 127, 255))
        x = 0
        for im in images.values():
            apercu.alpha_composite(im, (x, 34 - im.height))
            x += im.width + 4
        apercu.resize((apercu.width * 4, apercu.height * 4), Image.NEAREST).save(sys.argv[1])


main()
