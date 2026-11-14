#!/usr/bin/env python3
"""VESTIBULE DU DONJON FINAL (la QUEUE du coq vue de l'intérieur) : un ÉVENTAIL de 5 couloirs de pierre qui convergent vers la porte d'entrée,
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
FOYER = (200.0, 208.0)                      # point où se rejoignent les couloirs (sous la porte d'entrée)
HAUT, BAS = 32, 176                         # l'éventail va de y=32 (bout des couloirs) à y=176 (porte)
# cloisons entre les couloirs : (intervalle en haut, profondeur de la pointe : 0 = en haut, 1 = au foyer)
CLOISONS = [((80, 96), 0.62), ((144, 176), 0.72), ((224, 256), 0.72), ((304, 320), 0.62)]


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
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    d.polygon([(32, HAUT), (368, HAUT), (224, BAS), (176, BAS)], fill=255)     # l'éventail (bords extérieurs à 45°)
    d.rectangle([176, 0, 223, HAUT + 4], fill=255)                              # sortie du haut (vers le couloir du corps)
    d.rectangle([176, BAS - 2, 223, H], fill=255)                               # porte d'entrée (en bas)
    for (x0, x1), t in CLOISONS:                                                # les cloisons : triangles dont la pointe vise le foyer
        cx = (x0 + x1) / 2.0
        ax, ay = cx + t * (FOYER[0] - cx), HAUT + t * (FOYER[1] - HAUT)
        d.polygon([(x0, HAUT - 1), (x1, HAUT - 1), (ax, ay)], fill=0)
    return m


def plan():
    """Les 14 rangées de 25 caractères : '#' mur, '.' sol (une case est du sol si la moitié au moins de sa surface l'est)."""
    f = np.asarray(masque_sol()) > 127
    rangees = []
    for cy in range(14):
        ligne = ""
        for cx in range(25):
            ligne += "." if f[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16].mean() >= 0.5 else "#"
        rangees.append(ligne)
    return rangees


def fabriquer():
    sol_m = masque_sol()
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
    # relief des cloisons : léger éclairage depuis le haut-gauche
    Image.fromarray(arr, "RGBA").save(os.path.join(TUILES, "fond_vestibule.png"))


if __name__ == "__main__":
    fabriquer()
    print("fond_vestibule.png écrit")
    print("\n".join(plan()))
