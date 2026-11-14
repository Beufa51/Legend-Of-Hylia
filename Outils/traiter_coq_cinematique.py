#!/usr/bin/env python3
"""Découpe l'image du coq-forteresse en CALQUES pour la cinématique d'assemblage (Scripts/assemblage.gd).

Sources (Assets/Gemini/originaux/, toutes alignées au pixel près, 1408x768) :
  Coq_sans_ailes.jpg      corps seul (ailes absentes, herbe à leur place), bec de profil
  Coq_forteresse_bec.jpg  coq assemblé avec le bec de face = image FINALE

Sorties (Assets/Cinematique/) :
  corps.png   RGBA, château sans ailes (donjon rond, tour de tête avec le nouveau bec, queue, griffes), sur transparent
  aile_g.png  aile gauche (RGBA, recadrée)      aile_d.png  aile droite
  sol.png     le sol vide (herbe, arbres, chemin) : le château en est retiré
  coq_final.png  contrôle : sol + corps + ailes recomposés (doit ressembler à Coq_forteresse_bec.jpg)
  calques.json   positions (en pixels de l'image source) : origine de chaque calque, épaules (pivots des ailes)
À relancer si l'une des 2 images sources change.
"""
import json
import os

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(RACINE, "Assets", "Gemini", "originaux")
SORTIE = os.path.join(RACINE, "Assets", "Cinematique")
os.makedirs(SORTIE, exist_ok=True)

sans = Image.open(os.path.join(SRC, "Coq_sans_ailes.jpg")).convert("RGB")
final = Image.open(os.path.join(SRC, "Coq_forteresse_bec.jpg")).convert("RGB")
S = np.asarray(sans).astype(np.int16)
F = np.asarray(final).astype(np.int16)
H, W = S.shape[:2]


def lisse(masque, rayon=1.2):
    """Bords doux (alpha) à partir d'un masque booléen."""
    return np.clip(ndi.gaussian_filter(masque.astype(np.float32), rayon) * 1.6 - 0.1, 0, 1)


def composante_principale(masque, graine):
    etiq, n = ndi.label(masque)
    return etiq == etiq[graine]


# --- 1) Les AILES = ce que l'image finale a de plus que l'image sans ailes --------------------------------
diff = np.abs(F - S).sum(axis=2)
ailes = diff > 60
ailes = ndi.binary_closing(ailes, iterations=3)
ailes = ndi.binary_opening(ailes, iterations=1)
# on ne garde que les deux gros morceaux (gauche / droite), hors zone de la tête
ailes[:, 590:820] = False
cote = {}
for nom, (x0, x1) in {"g": (0, 590), "d": (820, W)}.items():
    m = ailes.copy()
    m[:, :x0] = False
    m[:, x1:] = False
    etiq, n = ndi.label(m)
    tailles = ndi.sum(m, etiq, range(1, n + 1))
    garde = np.zeros_like(m)
    for i, t in enumerate(tailles, 1):
        if t > 1500:      # les petits points de bruit JPEG sont ignorés
            garde |= etiq == i
    garde = ndi.binary_dilation(garde, iterations=2)
    garde = ndi.binary_fill_holes(garde)
    cote[nom] = garde

# --- 2) Le CHÂTEAU = pierre bleu-gris (le sol est vert), plus grande composante ------------------------
r, g, b = S[..., 0], S[..., 1], S[..., 2]
pierre = (b >= g - 2) & ~((g > r + 12) & (g > b + 6))
pierre = ndi.binary_opening(pierre, iterations=1)
pierre = ndi.binary_closing(pierre, iterations=3)
chateau = composante_principale(pierre, (400, 704))      # le donjon rond (rempart du bas)
chateau |= composante_principale(pierre, (110, 704))     # tour de tête (centre haut) si séparée
chateau = ndi.binary_fill_holes(chateau)                  # la cour intérieure (herbe) fait partie du château
# flammes, torches, braises et drapeaux (orange / rouge) ne sont pas de la pierre mais font partie du château
chaud = ((r > g + 25) & (r > b + 30)) & (np.arange(H)[:, None] < 720)
chaud = ndi.binary_opening(chaud, iterations=1)
chaud = ndi.binary_dilation(chaud, iterations=3)
etiq, n = ndi.label(chaud)
proche = ndi.binary_dilation(chateau, iterations=40)
for i in range(1, n + 1):          # on ne garde que les morceaux chauds proches du château (le chemin de terre en est exclu : il est loin et grand)
    m = etiq == i
    if m.sum() < 6000 and (m & proche).any():
        chateau |= m
bas = np.zeros_like(chateau)
bas[430:, :] = True
fermé = ndi.binary_closing(chateau, structure=np.ones((3, 3)), iterations=14)   # comble les creux entre les rampes de la queue
chateau = np.where(bas, fermé, chateau)
chateau = ndi.binary_closing(chateau, iterations=4)
chateau = ndi.binary_fill_holes(chateau)

