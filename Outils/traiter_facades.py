"""Façades des entrées de donjon (images Gemini, vue de face) -> `Assets/Gemini/tuiles/v_facade_*.png` (400x192 = 25x12 cases).
Sources (Assets/Gemini/originaux/) : facade_aile_ouverte.jpg (AILE GAUCHE : 5 plumes de pierre sur le rempart, porte ouverte ; l'aile droite = miroir)
et facade_queue.jpg (QUEUE : donjon rond, tour de tête, 4 tours à flammes qui mènent à la porte).
La variante « herse baissée » de l'aile est FABRIQUÉE ICI en dessinant une herse dans l'arche (pas d'image source).
Le ciel magenta est remplacé par des briques sombres (le bâtiment continue vers le haut de l'écran).
À lancer AVANT generer_village.py."""
import os
from PIL import Image, ImageFilter
import numpy as np

ORIG = "Assets/Gemini/originaux/"
SORTIE = "Assets/Gemini/tuiles/"
HAUTEUR = 192        # 12 cases
LARGEUR = 400
BANDE = 26           # largeur de bande reflétée pour élargir les bords


def cle_ciel(a):
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    return (r > 150) & (b > 150) & (g < 120)


def herse(a):
    """Dessine une herse de fer dans l'arche de la porte (image de l'aile : arche centrée en x=689, ouverture y 598-745)."""
    a = a.copy()
    for y in range(598, 748):
        for x in range(645, 734):
            if y < 650 and ((x - 689) / 50.0) ** 2 + ((y - 650) / 52.0) ** 2 > 1.0:
                continue
            vertical = (x - 645) % 12 < 3
            horizontal = (y - 600) % 46 < 3 and y > 640
            if vertical or horizontal:
                a[y, x] = (118, 122, 134) if ((x - 645) % 12 == 0 or (y - 600) % 46 == 0) else (84, 88, 100)
    return a


def construire(nom_src, sortie, miroir, retouche=None, texture_ciel=None):
    a = np.array(Image.open(ORIG + nom_src).convert("RGB"))
    if retouche:
        a = retouche(a)
    ciel = cle_ciel(a)
    ciel = np.array(Image.fromarray((ciel * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))) > 0
    tuile = texture_ciel.astype(float) * 0.5
    h, l = a.shape[:2]
    fond = np.tile(tuile, (h // tuile.shape[0] + 1, l // tuile.shape[1] + 1, 1))[:h, :l]
    a = a.astype(float)
    a[ciel] = fond[ciel]
    img = Image.fromarray(a.astype(np.uint8))
    echelle = HAUTEUR / img.height
    w = round(img.width * echelle)
    img = img.resize((w, HAUTEUR), Image.LANCZOS).filter(ImageFilter.UnsharpMask(1, 60, 2))
    reste = LARGEUR - w
    g = reste // 2
    d = reste - g
    out = Image.new("RGB", (LARGEUR, HAUTEUR))
    out.paste(img, (g, 0))
    gauche = img.crop((0, 0, BANDE, HAUTEUR)); droite = img.crop((w - BANDE, 0, w, HAUTEUR))
    x, flip = g, True
    while x > 0:                       # à gauche : reflets successifs de la bande du bord
        out.paste(gauche.transpose(Image.FLIP_LEFT_RIGHT) if flip else gauche, (x - BANDE, 0)); x -= BANDE; flip = not flip
    x, flip = g + w, True
    while x < LARGEUR:
        out.paste(droite.transpose(Image.FLIP_LEFT_RIGHT) if flip else droite, (x, 0)); x += BANDE; flip = not flip
    if miroir:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    out = out.quantize(48, dither=Image.NONE).convert("RGBA")
    out.save(SORTIE + sortie)
    print(sortie, out.size, "échelle %.3f, marges %d+%d" % (echelle, g, d))


if __name__ == "__main__":
    # briques sombres prises sur le mur de l'aile (zone sans bannière ni torche)
    mur = np.array(Image.open(ORIG + "facade_aile_ouverte.jpg").convert("RGB"))[612:690, 175:290]
    construire("facade_queue.jpg", "v_facade_queue.png", False, None, mur)
    construire("facade_aile_ouverte.jpg", "v_facade_aile_g.png", False, None, mur)
    construire("facade_aile_ouverte.jpg", "v_facade_aile_d.png", True, None, mur)
    construire("facade_aile_ouverte.jpg", "v_facade_aile_d_fermee.png", True, herse, mur)
    ims = [Image.open(SORTIE + n) for n in ("v_facade_queue.png", "v_facade_aile_g.png", "v_facade_aile_d_fermee.png")]
    pl = Image.new("RGBA", (LARGEUR, HAUTEUR * 3 + 8), (60, 140, 60, 255))
    for i, im in enumerate(ims):
        pl.paste(im, (0, i * (HAUTEUR + 4)), im)
    os.makedirs("Outils/apercus", exist_ok=True)
    pl.resize((LARGEUR * 2, pl.height * 2), Image.NEAREST).save("Outils/apercus/facades.png")
