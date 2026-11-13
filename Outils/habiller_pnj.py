"""Outil de développement : HABILLE le corps nu du pack Pixel Crawler (Entities/Characters/Body_A) pour fabriquer des habitants VUS DE 3 CÔTÉS
(bas, haut, côté) avec des BRAS visibles, marche et repos animés. Le corps est repeint par zones (cheveux, tunique, manches, pantalon, bottes, casque, chapeau).
Écrit Assets/Heros/pnj_<Nom>.png (4 poses), pnj_<Nom>_repos.png (4 images x 3 rangées : bas, haut, côté) et pnj_<Nom>_marche.png (6 images x 3 rangées).
Usage : python3 Outils/habiller_pnj.py [apercu.png]      (à lancer APRÈS preparer_pnj_pixelcrawler.py : il remplace les noms qu'il habille)"""
import os
import sys
import numpy as np
from PIL import Image

RACINE = os.path.join(os.path.dirname(__file__), "..")
ANIM = os.path.join(RACINE, "Assets", "Pixel Crawler - Free Pack", "Entities", "Characters", "Body_A", "Animations")
SORTIE = os.path.join(RACINE, "Assets", "Heros")

# tenues : tunique, manches (None = comme la tunique), pantalon, bottes, cheveux, coiffe, barbe, armure (épaules + plastron gris), gants
TENUES = {
    "Villager3": dict(tunique=(70, 84, 120), pantalon=(52, 58, 84), bottes=(60, 42, 30), cheveux=(70, 48, 30), coiffe=("casque", (150, 160, 178)), armure=(150, 160, 178)),
    "KnightGold": dict(tunique=(150, 30, 40), pantalon=(60, 40, 50), bottes=(70, 48, 28), cheveux=(60, 40, 24), coiffe=("casque", (196, 142, 44)), armure=(196, 142, 44)),
    "Villager4": dict(tunique=(64, 120, 92), pantalon=(112, 84, 52), bottes=(80, 56, 34), cheveux=(120, 78, 40), coiffe=("paille", (226, 196, 110)), armure=None),
}


