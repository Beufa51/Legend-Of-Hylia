"""HÉROS PIXEL CRAWLER (2026-11-16) : habille le corps nu du pack (Assets/Pixel Crawler - Free Pack/Entities/Characters/Body_A) en jeune garde royal à lance
et fabrique TOUTES ses animations : marche (6 images) et repos (4) de face / de dos / de profil, estoc de lance (8) dans les 3 vues (l'épée du pack est remplacée par une lance),
touché (hit) et mort. Le profil gauche = le profil droit retourné.
Écrit Assets/Heros/heros_pc.png (cases CASE x CASE) ; lignes : marche bas/haut/gauche/droite (6), repos bas/haut/gauche/droite (4), estoc bas/haut/gauche/droite (8), touche bas/haut/gauche/droite (4).
Le pack autorise les modifications et l'usage commercial (pas la revente des fichiers seuls) : voir Terms.txt du pack.
Usage : python3 Outils/habiller_heros.py [apercu.png]      (indépendant des autres outils ; réutilise habiller() d'habiller_pnj.py)"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import habiller_pnj as hp

RACINE = os.path.join(os.path.dirname(__file__), "..")
ANIM = hp.ANIM
SORTIE = os.path.join(RACINE, "Assets", "Heros")
CASE = (56, 48)       # largeur, hauteur d'une case de la planche finale (pieds en bas, centre du corps au milieu)

TENUE = dict(tunique=(46, 88, 178), pantalon=(124, 116, 88), bottes=(98, 66, 40), cheveux=(34, 30, 42), coiffe=("casque", (126, 140, 158)), armure=None)
NOIR = (0, 0, 0)
BOIS = (150, 98, 58)
BOIS_OMBRE = (110, 70, 42)
ACIER = (206, 214, 226)
ACIER_OMBRE = (130, 140, 156)
OR = (240, 190, 50)
ROUGE = (186, 36, 44)

# couleurs EXACTES de l'épée dans les planches d'estoc (acier, acier sombre, garde brune, gemme verte)
COULEURS_EPEE = {(146, 143, 136), (204, 201, 194), (255, 255, 254), (64, 69, 69), (167, 172, 174), (255, 252, 252), (118, 61, 43), (76, 181, 40)}


def charger(chemin):
    f = Image.open(os.path.join(ANIM, chemin)).convert("RGBA")
    return [f.crop((i * 64, 0, i * 64 + 64, 64)) for i in range(f.width // 64)]


def retirer_epee(case):
    """Efface l'épée (couleurs exactes + son contour noir qui ne touche pas la peau). Renvoie (corps sans épée, masque de l'épée)."""
    a = np.array(case).copy()
    rgb = a[..., :3].astype(int)
    op = a[..., 3] > 0
    epee = np.zeros(op.shape, bool)
    for c in COULEURS_EPEE:
        epee |= op & (rgb[..., 0] == c[0]) & (rgb[..., 1] == c[1]) & (rgb[..., 2] == c[2])
    peau = op & (((rgb[..., 0] == 217) & (rgb[..., 1] == 160)) | ((rgb[..., 0] == 162) & (rgb[..., 1] == 101)) | ((rgb[..., 0] == 250) & (rgb[..., 1] == 200)))
    noir = op & (rgb.sum(axis=2) == 0)
    zone = ndimage.binary_dilation(epee, structure=np.ones((3, 3)), iterations=1)
    pres_peau = ndimage.binary_dilation(peau, structure=np.ones((3, 3)), iterations=1)
    contour_epee = noir & zone & ~pres_peau
    efface = epee | contour_epee
    a[efface] = (0, 0, 0, 0)
    return Image.fromarray(a, "RGBA"), efface


def boite(img):
    return img.getchannel("A").getbbox()


# --- La lance (dessinée en pixels, contour noir de 1 px comme tout le pack) ------------------------------------------------
def lance(img, pointe, direction, longueur):
    """Dessine une lance dont la POINTE est en `pointe` (x, y) et qui s'étend vers l'arrière sur `longueur` pixels.
    direction = (dx, dy) : sens dans lequel la pointe regarde ((0,1) bas, (0,-1) haut, (1,0) droite)."""
    px = img.load()
    dx, dy = direction
    nx, ny = -dy, dx          # perpendiculaire

    def poser(x, y, c):
        if 0 <= x < img.width and 0 <= y < img.height:
            px[x, y] = c + (255,)

    # manche : 1 px de bois au centre, contour noir de chaque côté
    for k in range(8, longueur):
        x, y = pointe[0] - dx * k, pointe[1] - dy * k
        poser(x + nx, y + ny, NOIR)
        poser(x - nx, y - ny, NOIR)
    for k in range(8, longueur):
        x, y = pointe[0] - dx * k, pointe[1] - dy * k
        poser(x, y, BOIS if k % 5 else BOIS_OMBRE)
    # bout du manche
    poser(pointe[0] - dx * longueur, pointe[1] - dy * longueur, NOIR)
    # fer : feuille pointue de 7 px de long (1 px de pointe, 3 px de large au milieu), contour noir, éclat clair d'un côté
    largeurs = (0, 0, 1, 1, 1, 0, 0)
    for prof, larg in enumerate(largeurs):
        for lat in range(-larg - 1, larg + 2):
            x, y = pointe[0] - dx * prof + nx * lat, pointe[1] - dy * prof + ny * lat
            if abs(lat) == larg + 1 or prof == 0:
                poser(x, y, NOIR)
            else:
                poser(x, y, ACIER if lat <= 0 else ACIER_OMBRE)
    poser(pointe[0] - dx * 7, pointe[1] - dy * 7, NOIR)
    for lat in (-1, 0, 1):   # collerette
        x, y = pointe[0] - dx * 7 + nx * lat, pointe[1] - dy * 7 + ny * lat
        poser(x, y, NOIR if lat else ACIER_OMBRE)
    return img


def embleme_coq(img, vue, cx, y_torse):
    """Petit coq doré sur la poitrine (de face seulement), cimier rouge sur le casque de face et de côté."""
    px = img.load()
    if vue == "bas":
        for (dx, dy) in ((0, 0), (1, 0), (0, 1), (-1, 1), (0, 2), (1, 2), (-1, 0)):
            x, y = int(cx) + dx, y_torse + dy
            if px[x, y][3] > 0:
                px[x, y] = OR + (255,)
        if px[int(cx) + 2, y_torse - 1][3] > 0:
            px[int(cx) + 2, y_torse - 1] = ROUGE + (255,)


PEAU_CLAIRE, PEAU_OMBRE, PEAU_SOMBRE, PEAU_LUMIERE = (217, 160, 102), (162, 101, 67), (118, 61, 43), (250, 200, 149)
COULEUR_TUNIQUE = (46, 88, 178)
COULEUR_CASQUE = (126, 140, 158)
COULEUR_CHEVEUX = (36, 30, 46)
COULEUR_PANTALON = (124, 116, 88)
COULEUR_BOTTES = (98, 66, 40)
COULEUR_CEINTURE = (84, 56, 30)


def nuance(couleur, categorie):
    """Reprend l'ombre / la lumière du corps nu : clair = couleur, ombre = plus sombre, très sombre, lumière = plus claire."""
    f = {"claire": 1.0, "ombre": 0.74, "sombre": 0.52, "lumiere": 1.22}[categorie]
    return tuple(int(max(0, min(255, v * f))) for v in couleur)


