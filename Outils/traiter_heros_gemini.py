"""Héros Gemini (2026-11-15) : originaux/heros.jpg -> Assets/Heros/heros_g.png (cases de 48x32).
Si ce fichier existe, `player.gd` l'utilise à la place de heros_marche.png / heros_coup.png (l'ancien héros LPC reste en repli).

Lignes de la planche (de haut en bas) : marche_bas, marche_haut, marche_gauche, marche_droite (5 images chacune),
repos (4 cases : bas, haut, gauche, droite), attaque_bas, attaque_haut, attaque_gauche, attaque_droite (3 images : posture, estoc, estoc tenu),
degats (3 cases : surpris, touché, assommé : pas encore utilisées par le jeu).
La gauche est la droite retournée. Chaque image est posée en alignant le CENTRE DU CASQUE (gris) au milieu de la case, les pieds en bas (ligne 29).
"""
import numpy as np
from PIL import Image, ImageFilter, ImageOps
from scipy import ndimage

SRC = "Assets/Gemini/originaux/heros.jpg"
SORTIE = "Assets/Heros/heros_g.png"
CW, CH, PIEDS = 48, 32, 29
HAUTEUR_HEROS = 25     # un héros debout (casque aux bottes) fait 25 px de haut

a = np.array(Image.open(SRC).convert("RGB")).astype(int)


def detourer(boite, efface=None):
    """efface = ("g", x) ou ("d", x) : efface la lance tenue en main (tout ce qui est à gauche / à droite de la colonne x, sauf la main) pour la redessiner en code."""
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
    if efface:
        r_, g_, b_ = c[..., 0], c[..., 1], c[..., 2]
        peau = (r_ > 200) & (g_ > 120) & (g_ < 205) & (b_ > 80) & (b_ < 175)
        colonnes = np.arange(c.shape[1])[None, :]
        zone = (colonnes < efface[1]) if efface[0] == "g" else (colonnes >= efface[1])
        c[zone & ~peau] = (255, 0, 255)
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.03])
    m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)
    # centre du casque : pixels gris-bleu (le fer de lance, plus clair, est ignoré par la médiane)
    gris = m & (np.abs(r - g) < 25) & (np.abs(g - b) < 35) & (r > 70) & (r < 150)
    ys, xs = np.nonzero(gris)
    haut = ys.min() if len(ys) else 0
    casque = gris & (np.arange(c.shape[0])[:, None] < haut + 0.35 * (np.nonzero(m)[0].max() - np.nonzero(m)[0].min()))
    xs2 = np.nonzero(casque)[1]
    cx = float(np.median(xs2)) if len(xs2) else c.shape[1] / 2
    c[~m] = (16, 16, 22)
    al = (m * 255).astype(np.uint8)
    im = Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al)))
    bb = im.getbbox()
    return im.crop(bb), cx - bb[0]


