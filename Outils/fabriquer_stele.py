"""Outil de développement : fabrique la STÈLE DU COQ du parvis (lettre Y = vide, y = avec les deux ailes).
Usage : python3 Outils/fabriquer_stele.py [apercu.png]
Images : Assets/Gemini/tuiles/v_stele_vide.png et v_stele_pleine.png (36x48 : emprise 2x2 en bas, la stèle dépasse vers le haut).
Le coq gravé vient du grand blason (Assets/Gemini/embleme/blason_*.png) : même dessin que la vue aérienne."""
import os
import sys
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
EMBLEME = os.path.join(RACINE, "Assets", "Gemini", "embleme")
SORTIE = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
L, H = 36, 48

PIERRE = (138, 140, 150, 255)
PIERRE_CLAIRE = (172, 176, 186, 255)
PIERRE_SOMBRE = (88, 90, 104, 255)
CONTOUR = (40, 40, 52, 255)


def dalle():
    """La pierre : socle large en bas, dalle au sommet arrondi, éclairée à gauche."""
    im = Image.new("RGBA", (L, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2, 40, 33, 47], fill=(0, 0, 0, 70))                              # ombre au sol
    d.rectangle([3, 36, 32, 43], fill=PIERRE_SOMBRE, outline=CONTOUR)            # socle
    d.line([(4, 37), (31, 37)], fill=PIERRE)
    d.rounded_rectangle([6, 2, 29, 38], radius=10, fill=PIERRE, outline=CONTOUR) # la dalle
    d.line([(8, 12), (8, 35)], fill=PIERRE_CLAIRE)                               # arête éclairée
    d.line([(27, 12), (27, 35)], fill=PIERRE_SOMBRE)                             # côté dans l'ombre
    d.rectangle([9, 31, 26, 33], fill=PIERRE_SOMBRE)                             # inscription (trait)
    return im


def graver(im, pieces):
    """Grave le coq (et les ailes données) au centre de la dalle : réduit à 20 px de large."""
    blason = Image.new("RGBA", (244, 132), (0, 0, 0, 0))
    for nom in pieces:
        blason.alpha_composite(Image.open(os.path.join(EMBLEME, nom + ".png")).convert("RGBA"))
    petit = blason.resize((22, 12), Image.LANCZOS)
    im.alpha_composite(petit, (7, 15))
    return im


def main():
    vide = graver(dalle(), ["blason_socle"])
    pleine = graver(dalle(), ["blason_socle", "blason_aile_gauche", "blason_aile_droite"])
    # la stèle « pleine » luit doucement (petits éclats dorés)
    d = ImageDraw.Draw(pleine)
    for (x, y) in [(10, 8), (25, 9), (17, 5)]:
        d.point((x, y), fill=(255, 220, 120, 255))
    vide.save(os.path.join(SORTIE, "v_stele_vide.png"))
    pleine.save(os.path.join(SORTIE, "v_stele_pleine.png"))
    print("écrit : v_stele_vide.png, v_stele_pleine.png")
    if len(sys.argv) > 1:
        apercu = Image.new("RGBA", (L * 2 + 8, H), (120, 170, 90, 255))
        apercu.alpha_composite(vide, (0, 0))
        apercu.alpha_composite(pleine, (L + 8, 0))
        apercu.resize((apercu.width * 6, apercu.height * 6), Image.NEAREST).save(sys.argv[1])


main()
