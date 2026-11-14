"""Outil de développement (APRÈS traiter_pack_donjon.py, fabriquer_niches.py et fabriquer_murs_donjon.py) : dessine les FAÇADES des trois entrées du donjon final du coq.
Un grand bâtiment de pierre vu de face (400x96 = 25x6 cases), qui MONTE JUSQU'EN HAUT DE L'ÉCRAN (le haut est coupé : « la suite est sur l'écran du dessus »), avec :
  - un mur du fond sombre sur toute la largeur (le bâtiment continue derrière) ;
  - 5 TOURS pointues = les PLUMES du coq : ailes = tours de plus en plus hautes (aile gauche : de gauche à droite ; aile droite : l'inverse) ;
    queue = éventail de 5 tours penchées vers l'extérieur, aux pointes en flammes ;
  - un mur bas avec créneaux, bannières, torches, et une grande ARCHE de 3 cases (la porte) au centre, sur la dernière rangée.
Images produites (Assets/Gemini/tuiles/) : v_facade_aile_g, v_facade_aile_d, v_facade_aile_d_fermee (herse baissée : le garde), v_facade_queue.
Usage : python3 Outils/fabriquer_facade.py"""
import os
from PIL import Image, ImageDraw

SORTIE = os.path.join(os.path.dirname(__file__), "..", "Assets", "Gemini", "tuiles")
W, H = 400, 96
BASE_Y = 64                      # le mur bas commence ici (2 rangées : 64..96)
CONTOUR = (16, 20, 32, 255)
CLAIR = (150, 164, 192, 255)
TOUR_L = 44                                  # largeur d'une tour (fines : ce sont des plumes)
TOURS_X = [200 + (i - 2) * 82 - TOUR_L // 2 for i in range(5)]   # 5 tours, centrées sur 36, 118, 200, 282, 364 ; celle du milieu est au-dessus de l'arche


def tuile(nom):
    return Image.open(os.path.join(SORTIE, nom + ".png")).convert("RGBA")


def paver(img, texture, zone, teinte=1.0):
    """Remplit `zone` (x0, y0, x1, y1) avec une texture répétée, éclaircie/assombrie par `teinte`."""
    x0, y0, x1, y1 = zone
    tw, th = texture.size
    for y in range(y0, y1, th):
        for x in range(x0, x1, tw):
            t = texture
            if teinte != 1.0:
                r, g, b, a = t.split()
                f = lambda v: max(0, min(255, int(v * teinte)))
                t = Image.merge("RGBA", (r.point(f), g.point(f), b.point(f), a))
            img.alpha_composite(t.crop((0, 0, min(tw, x1 - x), min(th, y1 - y))), (x, y))


def fabrique_tour(haut_corps, pointe, couleur_pointe, penche=0.0, decalage_x=0):
    """Une tour de 56 px de large : corps de briques de `haut_corps` jusqu'à BASE_Y (0 = coupée par le haut de l'écran) + pointe de `pointe` px.
    Renvoie une image H x (TOUR_L + marge) ; `penche` = décalage horizontal par pixel de hauteur (tour penchée de la queue)."""
    marge = 40
    img = Image.new("RGBA", (TOUR_L + 2 * marge, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    brique = tuile("mur_face_haut")
    y_haut = max(0, haut_corps)
    paver(img, brique, (marge, y_haut, marge + TOUR_L, H), 1.0)
    # ombre à droite, lumière à gauche
    d.rectangle((marge + TOUR_L - 6, y_haut, marge + TOUR_L - 1, H), fill=(0, 0, 0, 70))
    d.rectangle((marge, y_haut, marge + 3, H), fill=(255, 255, 255, 40))
    d.line((marge, y_haut, marge, H), fill=CONTOUR)
    d.line((marge + TOUR_L - 1, y_haut, marge + TOUR_L - 1, H), fill=CONTOUR)
    # corniche en haut du corps + pointe (ogive)
    if haut_corps > 0:
        d.rectangle((marge - 3, y_haut, marge + TOUR_L + 2, y_haut + 4), fill=CLAIR, outline=CONTOUR)
        sommet = y_haut - pointe
        cx = marge + TOUR_L // 2
        for dy in range(pointe + 1):               # ogive : la largeur diminue en courbe vers le sommet
            t = dy / max(1, pointe)
            demi = int((TOUR_L / 2 + 2) * (1 - t) ** 1.15)
            y = y_haut - dy
            d.line((cx - demi, y, cx + demi, y), fill=couleur_pointe[0] if dy % 5 else couleur_pointe[1])
        d.polygon([(marge - 2, y_haut), (cx, sommet), (marge + TOUR_L + 1, y_haut)], outline=CONTOUR)
        d.line((cx, sommet, cx, y_haut - 2), fill=couleur_pointe[2])        # arête centrale
        # lumière sur la pente gauche
        for dy in range(pointe):
            t = dy / max(1, pointe)
            demi = int((TOUR_L / 2 + 2) * (1 - t) ** 1.15)
            d.point((cx - demi + 2, y_haut - dy), fill=couleur_pointe[2])
    # meurtrière (fente sombre) au milieu de la partie visible du corps
    milieu = (y_haut + BASE_Y) // 2 if haut_corps < BASE_Y - 24 else BASE_Y - 22
    if milieu - 8 > y_haut:
        d.rectangle((marge + TOUR_L // 2 - 2, milieu - 8, marge + TOUR_L // 2 + 1, milieu + 6), fill=(8, 10, 18, 255), outline=CLAIR)
    if penche:
        pen = Image.new("RGBA", img.size, (0, 0, 0, 0))
        for y in range(H):
            dec = round((BASE_Y - y) * penche) if y < BASE_Y else 0
            pen.alpha_composite(img.crop((0, y, img.width, y + 1)), (dec, y))
        img = pen
    return img


def facade(hauteurs, pointes, couleurs, penches, arche, miroir=False, flammes=False):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # 1) le fond : un grand mur sombre qui continue vers le haut (plus sombre en haut : on devine un bâtiment immense)
    paver(img, tuile("mur_fond"), (0, 0, W, H), 0.8)
    ombre = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(ombre)
    for y in range(0, 60):
        od.line((0, y, W, y), fill=(0, 0, 10, int(110 * (1 - y / 60))))
    img.alpha_composite(ombre)
    # 2) les tours (les plus hautes à l'arrière-plan : on les dessine de la plus haute à la plus basse)
    ordre = sorted(range(5), key=lambda i: hauteurs[i])
    for i in ordre:
        tour = fabrique_tour(hauteurs[i], pointes[i], couleurs[i], penches[i])
        img.alpha_composite(tour, (TOURS_X[i] - 40, 0))
    # 3) le mur bas, avec créneaux dans les intervalles entre les tours
    paver(img, tuile("mur_face_haut"), (0, BASE_Y, W, H), 0.92)
    d = ImageDraw.Draw(img)
    d.rectangle((0, BASE_Y - 2, W, BASE_Y + 3), fill=CLAIR, outline=CONTOUR)          # corniche
    d.line((0, BASE_Y + 4, W, BASE_Y + 4), fill=(0, 0, 0, 110))
    for x in range(0, W, 16):                                                           # créneaux entre les tours
        if not any(TOURS_X[i] - 2 <= x <= TOURS_X[i] + TOUR_L for i in range(5)):
            d.rectangle((x + 2, BASE_Y - 9, x + 11, BASE_Y - 2), fill=CLAIR, outline=CONTOUR)
    d.rectangle((0, H - 4, W, H), fill=(70, 78, 98, 255))                               # soubassement
    d.line((0, H - 5, W, H - 5), fill=CONTOUR)
    # 4) bannières et torches dans les intervalles
    ban = tuile("banniere")
    for gap_c in (159, 241):
        img.alpha_composite(ban, (gap_c - ban.width // 2, BASE_Y - 4))
    torche = tuile("torche_1")
    for gap_c in (77, 323):
        img.alpha_composite(torche, (gap_c - torche.width // 2, BASE_Y + 2))
    # 5) l'arche (porte de 3 cases) au centre, sur les 2 dernières rangées
    img.alpha_composite(tuile(arche), (176, 64))
    if miroir:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


if __name__ == "__main__":
    PIERRE = [(70, 82, 112, 255), (88, 102, 136, 255), (150, 164, 196, 255)]
    FLAMME = [(214, 70, 24, 255), (250, 150, 40, 255), (255, 226, 120, 255)]
    # AILES : tours de plus en plus hautes (la 5e est coupée par le haut de l'écran : le bâtiment continue)
    hauteurs_aile = [54, 40, 26, 12, 0]
    pointes_aile = [24, 28, 32, 36, 0]
    facade(hauteurs_aile, pointes_aile, [PIERRE] * 5, [0] * 5, "arche_herse_5").save(os.path.join(SORTIE, "v_facade_aile_g.png"))
    facade(hauteurs_aile, pointes_aile, [PIERRE] * 5, [0] * 5, "arche_herse_5", miroir=True).save(os.path.join(SORTIE, "v_facade_aile_d.png"))
    facade(hauteurs_aile, pointes_aile, [PIERRE] * 5, [0] * 5, "arche_herse_1", miroir=True).save(os.path.join(SORTIE, "v_facade_aile_d_fermee.png"))
    # QUEUE : éventail de 5 tours penchées vers l'extérieur, la plus haute au centre ; pointes en flammes
    hauteurs_q = [40, 20, 0, 20, 40]
    pointes_q = [26, 32, 0, 32, 26]
    penches_q = [-0.12, -0.06, 0.0, 0.06, 0.12]
    couleurs_q = [FLAMME, FLAMME, PIERRE, FLAMME, FLAMME]
    facade(hauteurs_q, pointes_q, couleurs_q, penches_q, "arche_herse_5").save(os.path.join(SORTIE, "v_facade_queue.png"))
    print("façades fabriquées")