def categorie_peau(c):
    c = tuple(int(v) for v in c)
    return {PEAU_CLAIRE: "claire", PEAU_OMBRE: "ombre", PEAU_SOMBRE: "sombre", PEAU_LUMIERE: "lumiere"}.get(c)


def habiller_image(case, vue, tete_gemini_activee=True):
    """Repeint un corps nu de 31 lignes : tête 14 lignes (casque en haut, cheveux sur les côtés, visage nu), torse 8 lignes (tunique, ceinture, mains nues),
    jambes 9 lignes (pantalon puis bottes). Les contours noirs, les yeux et les orteils ne bougent pas."""
    a = np.array(case).copy()
    op = a[..., 3] > 0
    ys, xs = np.nonzero(op)
    y0, y1 = ys.min(), ys.max()
    # centre du corps : milieu de la tête (lignes 2 à 8)
    tete = [x for y, x in zip(ys, xs) if 2 <= y - y0 <= 8]
    cx = float(np.median(tete)) if tete else float(np.median(xs))
    hauteur = y1 - y0 + 1
    for y, x in zip(ys, xs):
        cat = categorie_peau(a[y, x, :3])
        if cat is None:
            continue
        r = y - y0
        dx = x - cx
        couleur = None
        if r <= 13:                                   # TÊTE
            if vue == "haut":
                couleur = COULEUR_CASQUE if r <= 9 else COULEUR_CHEVEUX
            elif vue == "bas":
                if r <= 5:
                    couleur = COULEUR_CASQUE
                elif cat in ("ombre", "sombre") and abs(dx) >= 3.5:
                    couleur = COULEUR_CHEVEUX
            else:                                     # profil (regard à droite) : l'arrière de la tête est à gauche
                if r <= 5:
                    couleur = COULEUR_CASQUE
                elif cat in ("ombre", "sombre") or dx < -2.5:
                    couleur = COULEUR_CHEVEUX
        elif r <= 21:                                 # TORSE ET BRAS
            bras = abs(dx) >= 3.4 if vue != "cote" else True
            main = r >= 19 and (abs(dx) >= 3.4 if vue != "cote" else dx > 1.5)
            if not main:
                couleur = COULEUR_TUNIQUE
                if r in (19, 20) and not bras and vue != "cote":
                    couleur = COULEUR_CEINTURE
                if vue == "cote" and r in (19, 20):
                    couleur = COULEUR_CEINTURE
        elif r < hauteur - 3:                         # JAMBES
            couleur = COULEUR_PANTALON
        else:                                         # PIEDS
            couleur = COULEUR_BOTTES
        if couleur is not None:
            a[y, x, :3] = nuance(couleur, cat)
    img = Image.fromarray(a, "RGBA").copy()
    px = img.load()
    # reflet du casque (1 ligne claire en haut à gauche) et liseré bas du casque
    for x in range(int(cx) - 5, int(cx) + 6):
        for y in range(y0, y0 + 8):
            if 0 <= x < 64 and px[x, y][3] > 0 and tuple(px[x, y][:3]) == nuance(COULEUR_CASQUE, "claire") and y == y0 + 1 and x < cx:
                px[x, y] = tuple(min(255, int(v * 1.25)) for v in COULEUR_CASQUE) + (255,)
    # coq doré sur la poitrine (de face), boucle de ceinture
    if vue == "bas":
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 1), (1, 1), (0, 2)):
            x, yy = int(round(cx)) + dx, y0 + 15 + dy
            if px[x, yy][3] > 0 and tuple(px[x, yy][:3]) != (0, 0, 0):
                px[x, yy] = OR + (255,)
        bx, by = int(round(cx)), y0 + 19
        if px[bx, by][3] > 0:
            px[bx, by] = OR + (255,)
    if tete_gemini_activee:
        img = remplacer_tete(img, vue, cx, y0)
    return img


