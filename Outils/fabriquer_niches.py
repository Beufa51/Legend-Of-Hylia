"""Outil de développement : (1) remplace `mur_fond` (le vide noir derrière les murs) par des BRIQUES assombries : les murs épais des salles de donjon paraissent maçonnés ; (2) fabrique `niche_grille.png` (32x21) = une niche voûtée à barreaux dans le mur du haut des salles de donjon
(l'arche à herse du pack Craftpix, réduite aux 2/3). À lancer APRÈS traiter_pack_donjon.py. Utilisée par room.gd::_poser_details (COLONNES_NICHES)."""
import os
from PIL import Image

T = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
arche = Image.open(os.path.join(T, "arche_herse_1.png")).convert("RGBA")
niche = arche.resize((32, 21), Image.LANCZOS)
niche.save(os.path.join(T, "niche_grille.png"))
print("niche_grille écrite", niche.size)

from PIL import ImageEnhance
fond = ImageEnhance.Brightness(Image.open(os.path.join(T, "mur_face_haut.png")).convert("RGB")).enhance(0.55)
fond.save(os.path.join(T, "mur_fond.png"))
print("mur_fond : briques assombries")


# MEURTRIÈRE 8x14 (remplace les niches à barreaux, trop grandes : on les prenait pour des portes) : fente étroite dans un encadrement de pierre
from PIL import ImageDraw
m = Image.new("RGBA", (8, 14), (0, 0, 0, 0))
d = ImageDraw.Draw(m)
d.rectangle((0, 0, 7, 13), fill=(28, 30, 42, 255))        # contour sombre
d.rectangle((1, 1, 6, 12), fill=(112, 120, 142, 255))     # pierre éclairée
d.rectangle((5, 1, 6, 12), fill=(78, 84, 106, 255))       # côté ombré
d.rectangle((3, 2, 4, 11), fill=(8, 10, 18, 255))         # la fente
d.point((3, 2), fill=(70, 96, 150, 255)); d.point((3, 3), fill=(40, 56, 96, 255))   # un peu de jour tout en haut
d.rectangle((2, 5, 5, 6), fill=(8, 10, 18, 255))          # petite croisée
m.save(os.path.join(T, "meurtriere.png"))
print("meurtriere écrite")
