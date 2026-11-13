"""Outil de développement : fabrique en code les petits bruitages qui manquent au pack (Assets/Sons/).
  - porte.wav : grincement de bois + claquement sourd (porte qui s'ouvre quand on entre dans un bâtiment)
  - pas_pierre.wav : un pas sur une marche de pierre, avec un peu d'écho (la descente de l'escalier du donjon)
Usage : python3 Outils/fabriquer_sons.py"""
import os, wave
import numpy as np

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Sons")
FS = 44100


def ecrire(nom, signal):
    signal = signal / max(1e-9, np.max(np.abs(signal))) * 0.8
    os.makedirs(SORTIE, exist_ok=True)
    with wave.open(os.path.join(SORTIE, nom), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((signal * 32767).astype("<i2").tobytes())


def porte():
    rng = np.random.default_rng(3)
    t = np.arange(int(FS * 0.55)) / FS
    # grincement : onde en dents de scie dont la hauteur glisse et tremble
    f = 150 + 70 * t / 0.3 + 12 * np.sin(2 * np.pi * 9 * t)
    phase = np.cumsum(2 * np.pi * f / FS)
    grince = (2 * ((phase / (2 * np.pi)) % 1.0) - 1.0) * np.clip(1 - t / 0.34, 0, 1) * np.clip(t / 0.03, 0, 1)
    bruit = rng.normal(0, 1, t.size)
    bruit = np.convolve(bruit, np.ones(24) / 24, mode="same")   # bruit adouci (frottement)
    sortie = 0.5 * grince + 0.35 * bruit * np.clip(1 - t / 0.34, 0, 1)
    # claquement sourd à la fin
    d = t - 0.36
    sortie += np.where(d > 0, np.sin(2 * np.pi * 70 * d) * np.exp(-d * 18), 0) * 1.4
    ecrire("porte.wav", sortie)


def pas_pierre():
    rng = np.random.default_rng(7)
    t = np.arange(int(FS * 0.35)) / FS
    choc = np.sin(2 * np.pi * 95 * t) * np.exp(-t * 38)                       # le « toc » sourd
    claque = np.convolve(rng.normal(0, 1, t.size), np.ones(10) / 10, mode="same") * np.exp(-t * 60)
    sortie = choc * 1.2 + claque * 0.5
    echo = np.zeros_like(sortie)
    for k, (retard, gain) in enumerate(((0.11, 0.45), (0.22, 0.22))):     # l'écho de la cage d'escalier
        n = int(FS * retard)
        echo[n:] += sortie[:-n] * gain
    ecrire("pas_pierre.wav", sortie + echo)


if __name__ == "__main__":
    porte()
    pas_pierre()
    print("ok")
