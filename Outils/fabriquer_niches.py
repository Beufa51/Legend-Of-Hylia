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