# --- 3) Le BEC (nouveau) : sur la zone de la tête, on prend l'image FINALE (bec de face) --------------------
# l'ancien bec de profil dépasse à droite de la tour dans `sans` : on le remplace, image et masque, par ceux de l'image finale
def masque_pierre(A):
    r, g, b = A[..., 0], A[..., 1], A[..., 2]
    m = (b >= g - 2) & ~((g > r + 12) & (g > b + 6))
    return ndi.binary_closing(ndi.binary_opening(m, iterations=1), iterations=3)


Y0, Y1, X0, X1 = 10, 235, 600, 830
corps_rgb = S.copy()
corps_rgb[Y0:Y1, X0:X1] = F[Y0:Y1, X0:X1]
pierre_f = masque_pierre(F)
tete_f = np.zeros((H, W), bool)
tete_f[Y0:Y1, X0:X1] = pierre_f[Y0:Y1, X0:X1]
chateau[Y0:Y1, X0:X1] = False
chateau |= tete_f
chateau = ndi.binary_fill_holes(ndi.binary_closing(chateau, iterations=3))

# --- Enregistrement -----------------------------------------------------------------------------------------
def enregistrer(nom, rgb, alpha, recadrer=True):
    a = (alpha * 255).astype(np.uint8)
    img = np.dstack([np.clip(rgb, 0, 255).astype(np.uint8), a])
    im = Image.fromarray(img, "RGBA")
    boite = None
    if recadrer:
        boite = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        im = im.crop(boite)
    im.save(os.path.join(SORTIE, nom))
    return boite


alpha_ch = lisse(chateau)
b_corps = enregistrer("corps.png", corps_rgb, alpha_ch, recadrer=False)
b_g = enregistrer("aile_g.png", F, lisse(cote["g"]))
b_d = enregistrer("aile_d.png", F, lisse(cote["d"]))

# --- Le SOL sans château ni ailes : le trou est rempli avec de l'herbe tirée d'un coin d'herbe nu de l'image ------
trou = ndi.binary_dilation(chateau | cote["g"] | cote["d"], iterations=22)   # large : emporte aussi les ombres portées
trou[15:65, 635:790] = True   # drapeaux de la tour
# on retire aussi l'ancien bec de profil (hors du masque du château, à droite de la tour)
trou[40:200, 700:830] |= ndi.binary_dilation(~(np.abs(F - S).sum(axis=2)[40:200, 700:830] < 8), iterations=4)
rng = np.random.default_rng(3)
patch = np.asarray(sans)[110:330, 90:330].astype(np.float32)           # herbe nue
moy = patch.reshape(-1, 3).mean(axis=0)
sol = np.asarray(sans).astype(np.float32).copy()
tuile = np.concatenate([patch, patch[:, ::-1]], axis=1)
tuile = np.concatenate([tuile, tuile[::-1]], axis=0)
th, tw = tuile.shape[:2]
herbe = np.zeros((H, W, 3), np.float32)
for y in range(0, H, th):
    for x in range(0, W, tw):
        dy, dx = rng.integers(0, th), rng.integers(0, tw)
        t = np.roll(np.roll(tuile, dy, axis=0), dx, axis=1)
        h = min(th, H - y)
        w = min(tw, W - x)
        herbe[y:y + h, x:x + w] = t[:h, :w]
herbe = ndi.gaussian_filter(herbe, (0.8, 0.8, 0))
alpha = ndi.gaussian_filter(trou.astype(np.float32), 5)[..., None]
sol = sol * (1 - alpha) + herbe * alpha
Image.fromarray(np.clip(sol, 0, 255).astype(np.uint8)).save(os.path.join(SORTIE, "sol.png"))

# --- Contrôle : recomposition ------------------------------------------------------------------------------
comp = Image.open(os.path.join(SORTIE, "sol.png")).convert("RGBA")
c = Image.open(os.path.join(SORTIE, "corps.png"))
comp.alpha_composite(c)
for nom, bb in (("aile_g.png", b_g), ("aile_d.png", b_d)):
    comp.alpha_composite(Image.open(os.path.join(SORTIE, nom)), (bb[0], bb[1]))
comp.convert("RGB").save(os.path.join(SORTIE, "coq_final.png"))

meta = {
    "taille": [W, H],
    "aile_g": {"origine": [b_g[0], b_g[1]], "taille": [b_g[2] - b_g[0], b_g[3] - b_g[1]]},
    "aile_d": {"origine": [b_d[0], b_d[1]], "taille": [b_d[2] - b_d[0], b_d[3] - b_d[1]]},
    # épaules = là où l'aile se raccorde au château (milieu du bord intérieur de l'aile)
    "epaule_g": [575, 270],
    "epaule_d": [830, 270],
}
with open(os.path.join(SORTIE, "calques.json"), "w") as f:
    json.dump(meta, f, indent=1)
print(meta)
