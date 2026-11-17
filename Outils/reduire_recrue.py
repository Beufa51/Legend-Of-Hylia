"""Réduit les planches de la recrue (cases 40x48) à 75 % AVEC un vrai filtre (cases 30x36).
Dans Godot, un sprite à l'échelle 0,75 en filtre « nearest » perd des pixels (le personnage paraît
transparent et scintille en marchant). Ici on réduit une fois pour toutes, alpha net (0 ou 255).
Écrit Assets/Heros/recrue_<Idle|Walk|Slash>_p.png."""
import numpy as np
from PIL import Image

CASE = (40, 48)
NOUVELLE = (30, 36)

def reduire_case(case):
    a = np.array(case.convert("RGBA")).astype(float)
    alpha = a[..., 3:4] / 255.0
    pre = Image.fromarray(np.concatenate([a[..., :3] * alpha, a[..., 3:4]], axis=2).astype("uint8"), "RGBA")
    pre = pre.resize(NOUVELLE, Image.LANCZOS)
    p = np.array(pre).astype(float)
    al = p[..., 3:4] / 255.0
    rgb = np.where(al > 0.01, p[..., :3] / np.maximum(al, 0.01), 0).clip(0, 255)
    net = np.where(al >= 0.4, 255, 0)          # contour net : plus de pixels « fantômes »
    return Image.fromarray(np.concatenate([rgb, net], axis=2).astype("uint8"), "RGBA")

for nom in ("Idle", "Walk", "Slash"):
    src = Image.open(f"Assets/Heros/recrue_{nom}.png").convert("RGBA")
    colonnes, lignes = src.width // CASE[0], src.height // CASE[1]
    sortie = Image.new("RGBA", (colonnes * NOUVELLE[0], lignes * NOUVELLE[1]))
    for y in range(lignes):
        for x in range(colonnes):
            case = src.crop((x * CASE[0], y * CASE[1], (x + 1) * CASE[0], (y + 1) * CASE[1]))
            sortie.paste(reduire_case(case), (x * NOUVELLE[0], y * NOUVELLE[1]))
    sortie.save(f"Assets/Heros/recrue_{nom}_p.png")
    print(nom, src.size, "->", sortie.size)
