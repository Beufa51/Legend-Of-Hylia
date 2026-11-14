"""Façades des entrées de donjon (images Gemini) -> `Assets/Gemini/tuiles/v_facade_*.png` (400x192 = 25x12 cases).
Sources (Assets/Gemini/originaux/) : facade_queue.jpg (tours à flammes), facade_aile_ouverte.jpg, facade_aile_fermee.jpg (plumes, aile GAUCHE ; l'aile droite = miroir).
Retouches : la grande tour / la grande plume du bout étaient coupées en haut de l'image -> on les COMPLÈTE (flamme copiée d'une autre tour ; pointe de plume copiée de la plume voisine).
Le ciel magenta est remplacé par un fond de briques sombres (le bâtiment continue vers le haut de l'écran).
À lancer AVANT generer_village.py."""
import os
from PIL import Image, ImageFilter, ImageChops
import numpy as np

ORIG = "Assets/Gemini/originaux/"
SORTIE = "Assets/Gemini/tuiles/"
PAD = 110            # marge ajoutée en haut pour les parties complétées (pixels de l'image source)
BAS = 704            # on coupe l'image à cette ligne (sol de terre exclu)
HAUTEUR = 192        # 12 cases
LARGEUR = 400


def cle_ciel(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 150) & (b > 150) & (g < 120)


def avec_marge(img):
    a = np.array(img.convert("RGB"))
    marge = np.zeros((PAD, a.shape[1], 3), np.uint8); marge[:] = (255, 0, 255)
    return np.concatenate([marge, a], axis=0)


def coller(dst, src, boite_src, dx, dy, masque):
    """Copie les pixels de `src` (boite_src = x0,y0,x1,y1) décalés de (dx,dy), seulement là où `masque` (même taille que la boîte) est vrai."""
    x0, y0, x1, y1 = boite_src
    for y in range(y0, y1):
        for x in range(x0, x1):
            if masque[y - y0, x - x0]:
                ty, tx = y + dy, x + dx
                if 0 <= ty < dst.shape[0] and 0 <= tx < dst.shape[1]:
                    dst[ty, tx] = src[y, x]


def completer_flamme(a):
    """Grande tour centrale : la flamme sortait de l'image. On copie celle de la 2e tour (mêmes proportions) au-dessus de la couronne."""
    src = a.copy()
    boite = (350, PAD + 5, 535, PAD + 150)
    reg = src[boite[1]:boite[3], boite[0]:boite[2]].astype(int)
    r, g, b = reg[..., 0], reg[..., 1], reg[..., 2]
    flamme = (r > 205) & (g > 60) & (b < 170) & ~cle_ciel(reg.astype(np.uint8))
    flamme = np.array(Image.fromarray((flamme * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))) > 0
    # on efface l'ancienne flamme coupée de la grande tour, puis on colle
    dx, dy = 688 - 440, (PAD + 40) - (PAD + 147)
    zone = (610, 0, 770, PAD + 60)
    sub = a[zone[1]:zone[3], zone[0]:zone[2]].astype(int)
    vieux = (sub[..., 0] > 205) & (sub[..., 2] < 170)
    a[zone[1]:zone[3], zone[0]:zone[2]][vieux] = (255, 0, 255)
    coller(a, src, boite, dx, dy, flamme)


def completer_plume(a):
    """Plume du bout (la plus haute) : la pointe sortait de l'image. On copie la pointe de la plume voisine, agrandie pour avoir la même largeur."""
    src = Image.fromarray(a.copy())
    sky = cle_ciel(a)
    def largeur(y, x0, x1):
        xs = np.where(~sky[y, x0:x1])[0]
        return (xs.max() - xs.min() + 1, (xs.max() + xs.min()) / 2 + x0) if len(xs) else (0, 0)
    w5, c5 = largeur(PAD + 1, 1085, 1265)               # largeur de la plume du bout tout en haut de l'image d'origine
    # plume voisine : on cherche la ligne où sa largeur égale w5 / facteur
    f = 1.0
    haut4 = next(y for y in range(PAD, PAD + 200) if largeur(y, 850, 1015)[0] > 0)
    c4 = largeur(haut4 + 60, 850, 1015)[1]
    best = None
    for y in range(haut4, haut4 + 140):
        w, _ = largeur(y, 850, 1015)
        if w >= w5 / 1.0:
            best = y; break
    hauteur_pointe = best - haut4
    pointe = src.crop((int(c4 - w5 / 2 - 6), haut4, int(c4 + w5 / 2 + 7), best + 2))
    arr = np.array(pointe)
    m = ~cle_ciel(arr)
    x_dest = int(round(c5 - pointe.width / 2))
    y_dest = PAD + 0 - hauteur_pointe
    for y in range(arr.shape[0]):
        for x in range(arr.shape[1]):
            if m[y, x]:
                ty, tx = y_dest + y, x_dest + x
                if 0 <= ty < a.shape[0] and 0 <= tx < a.shape[1]:
                    a[ty, tx] = arr[y, x]


