"""Outil de développement (APRÈS traiter_gemini.py) : fabrique les FLAQUES d'eau de la salle « lance enflammée » (Plume 2a).
  flaque_1.png / flaque_2.png : flaque bleue peu profonde, 2 images (les rides bougent). 16x16, posée sur le sol."""
import os
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")


def flaque(n):
    t = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(t)
    d.rounded_rectangle((0, 1, 15, 14), radius=5, fill=(20, 36, 70, 255))        # bord sombre
    d.rounded_rectangle((1, 2, 14, 13), radius=4, fill=(40, 90, 160, 255))       # eau
    d.rounded_rectangle((2, 3, 13, 12), radius=3, fill=(58, 120, 196, 255))      # eau claire
    r = 1 if n == 1 else 2
    cx, cy = 8, 8
    d.arc((cx - 2 - r, cy - 1 - r, cx + 2 + r, cy + 1 + r), 0, 360, fill=(170, 220, 250, 255))   # ride
    d.point((4, 5), fill=(220, 245, 255, 255)); d.point((11, 10), fill=(220, 245, 255, 255))   # reflets
    return t


if __name__ == "__main__":
    flaque(1).save(os.path.join(SORTIE, "flaque_1.png"))
    flaque(2).save(os.path.join(SORTIE, "flaque_2.png"))
    print("flaques fabriquées")
