"""Outil de développement : fabrique en code les petits bruitages qui manquent au pack (Assets/Sons/).
  - porte.wav : grincement de bois + claquement sourd (porte qui s'ouvre quand on entre dans un bâtiment)
  - pas_pierre.wav : un pas sur une marche de pierre, avec un peu d'écho (la descente de l'escalier du donjon)
  - pas_herbe.wav / pas_terre.wav / pas_bois.wav / pas_dalle.wav : les PAS du héros selon le sol (Player::_bruit_de_pas) : froissement d'herbe, terre sourde, planche, dalle de donjon
  - ambiance_donjon.wav : 16 s en boucle (grondement grave, souffle, quelques gouttes lointaines) pour les ailes du donjon
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


def _bruit(rng, n, adouci):
    b = rng.normal(0, 1, n)
    return np.convolve(b, np.ones(adouci) / adouci, mode="same") if adouci > 1 else b


def pas_herbe():
    rng = np.random.default_rng(11)
    t = np.arange(int(FS * 0.16)) / FS
    froisse = _bruit(rng, t.size, 6) - _bruit(rng, t.size, 40) * 1.2     # bruit passe-haut doux
    ecrire("pas_herbe.wav", froisse * np.sin(np.pi * np.clip(t / 0.16, 0, 1)) ** 1.5 * 0.9)


def pas_terre():
    rng = np.random.default_rng(12)
    t = np.arange(int(FS * 0.14)) / FS
    choc = np.sin(2 * np.pi * 120 * t) * np.exp(-t * 55)
    grain = _bruit(rng, t.size, 14) * np.exp(-t * 40)
    ecrire("pas_terre.wav", choc * 1.0 + grain * 0.8)


def pas_bois():
    rng = np.random.default_rng(13)
    t = np.arange(int(FS * 0.2)) / FS
    toc = np.sin(2 * np.pi * 210 * t) * np.exp(-t * 45) + 0.5 * np.sin(2 * np.pi * 330 * t) * np.exp(-t * 60)
    claque = _bruit(rng, t.size, 5) * np.exp(-t * 90)
    ecrire("pas_bois.wav", toc + claque * 0.4)


def pas_dalle():
    rng = np.random.default_rng(14)
    t = np.arange(int(FS * 0.22)) / FS
    tic = np.sin(2 * np.pi * 150 * t) * np.exp(-t * 50) + _bruit(rng, t.size, 4) * np.exp(-t * 110) * 0.6
    sortie = tic.copy()
    n = int(FS * 0.07)
    sortie[n:] += tic[:-n] * 0.28                                         # un soupçon d'écho de salle
    ecrire("pas_dalle.wav", sortie)


def ambiance_donjon():
    """16 s qui bouclent sans raccord : tout est périodique (fréquences entières sur 16 s) ; les gouttes restent loin des bords."""
    rng = np.random.default_rng(21)
    duree = 16.0
    n = int(FS * duree)
    t = np.arange(n) / FS
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * t / 8.0)
    grondement = (np.sin(2 * np.pi * 55 * t) + 0.6 * np.sin(2 * np.pi * 82.5 * t + 1.0) + 0.35 * np.sin(2 * np.pi * 110.0625 * t)) * lfo
    souffle = _bruit(rng, n, 90) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 16.0 + 2.0))
    sortie = grondement * 0.55 + souffle * 5.0
    for debut in (3.1, 7.8, 12.4):                                       # trois gouttes qui tombent dans une salle de pierre
        d = t - debut
        goutte = np.where(d > 0, np.sin(2 * np.pi * (900 + 200 * np.exp(-d * 30)) * d) * np.exp(-d * 45), 0)
        for retard, gain in ((0.18, 0.4), (0.37, 0.2), (0.61, 0.1)):
            k = int(FS * retard)
            goutte[k:] += goutte[:-k] * gain
        sortie += goutte * 0.5
    ecrire("ambiance_donjon.wav", sortie)


if __name__ == "__main__":
    porte()
    pas_pierre()
    pas_herbe(); pas_terre(); pas_bois(); pas_dalle()
    ambiance_donjon()
    print("ok")
