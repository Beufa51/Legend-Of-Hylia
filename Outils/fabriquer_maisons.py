"""Outil de développement : DESSINE EN CODE les maisons du village (vues d'en haut, toit à pans) -> Assets/Gemini/tuiles/v_maison_*.png
Dessin ORIGINAL (aucun sprite d'un autre jeu). Chaque maison : toit à 4 pans (panneau plat au centre, pans inclinés), bande de mur en pierre
avec 2 fenêtres et une porte cintrée centrée sous un petit auvent, 3 dalles devant la porte, ombre à droite, petit coq doré sur le toit.
Taille : 80x64 (5x4 cases, porte en colonne 2) ; la caserne : 112x64 (7x4 cases, porte en colonne 3).
Usage : python3 Outils/fabriquer_maisons.py [contact.png]   (à lancer APRÈS traiter_village2.py)"""
import os, sys
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
CONTOUR = (40, 24, 32)

def mix(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# --- styles de toit : couleur du panneau, des pans clairs (haut, gauche) et sombres (droite, bas), motif
TOITS = {
    "losanges": dict(panneau=(214, 62, 52), clair=(236, 96, 72), sombre=(170, 40, 48), trait=(150, 30, 40)),
    "briques":  dict(panneau=(92, 148, 214), clair=(120, 176, 232), sombre=(70, 116, 184), trait=(56, 96, 160)),
    "chaume":   dict(panneau=(214, 140, 72), clair=(236, 172, 96), sombre=(176, 104, 56), trait=(150, 84, 44)),
    "ardoise":  dict(panneau=(84, 140, 156), clair=(112, 168, 184), sombre=(60, 104, 124), trait=(44, 84, 104)),
    "ecailles": dict(panneau=(96, 176, 80), clair=(130, 204, 100), sombre=(68, 140, 68), trait=(48, 112, 56)),
    "bois":     dict(panneau=(184, 120, 68), clair=(212, 152, 92), sombre=(144, 88, 52), trait=(116, 68, 40)),
}

def pixel_toit(x, y, st, motif, bande, dx, dy):
    """Couleur d'un pixel de toit. bande : 'panneau' ou 'haut|gauche|droite|bas'. dx, dy = position dans la zone (pour les motifs)."""
    cle = {"panneau": "panneau", "haut": "clair", "gauche": "clair", "droite": "sombre", "bas": "sombre"}[bande]
    c = st[cle]
    trait = st["trait"]
    if bande == "panneau":
        if motif == "losanges":
            if (dx + dy) % 8 == 0 or (dx - dy) % 8 == 0: c = trait
        elif motif == "briques":
            ligne = dy % 5
            if ligne == 0 or (dx + (dy // 5) * 4) % 8 == 0: c = trait
        elif motif == "chaume":
            if dx % 4 == 0 and (dy // 3) % 2 == 0: c = trait
        elif motif == "ardoise":
            if dy % 4 == 0 or (dx + (dy // 4) * 3) % 7 == 0: c = trait
        elif motif == "ecailles":
            r = (dy % 6)
            if r == 5 or (r < 3 and abs((dx + (dy // 6) * 3) % 6 - 3) == r): c = trait
        elif motif == "bois":
            if dx % 5 == 0: c = trait
    else:
        # pans : rangées de tuiles parallèles au bord
        if bande in ("haut", "bas"):
            if dy % 4 == 0: c = trait
        else:
            if dx % 4 == 0: c = trait
    return c

def maison(W, nom, toit, motif, cheminee=False, coq=True, porte=(176, 112, 60)):
    st = TOITS[toit]
    im = Image.new("RGBA", (W, 64), (0, 0, 0, 0))
    px = im.load()
    x0, x1, y0, yr = 3, W - 5, 2, 43     # rectangle du toit (inclus)
    BL, BR, BH, BB = 8, 8, 6, 10         # largeur des pans gauche, droite, haut, bas
    # ombre portée à droite (translucide)
    for y in range(y0 + 5, 50):
        for x in range(x1 + 1, x1 + 5):
            px[x, y] = (0, 0, 0, 70)
    # --- toit
    for y in range(y0, yr + 1):
        for x in range(x0, x1 + 1):
            # coins arrondis
            if (x - x0 + y - y0 < 2) or (x1 - x + y - y0 < 2) or (x - x0 + yr - y < 2) or (x1 - x + yr - y < 2):
                continue
            dl, dr, dt, db = (x - x0) / BL, (x1 - x) / BR, (y - y0) / BH, (yr - y) / BB
            m = min(dl, dr, dt, db)
            if m >= 1.0:
                bande, dx, dy = "panneau", x - x0 - BL, y - y0 - BH
            else:
                bande = "gauche" if m == dl else "droite" if m == dr else "haut" if m == dt else "bas"
                dx, dy = x - x0, y - y0
            c = pixel_toit(x, y, st, motif, bande, dx, dy)
            # arêtes des pans (diagonales) et bord du panneau : trait sombre
            vals = sorted([dl, dr, dt, db])
            if m < 1.0 and abs(vals[0] - vals[1]) < 0.09: c = mix(c, CONTOUR, 0.45)
            if m >= 1.0 and min(dl - 1.0, dr - 1.0, dt - 1.0, db - 1.0) < 0.12: c = mix(c, CONTOUR, 0.4)
            # contour extérieur
            if x in (x0, x1) or y in (y0, yr) or (x - x0 + y - y0 == 2) or (x1 - x + y - y0 == 2) or (x - x0 + yr - y == 2) or (x1 - x + yr - y == 2):
                c = CONTOUR
            px[x, y] = c + (255,)
    # --- mur de pierre (bande en bas)
    for y in range(yr + 1, 57):
        for x in range(x0 + 1, x1):
            ligne = (y - yr - 1) // 4
            c = (158, 158, 172)
            if (y - yr - 1) % 4 == 3 or (x + ligne * 5) % 10 == 0: c = (122, 122, 140)
            if y == yr + 1: c = (92, 92, 108)   # ombre sous le toit
            px[x, y] = c + (255,)
    for y in range(yr + 1, 58):
        px[x0, y] = CONTOUR + (255,); px[x1, y] = CONTOUR + (255,)
    for x in range(x0, x1 + 1): px[x, 57] = CONTOUR + (255,)
    # --- fenêtres (de part et d'autre de la porte)
    cx = W // 2
    for fx in (cx - 24, cx + 14):
        for y in range(46, 55):
            for x in range(fx, fx + 10):
                bord = x in (fx, fx + 9) or y in (46, 54)
                croix = x == fx + 4 or x == fx + 5 or y == 50
                px[x, y] = ((120, 76, 48) if bord else (240, 250, 255) if croix else (130, 200, 236)) + (255,)
    # --- auvent de pierre au-dessus de la porte (déborde sur le toit)
    for y in range(38, 47):
        for x in range(cx - 10, cx + 10):
            marge = max(0, 38 + 3 - y) * 1
            if abs(x - cx + 0.5) > 10 - (1 if y == 38 else 0): continue
            c = (196, 196, 210) if y < 44 else (170, 170, 186)
            if x in (cx - 10, cx + 9) or y == 38: c = CONTOUR
            px[x, y] = c + (255,)
    # --- porte cintrée en bois
    for y in range(44, 58):
        for x in range(cx - 7, cx + 7):
            dedans = abs(x - cx + 0.5) <= 5.5 and y >= 47
            if y < 47:   # arche : on garde le haut arrondi
                dedans = abs(x - cx + 0.5) <= 5.5 - (47 - y) * 1.2
            cadre = abs(x - cx + 0.5) <= 6.5 and y >= 46
            if dedans:
                c = porte
                if (x - cx) % 3 == 0: c = mix(porte, CONTOUR, 0.25)
                if y > 51 and x == cx + 3: c = (250, 220, 90)   # poignée
                px[x, y] = c + (255,)
            elif cadre and y >= 46:
                px[x, y] = (200, 200, 214, 255)
    # --- dalles devant la porte
    d = ImageDraw.Draw(im)
    for (ax, ay) in [(cx - 4, 58), (cx - 11, 61), (cx + 3, 61)]:
        d.rectangle((ax, ay, ax + 7, ay + 2), fill=(176, 184, 176, 255), outline=(110, 120, 112, 255))
    # --- cheminée
    if cheminee:
        for y in range(1, 11):
            for x in range(W - 22, W - 13):
                c = (150, 150, 164)
                if x in (W - 22, W - 14) or y in (1, 10): c = CONTOUR
                if 1 < y < 4 and W - 21 < x < W - 15: c = (50, 40, 50)
                px[x, y] = c + (255,)
    # --- petit coq doré (emblème du village) au centre du panneau
    if coq:
        gx, gy = cx - 5, 17 if W < 100 else 17
        masque = [
            "....CC.....",
            "...CRCT....",
            "...BBB..T..",
            "..BBBBB.TT.",
            "..BBBBBBTT.",
            "...BBBBBT..",
            "....BBBB...",
            ".....Y.Y...",
        ]
        coul = {"B": (255, 212, 72), "C": (232, 40, 40), "R": (255, 255, 255), "T": (255, 176, 40), "Y": (200, 140, 40)}
        for j, ligne in enumerate(masque):
            for i, ch in enumerate(ligne):
                if ch != ".":
                    px[gx + i, gy + j] = coul[ch] + (255,)
    im.save(os.path.join(SORTIE, nom + ".png"))
    return im

if __name__ == "__main__":
    os.makedirs(SORTIE, exist_ok=True)
    maisons = [
        maison(80, "v_maison_orange", "losanges", "losanges"),
        maison(80, "v_maison_bleue", "briques", "briques"),
        maison(80, "v_maison_chaume", "chaume", "chaume"),
        maison(80, "v_maison_rouge", "ardoise", "ardoise", cheminee=True),
        maison(80, "v_maison_pierre", "ecailles", "ecailles"),
        maison(112, "v_maison_caserne", "losanges", "losanges", cheminee=True),
        maison(80, "v_maison_bois", "bois", "bois", cheminee=True, porte=(150, 92, 52)),
    ]
    if len(sys.argv) > 1:
        fond = Image.new("RGBA", (460, 150), (112, 190, 64, 255))
        x = 4; y = 4
        for m in maisons:
            if x + m.width > 460: x = 4; y += 70
            fond.alpha_composite(m, (x, y)); x += m.width + 4
        fond.resize((fond.width * 3, fond.height * 3), Image.NEAREST).save(sys.argv[1])