# --- La TÊTE du héros Gemini (casque, cheveux, visage) posée sur le corps animé du pack ---------------------------------------
LARGEUR_TETE = {"bas": 18, "haut": 18, "cote": 15}   # largeur (px) de la tête Gemini selon la vue : de face / de dos, tête large de chibi comme le héros Gemini ; de profil 15
_TETES = {}


def _detourer(arr, boite):
    x0, y0, x1, y1 = boite
    c = arr[y0:y1, x0:x1].copy()
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    fond = (r > 150) & (b > 150) & (g < 120)
    lab, n = ndimage.label(~fond)
    tailles = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    m = np.isin(lab, [i + 1 for i, t in enumerate(tailles) if t > tailles.max() * 0.03])
    m &= ~ndimage.binary_dilation(fond, iterations=2) | ndimage.binary_erosion(m, iterations=3)
    gris = m & (np.abs(r - g) < 30) & (np.abs(g - b) < 40) & (r > 85) & (r < 155) & (b > 95)
    cx = float(np.median(np.nonzero(gris)[1])) if gris.any() else c.shape[1] / 2
    c[~m] = (16, 16, 22)
    al = (m * 255).astype(np.uint8)
    return Image.merge("RGBA", (*Image.fromarray(c.astype(np.uint8)).split(), Image.fromarray(al))), c, m, cx


