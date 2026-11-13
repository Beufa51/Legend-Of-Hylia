"""Outil de développement (APRÈS traiter_gemini.py) : fabrique le BLOC de pierre et les MARQUES au sol des énigmes de blocs.
  bloc_pierre.png / bloc_pierre_actif.png : cube de pierre bleu-gris (mêmes tons que murs, piliers et plots), rune creusée ;
                                            « actif » = rune dorée qui brille (le bloc est bien posé sur une marque).
  marque.png / marque_active.png          : emplacement gravé au sol (cadre + coins + losange doré) ; « active » = le losange brille.
Règle d'énigme (sans texte) : une marque dorée au sol = « il y a quelque chose à poser ici »."""
import os
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR = (20, 24, 38, 255)
CLAIR = (132, 150, 182, 255)
MOYEN = (92, 108, 138, 255)
SOMBRE = (60, 72, 100, 255)
TRES_SOMBRE = (42, 50, 74, 255)
OR = (240, 190, 70, 255)
OR_CLAIR = (255, 232, 140, 255)
OR_SOMBRE = (150, 110, 40, 255)


def bloc(actif):
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    d.rectangle((0, 0, 15, 15), fill=CONTOUR)
    d.rectangle((1, 1, 14, 11), fill=MOYEN)             # dessus
    d.rectangle((1, 12, 14, 14), fill=SOMBRE)           # face avant
    d.rectangle((1, 14, 14, 14), fill=TRES_SOMBRE)
    d.line((1, 1, 14, 1), fill=CLAIR)                   # lumière en haut et à gauche
    d.line((1, 1, 1, 11), fill=CLAIR)
    d.line((14, 2, 14, 11), fill=SOMBRE)                # ombre à droite
    d.line((1, 12, 14, 12), fill=MOYEN)                 # arête entre dessus et face avant
    d.rectangle((4, 4, 11, 9), fill=SOMBRE)             # creux du dessus
    d.rectangle((4, 4, 11, 4), fill=TRES_SOMBRE)
    d.rectangle((4, 9, 11, 9), fill=CLAIR)
    # rune : un losange
    c = OR if actif else TRES_SOMBRE
    d.polygon([(7, 5), (10, 6), (7, 8), (5, 6)], fill=c) if False else None
    d.rectangle((7, 5, 8, 8), fill=c)
    d.rectangle((6, 6, 9, 7), fill=c)
    if actif:
        d.point((7, 6), fill=OR_CLAIR); d.point((8, 6), fill=OR_CLAIR)
        for p in ((6, 5), (9, 5), (6, 8), (9, 8)):
            d.point(p, fill=OR_SOMBRE)
    return t


def marque(active):
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    gris = (28, 34, 52, 200)                            # sillon creusé dans la dalle
    d.rectangle((1, 1, 14, 14), outline=gris)
    d.rectangle((2, 2, 13, 13), outline=(150, 166, 196, 90))   # bord éclairé du sillon
    col = OR if active else OR_SOMBRE
    for x, y in ((1, 1), (14, 1), (1, 14), (14, 14)):   # coins dorés
        d.point((x, y), fill=col)
        d.point((x + (1 if x == 1 else -1), y), fill=col)
        d.point((x, y + (1 if y == 1 else -1)), fill=col)
    # losange central
    for r, c in ((3, col), (2, col), (1, OR_CLAIR if active else OR)):
        d.polygon([(7.5, 7.5 - r), (7.5 + r, 7.5), (7.5, 7.5 + r), (7.5 - r, 7.5)], fill=c)
    d.rectangle((7, 7, 8, 8), fill=OR_CLAIR if active else OR)
    return t


if __name__ == "__main__":
    bloc(False).save(os.path.join(SORTIE, "bloc_pierre.png"))
    bloc(True).save(os.path.join(SORTIE, "bloc_pierre_actif.png"))
    marque(False).save(os.path.join(SORTIE, "marque.png"))
    marque(True).save(os.path.join(SORTIE, "marque_active.png"))
    print("blocs et marques fabriqués")