def reduire(im, echelle):
    w, h = max(1, round(im.width * echelle)), max(1, round(im.height * echelle))
    rgb = Image.merge("RGB", im.split()[:3]).filter(ImageFilter.GaussianBlur(0.6)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = im.split()[3].resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    return Image.merge("RGBA", (*rgb.split(), al))


# fenêtres des images (x, y) dans la planche 1408x768
LIGNES_Y = [(0, 190), (190, 385), (385, 578), (578, 768)]
PAS = [(5, 145), (145, 285), (285, 425), (425, 565), (565, 705)]
boites_marche = {n: [(x0, LIGNES_Y[r][0], x1, LIGNES_Y[r][1]) for (x0, x1) in PAS] for n, r in (("bas", 0), ("haut", 1), ("droite", 2))}
boites_poses = {
    "attaque_bas": [(860, 0, 970, 190), (995, 0, 1180, 190), (1190, 0, 1380, 190)],
    "attaque_haut": [(860, 190, 975, 385), (1005, 190, 1220, 385), (1005, 190, 1220, 385)],   # 3e pose de la planche = un poing tourné : on tient l'estoc
    "attaque_droite": [(858, 385, 1003, 578), (1007, 385, 1225, 578), (1240, 385, 1395, 578)],
    "degats": [(1000, 578, 1115, 768), (1125, 578, 1245, 768), (1255, 578, 1400, 768)],
}
# échelle commune : le héros debout (1re image de marche vers le bas) fait HAUTEUR_HEROS px
ref, _ = detourer(boites_marche["bas"][0])
E = HAUTEUR_HEROS / ref.height


def case(boite):
    im, cx = detourer(boite)
    p = reduire(im, E)
    return p, cx * E


def poser(feuille, p, cx, col, ligne, miroir=False, dy=0):
    if miroir:
        p = ImageOps.mirror(p)
        cx = p.width - cx
    x = col * CW + round(CW / 2 - cx)
    y = ligne * CH + PIEDS + 1 - p.height + dy
    feuille.alpha_composite(p, (max(col * CW, x) if x < col * CW else x, y))


lignes = 4 + 1 + 4 + 1
colonnes = 8
feuille = Image.new("RGBA", (colonnes * CW, lignes * CH), (0, 0, 0, 0))
cases_marche = {n: [case(b) for b in bs] for n, bs in boites_marche.items()}
# MARCHE : les 5 images de marche de la planche Gemini sont presque identiques (on ne voyait pas les pas) : on fabrique un vrai cycle
# de 8 images à partir d'UNE image de base : un pied se lève (jusqu'à 2 px, les bottes montent), puis l'autre, et le corps monte d'1 px
# quand un pied est au plus haut (balancement). Les images de base : face = 1re de la ligne du haut, dos = 1re, profil = 2e (lance calée sous le bras).
ZONE_PIEDS = 7                       # les 6 dernières lignes (bottes + bas du pantalon) bougent
LEVEE_G = [0, 2, 3, 2, 0, 0, 0, 0]   # hauteur du pied gauche (de l'image) à chaque image du cycle
LEVEE_D = [0, 0, 0, 0, 0, 2, 3, 2]   # hauteur du pied droit
BALANCEMENT = [0, 0, -1, 0, 0, 0, -1, 0]


def pas(p, cx, levee_g, levee_d):
    h = p.height
    res = p.copy()
    coupe = max(1, min(p.width - 1, round(cx)))
    for (x0, x1, levee) in ((0, coupe, levee_g), (coupe, p.width, levee_d)):
        if levee == 0:
            continue
        boite = (x0, h - ZONE_PIEDS, x1, h)
        zone = p.crop(boite)
        res.paste(Image.new("RGBA", zone.size, (0, 0, 0, 0)), boite)
        res.alpha_composite(zone, (x0, h - ZONE_PIEDS - levee))
    return res


# PROFIL (originaux/heros_profil.jpg, 2e planche Gemini : 8 vraies images de marche de profil, jambes bien différentes d'une image à l'autre,
# MAIS la lance change de place à chaque image). On garde donc les JAMBES de chaque image et on les place sous UN SEUL haut du corps
# (image 8 de la rangée du haut : lance portée à l'horizontale) : la lance reste fixe, les pas sont ceux de Gemini.
PROFIL = np.array(Image.open("Assets/Gemini/originaux/heros_profil.jpg").convert("RGB")).astype(int)
BOITES_PROFIL = [(4, 13, 242, 323), (254, 24, 411, 318), (427, 12, 581, 323), (587, 2, 802, 308),
                 (786, 13, 1002, 323), (1004, 24, 1161, 318), (1182, 14, 1324, 323), (1331, 6, 1584, 308)]
HAUT_DU_CORPS = 7                    # image qui donne le haut du corps (et la lance)
E_PROFIL = E * 50 / 84               # le casque de profil fait 84 px ici contre 50 px sur la planche d'origine : même taille de casque


def image_profil(boite):
    """Image RGBA (taille de la boîte) d'une image de profil, centre du casque (x) et dernière ligne de la tunique bleue (la hanche)."""
    x0, y0, x1, y1 = boite
    c = PROFIL[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.03])
    m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)
    gris = m & (np.abs(r - g) < 30) & (np.abs(g - b) < 40) & (r > 85) & (r < 155) & (b > 95)
    cx = float(np.median(np.nonzero(gris)[1]))
    bleu = m & (b > 140) & (r < 90) & (g < 130)
    lignes = np.nonzero(bleu.sum(axis=1) >= 3)[0]
    hanche = int(lignes.max())
    c[~m] = (16, 16, 22)
    al = (m * 255).astype(np.uint8)
    return Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al))), cx, hanche