def tete_gemini(vue):
    """Tête du héros Gemini réduite à LARGEUR_TETE px : (image RGBA, x du centre du casque dans l'image)."""
    if vue in _TETES:
        return _TETES[vue]
    base = os.path.join(RACINE, "Assets", "Gemini", "originaux")
    if vue == "cote":
        arr = np.array(Image.open(os.path.join(base, "heros_profil.jpg")).convert("RGB")).astype(int)
        boite, depart = (254, 24, 411, 318), "tunique"
    else:
        arr = np.array(Image.open(os.path.join(base, "heros.jpg")).convert("RGB")).astype(int)
        boite, depart = ((5, 0, 145, 190), "tunique") if vue == "bas" else ((5, 190, 145, 385), "cape")
    im, c, m, cx = _detourer(arr, boite)
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    vetement = m & (b > 140) & (r < 90) & (g < 130) if depart == "tunique" else m & (r > 100) & (r < 190) & (g > 55) & (g < 110) & (b < 70)
    cou = int(np.nonzero(vetement.sum(axis=1) >= (8 if vue != "cote" else 6))[0].min())
    tete = im.crop((0, 0, im.width, cou))
    tete = tete.crop(tete.getchannel("A").getbbox()) if tete.getchannel("A").getbbox() else tete
    x_casque = cx - im.getchannel("A").getbbox()[0] if False else cx
    # recadrage : on garde la position du centre du casque après le recadrage
    bb0 = im.crop((0, 0, im.width, cou)).getchannel("A").getbbox()
    cx_local = cx - bb0[0]
    echelle = LARGEUR_TETE[vue] / tete.width
    w, h = LARGEUR_TETE[vue], max(1, round(tete.height * echelle))
    rgb = Image.merge("RGB", tete.split()[:3]).filter(ImageFilter.GaussianBlur(0.5)).resize((w, h), Image.LANCZOS)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=2))
    al = tete.getchannel("A").resize((w, h), Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)
    petite = Image.merge("RGBA", (*rgb.split(), al))
    _TETES[vue] = (petite, cx_local * echelle)
    return _TETES[vue]


def remplacer_tete(img, vue, cx_tete, y0):
    """Efface la tête du pack (lignes 0 à 13 du corps) et pose la tête Gemini, son bas sur la ligne du menton."""
    a = np.array(img).copy()
    a[y0:y0 + 14, :, 3] = 0
    img = Image.fromarray(a, "RGBA")
    tete, cx_local = tete_gemini(vue)
    x = int(round(cx_tete - cx_local))
    y = y0 + 14 - tete.height
    img.alpha_composite(tete, (x, y))
    return img


def ajouter_lance_portee(img, vue, y0_ref, bob):
    """Lance portée au côté (marche, repos, touché) : verticale à gauche de face, verticale à droite de dos, horizontale devant le ventre de profil."""
    if vue == "bas":
        lance(img, (22, y0_ref + 2 + bob), (0, -1), 28)
    elif vue == "haut":
        lance(img, (42, y0_ref + 2 + bob), (0, -1), 28)
    else:
        lance(img, (46, y0_ref + 19 + bob), (1, 0), 30)
    return img


