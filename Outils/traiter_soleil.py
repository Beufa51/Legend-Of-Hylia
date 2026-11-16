"""Soleil du mur (source du rayon) : découpe la planche Gemini `originaux/soleil.jpg`
(éteint terni / allumé brillant) et écrit `source_soleil.png` (allumé) + `source_soleil_eteint.png` (16x16).
À lancer APRÈS traiter_lot_donjon.py (qui écrit l'ancien soleil)."""
from PIL import Image
D = "Assets/Gemini/"
im = Image.open(D + "originaux/soleil.jpg").convert("RGB")
# intérieur des deux panneaux (sans le cadre noir ni le magenta)
BOITES = {"source_soleil_eteint": (60, 60, 648, 706), "source_soleil": (764, 60, 1352, 706)}
for nom, b in BOITES.items():
    p = im.crop(b).resize((16, 16), Image.LANCZOS)
    p = p.quantize(24, method=Image.MEDIANCUT).convert("RGB")
    p.convert("RGBA").save(D + "tuiles/%s.png" % nom)
    print(nom)
