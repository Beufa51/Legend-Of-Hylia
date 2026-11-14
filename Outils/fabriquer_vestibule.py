#!/usr/bin/env python3
"""VESTIBULE DU DONJON FINAL (la QUEUE du coq vue de l'intérieur) : un ÉVENTAIL de 5 couloirs de pierre SÉPARÉS (pincé en haut, large en bas, porte au centre du bas),
comme sur l'image Coq_forteresse.jpg. La forme est trop diagonale pour des tuiles : on PEINT le fond de la salle (400x224) avec des polygones,
dans le style du donjon (briques, liserés, faces de mur vues de 3/4), et on en tire le plan de collisions (cases 16 px).
Sorties : Assets/Gemini/tuiles/fond_vestibule.png ; la fonction plan() renvoie les 14 rangées du `layout` (utilisée par generer_corps.py).
Lancer APRÈS traiter_pack_donjon.py (tuiles mur_fond, mur_face_bas, sol_plat) et fabriquer_murs_donjon.py."""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

RACINE = os.path.join(os.path.dirname(__file__), "..")
TUILES = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
W, H = 400, 224
HAUT, BAS = 32, 176                         # les couloirs vont de y=32 (arches du donjon rond) à y=176 (tours à flammes + porte)
# Comme sur l'image : l'éventail est PINCÉ en HAUT (côté donjon) et s'ÉLARGIT vers le BAS ; les 5 couloirs restent SÉPARÉS par des murs sur toute leur longueur.
# (x au centre en haut, x au centre en bas, demi-largeur en haut, demi-largeur en bas)
COULOIRS = [(114, 52, 11, 14), (156, 109, 11, 14), (200, 200, 20, 28), (244, 291, 11, 14), (286, 348, 11, 14)]


def tuile(nom):
    return Image.open(os.path.join(TUILES, nom + ".png")).convert("RGBA")


def paver(nom_tuiles, taille=(W, H)):
    """Remplit une image en répétant une ou plusieurs tuiles 16x16 (variantes choisies de façon fixe)."""
    ims = [tuile(n) for n in nom_tuiles]
    out = Image.new("RGBA", taille)
    for y in range(0, taille[1], 16):
        for x in range(0, taille[0], 16):
            out.paste(ims[((x // 16) * 7 + (y // 16) * 13) % len(ims)], (x, y))
    return out


def masque_sol():
    """5 couloirs séparés (le central relie la porte du bas à la sortie du haut ; les 4 autres finissent contre une tour à flamme en bas)."""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    for (ah, ab, wh, wb) in COULOIRS:
        d.polygon([(ah - wh, HAUT), (ah + wh, HAUT), (ab + wb, BAS), (ab - wb, BAS)], fill=255)
    d.rectangle([176, 0, 223, HAUT + 4], fill=255)                              # sortie du haut (vers le couloir du corps)
    d.rectangle([176, BAS - 2, 223, H], fill=255)                               # porte d'entrée (en bas)
    return m


def plan(masque=None):
    """Les 14 rangées de 25 caractères : '#' mur, '.' sol (une case est du sol si la moitié au moins de sa surface l'est)."""
    f = np.asarray(masque if masque is not None else masque_sol()) > 127
    rangees = []
    for cy in range(14):
        ligne = ""
        for cx in range(25):
            ligne += "." if f[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16].mean() >= 0.5 else "#"
        rangees.append(ligne)
    return rangees


def masque_couloir():
    """Le COULOIR (passage dans l'épaisseur du donjon rond) : un couloir droit de 3 cases + 2 alcôves de garde de chaque côté."""
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    d.rectangle([176, 0, 223, H], fill=255)
    d.rectangle([128, 80, 175, 143], fill=255)        # alcôve gauche
    d.rectangle([224, 80, 271, 143], fill=255)        # alcôve droite
    return m


def fabriquer(masque=None, fichier="fond_vestibule", lumieres=((52, 168), (109, 168), (291, 168), (348, 168), (114, 40), (156, 40), (244, 40), (286, 40)), nervures=()):
    """Peint le fond. `lumieres` : centres des flammes (lueur chaude sur le sol et les murs) ; `nervures` : y des arcs de la voûte (bandes d'ombre en travers)."""
    sol_m = masque if masque is not None else masque_sol()
    f = np.asarray(sol_m) > 127
    fond = paver(["mur_fond"])                                        # les murs vus de dessus : briques sombres
    sol = paver(["sol_plat", "sol_plat", "sol_plat", "sol_plat_b", "sol_plat_c", "sol_plat", "sol_plat_d"])
    # FACE des murs (vue de 3/4) : les pixels de mur qui ont du sol juste en dessous (jusqu'à 11 px) montrent leurs briques de face
    face_m = np.zeros((H, W), bool)
    for d in range(1, 12):
        dec = np.zeros_like(f)
        dec[:-d, :] = f[d:, :]
        face_m |= dec & ~f
    face_tex = paver(["mur_face_bas", "mur_face_bas"])
    # LISERÉ (couvertine claire) : mur proche du sol sur les côtés ou au-dessous (vu de dessus)
    proche = np.asarray(sol_m.filter(ImageFilter.MaxFilter(7))) > 127
    rim_m = proche & ~f & ~face_m
    img = fond.copy()
    img.paste(sol, (0, 0), sol_m)
    arr = np.asarray(img).copy()
    ft = np.asarray(face_tex)
    arr[face_m] = ft[face_m]
    rim = np.asarray(sol_m.filter(ImageFilter.MaxFilter(5))) > 127
    arr[rim_m & rim] = (138, 152, 184, 255)                           # liseré clair le long du sol
    arr[rim_m & ~rim] = (92, 102, 132, 255)                           # et son ombre
    # ombre portée sur le sol, sous les faces de mur
    for d in range(1, 7):
        sh = np.zeros_like(f)
        sh[d:, :] = face_m[:-d, :]
        sel = sh & f
        arr[sel, :3] = (arr[sel, :3] * (1.0 - 0.07 * (7 - d) / 6.0 * 3)).astype(np.uint8)
    # arcs de la voûte : une bande d'ombre en travers du sol, avec un filet clair au-dessus
    for y in nervures:
        for dy in range(8):
            sel = f.copy()
            sel[:, :] = False
            if 0 <= y + dy < H:
                sel[y + dy, :] = f[y + dy, :]
                arr[sel, :3] = (arr[sel, :3] * (0.78 + 0.02 * dy)).astype(np.uint8)
        if 0 <= y - 1 < H:
            sel = np.zeros_like(f)
            sel[y - 1, :] = f[y - 1, :]
            arr[sel, :3] = np.minimum(255, arr[sel, :3].astype(int) + 26).astype(np.uint8)
    # LUEUR chaude des flammes sur le sol et les murs
    yy, xx = np.mgrid[0:H, 0:W]
    lum = np.zeros((H, W), float)
    for (lx, ly) in lumieres:
        d = np.sqrt((xx - lx) ** 2 + ((yy - ly) * 1.15) ** 2)
        lum += np.clip(1.0 - d / 78.0, 0, 1) ** 2
    lum = np.clip(lum, 0, 1.2)[..., None]
    arr[..., :3] = np.minimum(255, arr[..., :3] + lum * np.array([150, 82, 28]) * 0.55).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(os.path.join(TUILES, fichier + ".png"))


if __name__ == "__main__":
    fabriquer()
    fabriquer(masque_couloir(), "fond_couloir", lumieres=((136, 88), (264, 88)), nervures=(40, 104, 168))
    print("fond_vestibule.png et fond_couloir.png écrits")
    print("\n".join(plan()))