def fabriquer_animation(chemin, vue, avec_epee=False):
    """Renvoie la liste (image habillée, rien) de l'animation. Marche / repos / touché : lance portée ; estoc : l'épée est remplacée par une lance."""
    images = []
    originales = charger(chemin)
    haut0 = min(c.getchannel("A").getbbox()[1] for c in originales)
    for c in originales:
        if avec_epee:
            corps, masque = retirer_epee(c)
            img = habiller_image(corps, vue)
            ys, xs = np.nonzero(masque)
            if len(xs):
                if vue == "bas":
                    bas = ys.max()
                    tx = int(round(np.median(xs[ys >= bas - 2])))
                    lance(img, (tx, bas - 1), (0, 1), int(ys.max() - ys.min()) + 12)
                elif vue == "haut":
                    haut = ys.min()
                    tx = int(round(np.median(xs[ys <= haut + 2])))
                    lance(img, (tx, haut + 1), (0, -1), int(ys.max() - ys.min()) + 12)
                else:
                    droite = xs.max()
                    ty = int(round(np.median(ys[xs >= droite - 2])))
                    lance(img, (droite - 1, ty), (1, 0), int(xs.max() - xs.min()) + 12)
            images.append((img, None))
        else:
            img = habiller_image(c, vue)
            b = c.getchannel("A").getbbox()
            ajouter_lance_portee(img, vue, haut0, b[1] - haut0)
            images.append((img, None))
    return images


def main():
    vues = {"bas": "Down", "haut": "Up", "cote": "Side"}
    anims = {}
    for nom, dossier, fich in (("marche", "Walk_Base", "Walk_%s-Sheet.png"), ("repos", "Idle_Base", "Idle_%s-Sheet.png"), ("touche", "Hit_Base", "Hit_%s-Sheet.png")):
        for vue, suffixe in vues.items():
            anims[(nom, vue)] = fabriquer_animation("%s/%s" % (dossier, fich % suffixe), vue)
    for vue, suffixe in (("bas", "Down"), ("haut", "Top"), ("cote", "Side")):
        anims[("estoc", vue)] = fabriquer_animation("Pierce_Base/Pierce_%s-Sheet.png" % suffixe, vue, avec_epee=True)
    return anims


def assembler(anims):
    """Planche finale heros_pc.png : cases de même taille, centre du corps (x = 32 dans le pack) au milieu, pieds alignés."""
    tout = [im for v in anims.values() for im, _ in v]
    boites = [im.getchannel("A").getbbox() for im in tout]
    miny, maxy = min(b[1] for b in boites), max(b[3] for b in boites)
    demi = max(32 - min(b[0] for b in boites), max(b[2] for b in boites) - 32) + 1
    largeur, hauteur = 2 * demi, maxy - miny
    pieds = 49 - miny                                        # ligne (dans la case) juste sous les pieds du corps nu (dernière ligne = 48)
    lignes = [("marche", "bas"), ("marche", "haut"), ("marche", "cote"), ("marche", "cote_g"), ("repos", "bas"), ("repos", "haut"), ("repos", "cote"), ("repos", "cote_g"),
              ("estoc", "bas"), ("estoc", "haut"), ("estoc", "cote"), ("estoc", "cote_g"), ("touche", "bas"), ("touche", "haut"), ("touche", "cote"), ("touche", "cote_g")]
    planche = Image.new("RGBA", (8 * largeur, len(lignes) * hauteur))
    for r, (nom, vue) in enumerate(lignes):
        miroir = vue.endswith("_g")
        images = anims[(nom, vue[:-2] if miroir else vue)]
        for i, (im, _) in enumerate(images):
            c = im.crop((32 - demi, miny, 32 + demi, maxy))
            if miroir:
                c = c.transpose(Image.FLIP_LEFT_RIGHT)
            planche.alpha_composite(c, (i * largeur, r * hauteur))
    planche.save(os.path.join(SORTIE, "heros_pc.png"))
    return largeur, hauteur, pieds


if __name__ == "__main__":
    anims = main()
    largeur, hauteur, pieds = assembler(anims)
    print("heros_pc.png : case %dx%d, pieds à la ligne %d" % (largeur, hauteur, pieds))
    if len(sys.argv) > 1:
        planche = Image.open(os.path.join(SORTIE, "heros_pc.png"))
        fond = Image.new("RGBA", planche.size, (90, 130, 70, 255))
        fond.alpha_composite(planche)
        fond.resize((fond.width * 2, fond.height * 2), Image.NEAREST).save(sys.argv[1])
