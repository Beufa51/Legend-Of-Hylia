"""Outil de développement : fabrique les PIERRES-STÈLES posées devant les griffes du Parvis, depuis la planche Gemini `Assets/Gemini/originaux/pierres_steles.jpg`
(4 pierres par rangée : vide, ailes dorées, ailes allumées...). Une pierre = un mur de briques à trois orteils, avec une fenêtre où l'on dépose le symbole d'une AILE.
Chaque pierre n'allume qu'UNE aile : la pierre gauche allume l'aile gauche, la droite l'aile droite (l'autre aile reste gravée, sombre). Les deux ensemble = le couple d'ailes.
  v_pierre_g_vide / v_pierre_g_pleine ; v_pierre_d_vide / v_pierre_d_pleine   (largeur 44 px par défaut)
Usage : python3 Outils/traiter_pierres.py [largeur_px]"""
import os, sys
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

RACINE = os.path.join(os.path.dirname(__file__), "..")
SOURCE = os.path.join(RACINE, "Assets", "Gemini", "originaux", "pierres_steles.jpg")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
ZONE_VIDE = (15, 0, 330, 350)        # pierre 1 de la rangée du haut : fenêtre vide (gravure sombre)
ZONE_OR = (360, 0, 675, 350)         # pierre 2 de la rangée du haut : ailes dorées (or posé, sans halo) : on en prend les plumes
CENTRE_X = 157                       # axe de symétrie de la pierre dans sa zone
FENETRE_Y = (150, 320)               # rangées de pixels (dans la zone) où l'on prend la moitié allumée


def plus_grande(m):
    h, w = m.shape
    vu = np.zeros_like(m, bool)
    meilleur, taille = None, 0
    for y in range(h):
        for x in range(w):
            if m[y, x] and not vu[y, x]:
                q = deque([(y, x)]); vu[y, x] = True; comp = [(y, x)]
                while q:
                    cy, cx = q.popleft()
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not vu[ny, nx]:
                            vu[ny, nx] = True; q.append((ny, nx)); comp.append((ny, nx))
                if len(comp) > taille:
                    taille, meilleur = len(comp), comp
    r = np.zeros_like(m, bool)
    for y, x in meilleur:
        r[y, x] = True
    return r


def calque_or(vide, or_, cote):
    """Calque RGBA (même taille que la zone) : l'AILE du côté `cote` ("g" ou "d") repeinte en or vif (plumes prises sur la pierre aux ailes dorées) + halo lumineux autour."""
    ref = np.array(or_.convert("RGB")).astype(int)
    h, w = ref.shape[:2]
    R, G, B = ref[..., 0], ref[..., 1], ref[..., 2]
    dore = (R > 120) & (G > 70) & (B < 120) & (R > B + 40)
    moitie = np.zeros((h, w), bool)
    if cote == "g":
        moitie[:, :CENTRE_X] = True
    else:
        moitie[:, CENTRE_X:] = True
    moitie[:FENETRE_Y[0], :] = False
    moitie[FENETRE_Y[1]:, :] = False
    plumes = dore & moitie
    plumes = np.array(Image.fromarray((plumes * 255).astype("uint8")).filter(ImageFilter.MaxFilter(3))) > 127   # plumes un peu épaissies (elles seront réduites)
    halo = np.array(Image.fromarray((plumes * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(13))).astype(float) / 255.0
    out = np.zeros((h, w, 4), float)
    out[..., 0], out[..., 1], out[..., 2] = 255, 205, 90
    out[..., 3] = np.minimum(150, halo * 330)
    ys = np.arange(h)[:, None] * np.ones((1, w))
    clair = np.clip(1.0 - (ys - FENETRE_Y[0]) / (FENETRE_Y[1] - FENETRE_Y[0]), 0, 1)
    for c, (bas, haut) in enumerate(((240, 255), (176, 238), (54, 150))):
        out[..., c] = np.where(plumes, bas + (haut - bas) * clair, out[..., c])
    out[..., 3] = np.where(plumes, 255, out[..., 3])
    return Image.fromarray(out.astype("uint8"), "RGBA")


def decouper(img, largeur, calque=None):
    """Détoure la pierre (retire magenta et terre), réduit à `largeur` px, réduit la palette ; le `calque` d'or (facultatif) est découpé et réduit pareil puis posé APRÈS la réduction de palette."""
    a = np.array(img).astype(int)
    R, G, B = a[..., 0], a[..., 1], a[..., 2]
    magenta = (R > 170) & (B > 170) & (G < 110)
    brun = (R > B + 6) & (R >= G - 2) & (R < 120)            # la terre sous la pierre
    violet = (R > G + 3) & (B > G + 3) & (R < 150)           # reste de frange magenta / ombre violette
    jaune = (R > 200) & (G > 150) & (B < 140)                # l'or des ailes : on le garde
    garde = (~(magenta | brun | violet)) | jaune
    m = np.array(Image.fromarray((garde * 255).astype("uint8")).filter(ImageFilter.MedianFilter(5))) > 127
    masque = plus_grande(m)
    masque = np.array(Image.fromarray((masque * 255).astype("uint8")).filter(ImageFilter.MinFilter(5))) > 127   # frange magenta : on rogne 2 px
    rgba = img.convert("RGBA")
    rgba.putalpha(Image.fromarray((masque * 255).astype("uint8")))
    boite = rgba.getbbox()
    rgba = rgba.crop(boite)
    h = round(rgba.height * largeur / rgba.width)
    p = rgba.resize((largeur, h), Image.LANCZOS)
    alpha = p.split()[3].point(lambda v: 255 if v > 110 else 0)
    rgb = p.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1, percent=70, threshold=2))
    q = rgb.quantize(colors=40, dither=Image.NONE).convert("RGBA")
    q.putalpha(alpha)
    if calque is not None:
        c = calque.crop(boite).resize((largeur, h), Image.LANCZOS)
        # l'or ne dépasse pas de la pierre ; les plumes (alpha fort) restent nettes
        ca = c.split()[3]
        ca = Image.composite(ca, Image.new("L", ca.size, 0), alpha)
        c.putalpha(ca)
        q.alpha_composite(c)
    return q


if __name__ == "__main__":
    largeur = int(sys.argv[1]) if len(sys.argv) > 1 else 44
    planche = Image.open(SOURCE).convert("RGB")
    vide = planche.crop(ZONE_VIDE)
    or_ = planche.crop(ZONE_OR)
    for cote in ("g", "d"):
        decouper(vide, largeur).save(os.path.join(SORTIE, "v_pierre_%s_vide.png" % cote))
        p = decouper(vide, largeur, calque_or(vide, or_, cote))
        p.save(os.path.join(SORTIE, "v_pierre_%s_pleine.png" % cote))
        print("pierre %s : %dx%d px" % (cote, p.width, p.height))
