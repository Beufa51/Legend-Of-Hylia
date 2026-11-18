"""Découpe la planche Gemini `sablier.jpg` (5 sabliers de pierre et d'or sur fond magenta)
-> Assets/Gemini/tuiles/sablier_1..5.png (16x36 : le socle est sur la case, le haut dépasse de 20 px vers le haut).
  1 = repos (sable en haut)   2 = le sable coule (moitié)   3 = frappé (éclair violet)
  4 = REMBOBINE (le sable remonte, étincelles)   5 = éteint (la salle est réussie, le sablier dort)
Toutes les pièces sont coupées dans une boîte de MÊME taille, centrée sur le socle : elles ne « sautent » pas d'une image à l'autre.
Usage : python3 Outils/traiter_sablier.py"""
import numpy as np
from PIL import Image, ImageEnhance

SRC = "Assets/Gemini/originaux/sablier.jpg"
SORTIE = "Assets/Gemini/tuiles/sablier_%d.png"
LARGEUR, HAUTEUR = 16, 36      # image finale
CORPS = 14                     # largeur du sablier dans l'image finale (px)

img = Image.open(SRC).convert("RGB")
a = np.array(img).astype(int)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
magenta = (r > 170) & (b > 170) & (g < 50)     # le sable violet (g ~ 70-90) n'est PAS du magenta
# fond = le magenta relié aux bords de l'image ; le magenta ENFERMÉ dans le verre devient du verre sombre teinté
from scipy import ndimage
lab, _ = ndimage.label(magenta)
bords = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
fond = np.isin(lab, list(bords))
enferme = magenta & ~fond
a[enferme] = (78, 66, 104)
img = Image.fromarray(a.astype(np.uint8))
W = a.shape[1]
# largeur de référence = celle du 1er sablier (sans éclat)
ys, xs = np.where(~fond[:, : W // 5])
larg_ref = xs.max() - xs.min() + 1
haut, bas = ys.min(), ys.max() + 1
echelle = CORPS / larg_ref
for i in range(5):
    x0, x1 = int(i * W / 5), int((i + 1) * W / 5)
    # centre = centre du SOCLE (les 40 dernières lignes) : l'éclair de l'image 3 ne décale pas la découpe
    ys_b, xs_b = np.where(~fond[bas - 40: bas, x0:x1])
    cx = x0 + (xs_b.min() + xs_b.max()) / 2.0
    largeur_src = LARGEUR / echelle
    boite = (int(round(cx - largeur_src / 2)), haut, int(round(cx + largeur_src / 2)), bas)
    piece = img.crop(boite).convert("RGBA")
    alpha = Image.fromarray(np.where(fond[boite[1]:boite[3], boite[0]:boite[2]], 0, 255).astype(np.uint8))
    piece.putalpha(alpha)
    piece = piece.resize((LARGEUR, HAUTEUR), Image.LANCZOS)
    rgb = ImageEnhance.Contrast(piece.convert("RGB")).enhance(1.15)
    p = np.array(rgb.convert("RGBA"))
    p[..., 3] = np.where(np.array(piece)[..., 3] > 110, 255, 0)
    Image.fromarray(p).save(SORTIE % (i + 1))
print("écrit : sablier_1..5.png (%dx%d)" % (LARGEUR, HAUTEUR))

# --- Sons du sablier (Assets/Sons/) : tic.wav (tic-tac de bois) et rembobine.wav (un souffle JOUÉ À L'ENVERS + un glissando qui monte) ---
import wave

TAUX = 44100

def lire(chemin):
    w = wave.open(chemin)
    n, c = w.getnframes(), w.getnchannels()
    d = np.frombuffer(w.readframes(n), dtype=np.int16).astype(float) / 32768.0
    return d.reshape(-1, c).mean(axis=1) if c > 1 else d

def ecrire(chemin, son):
    son = np.clip(son / max(1e-6, np.abs(son).max()) * 0.85, -1, 1)
    w = wave.open(chemin, "w"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(TAUX)
    w.writeframes((son * 32767).astype(np.int16).tobytes()); w.close()

t = np.arange(int(TAUX * 0.07)) / TAUX
tic = np.sin(2 * np.pi * 1850 * t) * np.exp(-t * 90) + 0.5 * np.sin(2 * np.pi * 620 * t) * np.exp(-t * 60)
tic += np.random.default_rng(3).normal(0, 0.25, t.size) * np.exp(-t * 200)
ecrire("Assets/Sons/tic.wav", tic)

souffle = lire("Assets/Ninja_adventure/Audio/Sounds/Whoosh & Slash/Whoosh.wav")[::-1]       # à l'envers
esprit = lire("Assets/Ninja_adventure/Audio/Sounds/Magic & Skill/Spirit.wav")[::-1]
n = int(TAUX * 1.0)
mix = np.zeros(n)
mix[-min(n, souffle.size):] += souffle[-n:] * 0.9
mix[:min(n, esprit.size)] += esprit[:n] * 0.6
t = np.arange(n) / TAUX
freq = 300 * (2 ** (t * 2.2))                       # glissando qui monte (le sable remonte)
phase = 2 * np.pi * np.cumsum(freq) / TAUX
mix += 0.25 * np.sin(phase) * np.minimum(1, t * 6) * np.exp(-((t - 0.85) ** 2) * 18)
mix *= np.minimum(1, (1.0 - t) * 12)                 # coupe nette à la fin
ecrire("Assets/Sons/rembobine.wav", mix)
print("écrit : Assets/Sons/tic.wav, Assets/Sons/rembobine.wav")
