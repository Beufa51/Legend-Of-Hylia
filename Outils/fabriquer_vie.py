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
    """Un « ploc » d'eau GRAVE et mat (et pas un « plic » aigu : à 1 500 Hz, 0,16 s, on aurait dit un piaillement d'oiseau).
    Bulle qui monte de 330 à 560 Hz, très amortie, petit clic d'impact adouci, puis 3 échos de pierre."""
    fs = 44100
    t = np.arange(int(fs * 0.6)) / fs
    f = 330 + 230 * (1 - np.exp(-t / 0.025))            # une goutte qui tombe dans l'eau monte un peu en hauteur
    phase = np.cumsum(2 * np.pi * f / fs)
    bulle = np.sin(phase) * np.exp(-t / 0.045) * np.clip(t / 0.003, 0, 1)
    rng = np.random.default_rng(7)
    clic = rng.normal(0, 1, len(t)) * np.exp(-t / 0.002) * 0.35
    s = bulle + clic
    noyau = np.ones(9) / 9.0                                # filtre passe-bas simple : plus de piqué aigu
    s = np.convolve(s, noyau, mode="same")
    for retard, gain in ((0.09, 0.35), (0.19, 0.18), (0.31, 0.08)):   # écho de la salle de pierre
        k = int(fs * retard)
        s[k:] += s[:-k] * gain
    s *= np.clip((0.6 - t) / 0.1, 0, 1)                     # fin propre
    s = s / np.max(np.abs(s)) * 0.4
    os.makedirs(SONS, exist_ok=True)
    with wave.open(os.path.join(SONS, "goutte.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(fs)
        w.writeframes((s * 32767).astype("<i2").tobytes())


if __name__ == "__main__":
    toile(True).save(os.path.join(TUILES, "toile_g.png"))
    toile(False).save(os.path.join(TUILES, "toile_d.png"))
    goutte()
    print("toiles et goutte fabriquées")