def fond_briques(h, l):
    """Fond du « ciel » : briques sombres du mur, assombries."""
    return None


def construire(nom_src, retouche, sortie, miroir):
    a = avec_marge(Image.open(ORIG + nom_src))
    retouche(a)
    # ciel -> fond de briques sombres (texture prise sur le mur, assombrie)
    ciel = cle_ciel(a)
    ciel = np.array(Image.fromarray((ciel * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))) > 0
    tuile = a[PAD + 600:PAD + 676, 100:440].astype(float) * 0.5
    h, l = a.shape[:2]
    fond = np.tile(tuile, (h // tuile.shape[0] + 1, l // tuile.shape[1] + 1, 1))[:h, :l]
    a = a.astype(float)
    a[ciel] = fond[ciel]
    a = a.astype(np.uint8)[: PAD + BAS]
    img = Image.fromarray(a)
    echelle = HAUTEUR / img.height
    w = round(img.width * echelle)
    img = img.resize((w, HAUTEUR), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1, 60, 2))
    # élargit jusqu'à 400 px en reflétant les bords (le mur est répétitif)
    reste = LARGEUR - w
    g = reste // 2
    d = reste - g
    out = Image.new("RGB", (LARGEUR, HAUTEUR))
    out.paste(img, (g, 0))
    BANDE = 26   # largeur de bande reflétée (< distance entre le bord et la 1re tour, pour ne pas dupliquer de tour)
    gauche = img.crop((0, 0, BANDE, HAUTEUR)); droite = img.crop((w - BANDE, 0, w, HAUTEUR))
    x, flip = g, True
    while x > 0:                       # à gauche : reflets successifs de la bande du bord
        bande = gauche.transpose(Image.FLIP_LEFT_RIGHT) if flip else gauche
        out.paste(bande, (x - BANDE, 0)); x -= BANDE; flip = not flip
    x, flip = g + w, True
    while x < LARGEUR:
        bande = droite.transpose(Image.FLIP_LEFT_RIGHT) if flip else droite
        out.paste(bande, (x, 0)); x += BANDE; flip = not flip
    if miroir:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    out = out.quantize(48, dither=Image.NONE).convert("RGBA")
    out.save(SORTIE + sortie)
    print(sortie, out.size, "échelle %.3f, marges %d+%d" % (echelle, g, d))


if __name__ == "__main__":
    construire("facade_queue.jpg", completer_flamme, "v_facade_queue.png", False)
    construire("facade_aile_ouverte.jpg", completer_plume, "v_facade_aile_g.png", False)
    construire("facade_aile_ouverte.jpg", completer_plume, "v_facade_aile_d.png", True)
    construire("facade_aile_fermee.jpg", completer_plume, "v_facade_aile_d_fermee.png", True)
    # aperçu
    ims = [Image.open(SORTIE + n) for n in ("v_facade_queue.png", "v_facade_aile_g.png", "v_facade_aile_d_fermee.png")]
    pl = Image.new("RGBA", (LARGEUR, HAUTEUR * 3 + 8), (60, 140, 60, 255))
    for i, im in enumerate(ims):
        pl.paste(im, (0, i * (HAUTEUR + 4)), im)
    os.makedirs("Outils/apercus", exist_ok=True)
    pl.resize((LARGEUR * 2, pl.height * 2), Image.NEAREST).save("Outils/apercus/facades.png")
