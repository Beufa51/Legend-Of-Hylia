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


def detourer(boite):
    x0, y0, x1, y1 = boite
    c = a[y0:y1, x0:x1].copy()
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


def poser(feuille, p, cx, col, ligne, miroir=False):
    if miroir:
        p = ImageOps.mirror(p)
        cx = p.width - cx
    x = col * CW + round(CW / 2 - cx)
    y = ligne * CH + PIEDS + 1 - p.height
    feuille.alpha_composite(p, (max(col * CW, x) if x < col * CW else x, y))


lignes = 4 + 1 + 4 + 1
colonnes = 5
feuille = Image.new("RGBA", (colonnes * CW, lignes * CH), (0, 0, 0, 0))
cases_marche = {n: [case(b) for b in bs] for n, bs in boites_marche.items()}
# marche vers la droite : les images 2, 3, 5, 3 (lance calée sous le bras) ; l'image 1 n'a pas de lance visible, la 4 la tient droite
droite = [cases_marche["droite"][i] for i in (1, 2, 4, 2, 1)]
ordre = {"bas": cases_marche["bas"], "haut": cases_marche["haut"], "droite": droite}
for ligne, d in enumerate(("bas", "haut", "gauche", "droite")):
    src = ordre["droite" if d == "gauche" else d]
    for col, (p, cx) in enumerate(src):
        poser(feuille, p, cx, col, ligne, miroir=(d == "gauche"))
# repos : une image par direction
repos = {"bas": cases_marche["bas"][0], "haut": cases_marche["haut"][0], "droite": cases_marche["droite"][1]}
for col, d in enumerate(("bas", "haut", "gauche", "droite")):
    p, cx = repos["droite" if d == "gauche" else d]
    poser(feuille, p, cx, col, 4, miroir=(d == "gauche"))
# estoc
for k, d in enumerate(("bas", "haut", "gauche", "droite")):
    src = [case(b) for b in boites_poses["attaque_" + ("droite" if d == "gauche" else d)]]
    for col, (p, cx) in enumerate(src):
        poser(feuille, p, cx, col, 5 + k, miroir=(d == "gauche"))
for col, b in enumerate(boites_poses["degats"]):
    p, cx = case(b)
    poser(feuille, p, cx, col, 9)
feuille.save(SORTIE)
print("héros Gemini :", feuille.size, "échelle", round(E, 3))