haut_im, haut_cx, haut_hanche = image_profil(BOITES_PROFIL[HAUT_DU_CORPS])
haut_im = haut_im.crop((0, 0, haut_im.width, haut_hanche + 1))
# Les images 4 et 8 de la rangée du haut font SAUTER tout le corps de 15 px (pieds en l'air) : on avait l'impression d'enjamber un obstacle à chaque pas.
# On garde les 6 images où les pieds restent au sol : contact, milieu, passage, contact (autre jambe), milieu, passage.
IMAGES_PROFIL = [0, 1, 2, 4, 5, 6]
profil = []
for boite in [BOITES_PROFIL[i] for i in IMAGES_PROFIL]:
    jambes_im, jambes_cx, jambes_hanche = image_profil(boite)
    jambes = jambes_im.crop((0, jambes_hanche + 1, jambes_im.width, jambes_im.height))
    toile = Image.new("RGBA", (700, 380), (0, 0, 0, 0))
    ox = 350 - round(haut_cx)
    toile.alpha_composite(haut_im, (ox, 0))
    toile.alpha_composite(jambes, (350 - round(jambes_cx), haut_hanche + 1))
    bb = toile.getbbox()
    rogne = toile.crop(bb)
    profil.append((reduire(rogne, E_PROFIL), (350 - bb[0]) * E_PROFIL))

bases = {"bas": cases_marche["bas"][0], "haut": cases_marche["haut"][0]}
BALANCEMENT_PROFIL = [0, 1, 0, 0, 1, 0]
for ligne, d in enumerate(("bas", "haut", "gauche", "droite")):
    if d in ("gauche", "droite"):
        for col in range(len(profil)):
            p, cx = profil[col]
            poser(feuille, p, cx, col, ligne, miroir=(d == "gauche"), dy=BALANCEMENT_PROFIL[col])
        continue
    p, cx = bases[d]
    for col in range(8):
        image = pas(p, cx, LEVEE_G[col], LEVEE_D[col])
        poser(feuille, image, cx, col, ligne, miroir=False, dy=BALANCEMENT[col])
# repos : une image par direction
repos = {"bas": cases_marche["bas"][0], "haut": cases_marche["haut"][0], "droite": profil[1]}
for col, d in enumerate(("bas", "haut", "gauche", "droite")):
    p, cx = repos["droite" if d == "gauche" else d]
    poser(feuille, p, cx, col, 4, miroir=(d == "gauche"))
# estoc : gauche / droite = poses de profil de la planche ; bas / haut = le héros de face / de dos SANS lance dans la main
# (la planche Gemini ne dessine la lance que de profil) ; player.gd redessine alors la lance (lance_g.png) qui avance vers le bas / le haut.
def sans_lance(boite, efface, penche):
    im, cx = detourer(boite, efface)
    p = reduire(im, E)
    return [(p, cx * E), (p, cx * E), (p, cx * E)], penche


for k, d in enumerate(("bas", "haut", "gauche", "droite")):
    if d == "bas":
        src, _ = sans_lance(boites_marche["bas"][0], ("g", 23), 1)
    elif d == "haut":
        src, _ = sans_lance(boites_marche["haut"][0], ("d", 98), -1)
    else:
        src = [case(b) for b in boites_poses["attaque_" + ("droite" if d == "gauche" else d)]]
    for col, (p, cx) in enumerate(src):
        poser(feuille, p, cx, col, 5 + k, miroir=(d == "gauche"))
        if d in ("bas", "haut") and col > 0:   # corps qui se penche d'un pixel vers l'avant pendant l'estoc
            pass
for col, b in enumerate(boites_poses["degats"]):
    p, cx = case(b)
    poser(feuille, p, cx, col, 9)
feuille.save(SORTIE)

# La lance redessinée EN PIXELS (le fer de la planche Gemini devient illisible à cette taille) : pointe d'acier + manche brun, pointe vers le BAS.
# La main tient la lance à ~38 % de sa longueur depuis la pointe (voir player.gd::MAIN_LANCE).
LONG, LARG = 26, 5
D, L, M, B1, B2 = (36, 36, 52, 255), (214, 222, 234, 255), (150, 166, 188, 255), (40, 24, 18, 255), (122, 78, 42, 255)
fer = ["..d..", ".dld.", ".dld.", "dlmld", "dlmld", ".dmd.", "..d.."]
lance = Image.new("RGBA", (LARG, LONG), (0, 0, 0, 0))
code = {"d": D, "l": L, "m": M}
for y, ligne in enumerate(fer):
    for x, ch in enumerate(ligne):
        if ch in code:
            lance.putpixel((x, y), code[ch])
for y in range(len(fer), LONG):
    lance.putpixel((1, y), B1)
    lance.putpixel((2, y), B2)
    lance.putpixel((3, y), B1)
lance.transpose(Image.FLIP_TOP_BOTTOM).save("Assets/Heros/lance_g.png")   # pointe vers le bas
print("lance_g.png", lance.size)