def charger(nom):
    f = Image.open(os.path.join(ANIM, nom)).convert("RGBA")
    return [f.crop((i * 64, 0, i * 64 + 64, 64)) for i in range(f.width // 64)]


def luminance(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def ombrer(couleur, facteur):
    return tuple(int(max(0, min(255, v * facteur))) for v in couleur)


def habiller(case, vue, t):
    """Repeint une image du corps nu. vue = 'bas', 'haut' ou 'cote' (regard à droite)."""
    a = np.array(case).copy()
    opaque = a[:, :, 3] > 0
    if not opaque.any():
        return case
    ys, xs = np.nonzero(opaque)
    y0, y1, cx = ys.min(), ys.max(), (xs.min() + xs.max()) / 2.0
    h = y1 - y0 + 1
    peau = np.median(a[opaque][:, :3], axis=0)
    lpeau = luminance(peau)
    sortie = a.copy()
    for y in range(y0, y1 + 1):
        r = (y - y0) / h                    # 0 = haut de la tête, 1 = pieds
        for x in range(a.shape[1]):
            if not opaque[y, x]:
                continue
            px = a[y, x, :3].astype(float)
            lum = luminance(px)
            if lum < lpeau * 0.45:            # contour sombre : on le garde
                continue
            f = max(0.55, min(1.25, lum / lpeau))   # relief du corps (ombres et lumières) : on le garde
            dx = x - cx
            couleur = None
            if r < 0.30:                       # TÊTE (le visage reste visible)
                coiffe = t["coiffe"]
                if vue == "haut":
                    couleur = t["cheveux"]                                          # de dos : tout est cheveux
                elif vue == "cote":
                    if r < 0.09 or (dx < 0.0 and r < 0.20): couleur = t["cheveux"]   # dessus et arrière de la tête
                else:
                    if r < 0.08 or (abs(dx) >= 3.4 and r < 0.17): couleur = t["cheveux"]
                if coiffe[0] == "casque":
                    if vue == "haut" or r < 0.10 or (vue == "cote" and dx < 0.0 and r < 0.22) or (vue == "bas" and abs(dx) >= 3.4 and r < 0.22):
                        couleur = coiffe[1]
                if coiffe[0] == "paille" and r < 0.08:
                    couleur = coiffe[1]
            elif r < 0.62:                     # TORSE ET BRAS
                bras = abs(dx) >= 3.2 if vue != "cote" else False
                main = r > 0.55 and bras
                couleur = None if main else (t["tunique"] if not (t["armure"] and (r < 0.40 or bras)) else t["armure"])
                if not bras and 0.56 <= r < 0.62 and vue != "haut":
                    couleur = (84, 56, 30)                                         # ceinture de cuir
                if vue == "cote" and r >= 0.5 and dx > 0.5:   # le bras de devant, côté face : on le voit en manche, la main reste nue
                    couleur = None if r > 0.56 else t["tunique"]
            elif r < 0.92:                     # JAMBES
                couleur = t["pantalon"]
            else:                              # PIEDS
                couleur = t["bottes"]
            if couleur is not None:
                sortie[y, x, :3] = ombrer(couleur, f)
    img = Image.fromarray(sortie, "RGBA").copy()
    if t["coiffe"][0] == "paille" and True:   # chapeau de paille : un large bord au-dessus de la tête
        px = img.load()
        col = t["coiffe"][1]
        ys2, xs2 = np.nonzero(sortie[:, :, 3] > 0)
        top = ys2.min()
        for x in range(int(cx) - 6, int(cx) + 7):
            for y in (top + 2, top + 3):
                if 0 <= x < 64 and (x, y) not in ():
                    if px[x, y][3] == 0 or y == top + 3:
                        px[x, y] = ombrer(col, 0.95 if y == top + 2 else 0.7) + (255,)
        for x in range(int(cx) - 6, int(cx) + 7, 12):
            pass
    return img


def fabriquer(nom, t):
    rangees = {"repos": [], "marche": []}
    for kind, fichiers in (("repos", ("Idle_Base/Idle_Down-Sheet.png", "Idle_Base/Idle_Up-Sheet.png", "Idle_Base/Idle_Side-Sheet.png")),
                           ("marche", ("Walk_Base/Walk_Down-Sheet.png", "Walk_Base/Walk_Up-Sheet.png", "Walk_Base/Walk_Side-Sheet.png"))):
        for vue, f in zip(("bas", "haut", "cote"), fichiers):
            images = [habiller(c, vue, t) for c in charger(f)]
            rangees[kind].append(images)
    # boîte commune : toutes les images rognées pareil, pieds en bas d'une case de 32 px
    toutes = [im for k in rangees.values() for r in k for im in r]
    boites = [im.getchannel("A").getbbox() for im in toutes]
    x0, y0 = min(b[0] for b in boites), min(b[1] for b in boites)
    x1, y1 = max(b[2] for b in boites), max(b[3] for b in boites)
    def case32(im):
        c = Image.new("RGBA", (32, 32))
        p = im.crop((x0, y0, x1, y1))
        c.alpha_composite(p, ((32 - p.width) // 2, 32 - p.height))
        return c
    for kind, n in (("repos", 4), ("marche", 6)):
        planche = Image.new("RGBA", (32 * n, 96))
        for ligne, images in enumerate(rangees[kind]):
            for i, im in enumerate(images[:n]):
                planche.alpha_composite(case32(im), (i * 32, ligne * 32))
        planche.save(os.path.join(SORTIE, "pnj_%s_%s.png" % (nom, kind)))
    # poses fixes : bas, haut, gauche, droite (première image au repos)
    bas, haut, cote = (case32(rangees["repos"][i][0]) for i in range(3))
    sheet = Image.new("RGBA", (128, 32))
    for i, c in enumerate((bas, haut, cote.transpose(Image.FLIP_LEFT_RIGHT), cote)):
        sheet.alpha_composite(c, (i * 32, 0))
    sheet.save(os.path.join(SORTIE, "pnj_%s.png" % nom))


if __name__ == "__main__":
    for nom, t in TENUES.items():
        fabriquer(nom, t)
    print("habitants habillés :", ", ".join(TENUES))
    if len(sys.argv) > 1:
        noms = list(TENUES)
        prev = Image.new("RGBA", (len(noms) * 4 * 32, 4 * 32), (51, 118, 3, 255))
        for k, nom in enumerate(noms):
            rep = Image.open(os.path.join(SORTIE, "pnj_%s_repos.png" % nom)).convert("RGBA")
            mar = Image.open(os.path.join(SORTIE, "pnj_%s_marche.png" % nom)).convert("RGBA")
            for ligne in range(3):
                prev.alpha_composite(rep.crop((0, ligne * 32, 32, ligne * 32 + 32)), (k * 128 + ligne * 32, 0))
                for i in range(0, 4):
                    prev.alpha_composite(mar.crop((i * 32, ligne * 32, i * 32 + 32, ligne * 32 + 32)), (k * 128 + i * 32, 32 + ligne * 32))
        prev.resize((prev.width * 3, prev.height * 3), Image.NEAREST).save(sys.argv[1])
