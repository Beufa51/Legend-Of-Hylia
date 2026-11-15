"""Outil de développement : fabrique les petits éléments de VIE des salles du donjon (Scripts/vie_salle.gd).
  - Assets/Gemini/tuiles/toile_g.png / toile_d.png : toiles d'araignée de coin (12x12)
  - Assets/Sons/goutte.wav : une goutte qui tombe (très douce)
Usage : python3 Outils/fabriquer_vie.py"""
import os, wave
import numpy as np
from PIL import Image, ImageDraw

RACINE = os.path.join(os.path.dirname(__file__), "..")
TUILES = os.path.join(RACINE, "Assets", "Gemini", "tuiles")
SONS = os.path.join(RACINE, "Assets", "Sons")


def toile(gauche):
    """Toile d'araignée dans un coin haut (le coin est en haut à gauche pour `gauche`, sinon en haut à droite)."""
    n = 12
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fil, fil2 = (214, 220, 236, 150), (190, 198, 218, 110)
    for fin in ((n - 1, 0), (n - 1, 5), (n - 1, n - 1), (5, n - 1), (0, n - 1)):   # fils qui partent du coin (0,0)
        d.line((0, 0) + fin, fill=fil)
    for r in (4, 7, 10):                                                           # arcs entre les fils
        d.arc((-r, -r, r, r), 0, 90, fill=fil2)
    if not gauche:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def goutte():
    fs = 44100
    t = np.arange(int(fs * 0.16)) / fs
    f = 1500 - 4200 * t                                  # "plic" : la hauteur chute vite
    phase = np.cumsum(2 * np.pi * f / fs)
    s = np.sin(phase) * np.exp(-t / 0.035) * np.clip(t / 0.002, 0, 1)
    s += 0.25 * np.sin(2 * phase) * np.exp(-t / 0.02)
    s = s / np.max(np.abs(s)) * 0.5
    os.makedirs(SONS, exist_ok=True)
    with wave.open(os.path.join(SONS, "goutte.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(fs)
        w.writeframes((s * 32767).astype("<i2").tobytes())


if __name__ == "__main__":
    toile(True).save(os.path.join(TUILES, "toile_g.png"))
    toile(False).save(os.path.join(TUILES, "toile_d.png"))
    goutte()
    print("toiles et goutte fabriquées")
