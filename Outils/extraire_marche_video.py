"""ESSAI : fabrique une marche de PROFIL à partir de la vidéo générée (garde casqué qui marche sur place).
Source : Assets/Gemini/originaux/garde_marche.mp4 (1280x720, 24 i/s ; profil entre 3,0 et 6,0 s environ).
Principe (comme pour heros_profil.jpg) : UN SEUL haut du corps (une image où la lance est verticale et propre),
et sous la hanche les JAMBES de chaque image du cycle (16 images = 2 pas, on en garde 8). La lance qui traverse
les jambes dans les autres images (et qui se dédouble parfois : bug de la vidéo) est effacée ; on redessine en dessous
le bas de la lance de l'image de base. Le sol gris de la vidéo est retiré (pixels peu saturés reliés au bord).
Sortie : Assets/Heros/garde_profil.png (8 images côte à côte, cases LARGEUR x HAUTEUR, pieds en bas) + aperçus.
Usage : python3 Outils/extraire_marche_video.py [debut_du_cycle]   (ffmpeg et scipy nécessaires)"""
import os, subprocess, sys, tempfile
import numpy as np
from PIL import Image
from scipy import ndimage

VIDEO = "Assets/Gemini/originaux/garde_marche.mp4"
SORTIE = "Assets/Heros/garde_profil.png"
APERCU = "Outils/apercus/garde_profil_apercu.png"
GIF = "Outils/apercus/garde_profil.gif"
DEBUT_S, DUREE_S = 2.5, 5.0          # morceau extrait de la vidéo (images numérotées depuis 1)
RECADRAGE = (420, 10, 860, 710)      # zone du personnage dans la vidéo
BASE = 19                            # image du haut du corps (lance verticale, pas de double lance)
DEBUT = int(sys.argv[1]) if len(sys.argv) > 1 else 37   # début du cycle de marche (16 images = 2 pas)
PERIODE, PAS = 16, 2                 # -> 8 images
HANCHE = 465                         # ligne (dans l'image recadrée) sous laquelle on prend les jambes
HAUTEUR = int(os.environ.get("HAUTEUR", 34))                         # hauteur finale du personnage (px), comme les autres persos du jeu


def extraire(dossier):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(DEBUT_S), "-t", str(DUREE_S), "-i", VIDEO,
                    "-vf", "crop=%d:%d:%d:%d" % (RECADRAGE[2] - RECADRAGE[0], RECADRAGE[3] - RECADRAGE[1], RECADRAGE[0], RECADRAGE[1]),
                    os.path.join(dossier, "f%03d.png")], check=True)


def lire(dossier, i):
    """Image RGBA : le sol gris (peu saturé, relié au bord) devient transparent ; l'ombre au sol aussi."""
    a = np.array(Image.open(os.path.join(dossier, "f%03d.png" % i)).convert("RGB")).astype(int)
    l, s = a.mean(2), a.max(2) - a.min(2)
    r, b = a[..., 0], a[..., 2]
    # sol = gris CHAUD et moyen (pas l'acier clair de la lance, ni les jambières gris-bleu, ni le contour noir)
    lab, _ = ndimage.label((s < 25) & (l > 22) & (l < 100) & (b <= r + 2))
    bords = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    perso = ~np.isin(lab, list(bords))
    perso = ndimage.binary_opening(perso, iterations=2)           # miettes isolées
    rgba = np.zeros(a.shape[:2] + (4,), np.uint8)
    rgba[..., :3] = a
    rgba[..., 3] = perso * 255
    return rgba


def lance(rgba):
    """Pixels du MANCHE de la lance (bois brun sombre) et de son contour noir proche."""
    a = rgba[..., :3].astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    l = a.mean(2)
    bois = (r > g) & (g > b) & (r - b > 22) & (l < 115) & (rgba[..., 3] > 0)
    # le bois est un trait fin et long : on garde les grandes composantes seulement
    lab, n = ndimage.label(bois)
    tailles = ndimage.sum(bois, lab, range(1, n + 1))
    gros = np.isin(lab, [k + 1 for k, t in enumerate(tailles) if t > 400])
    return ndimage.binary_dilation(gros, iterations=2) & (rgba[..., 3] > 0)


def boucher(img, trous):
    """Retire la lance (`trous`) puis rebouche les trous ENTOURÉS de jambe avec la couleur de jambe la plus proche."""
    jambe = (img[..., 3] > 0) & ~trous
    img[trous] = 0
    dedans = trous & ndimage.binary_closing(jambe, iterations=5)
    _, (iy, ix) = ndimage.distance_transform_edt(~jambe, return_indices=True)
    img[dedans] = img[iy[dedans], ix[dedans]]


def composer(dossier):
    base = lire(dossier, BASE)
    lance_base = lance(base)
    images = []
    for i in range(DEBUT, DEBUT + PERIODE, PAS):
        img = lire(dossier, i)
        boucher(img, lance(img))                             # la lance de cette image (souvent de travers) disparaît
        out = np.zeros_like(base)
        out[:HANCHE] = base[:HANCHE]                         # haut du corps fixe (lance verticale comprise)
        out[HANCHE:] = img[HANCHE:]                          # jambes de l'image
        bas = lance_base.copy(); bas[:HANCHE] = False
        out[bas] = base[bas]                                 # bas de la lance de l'image de base, devant les jambes
        images.append(out)
    return images


def reduire_trait(src, largeur, hauteur, seuil_trait=0.22):
    """Réduction qui GARDE LES TRAITS : chaque pixel final couvre un bloc de la source ; si assez de pixels
    du bloc sont des traits sombres (contours du dessin), le pixel devient sombre ; sinon couleur médiane du bloc.
    (Une simple moyenne fond le casque, l'armure et le visage dans le même beige.)"""
    h, w = src.shape[:2]
    rgb = np.zeros((hauteur, largeur, 3), np.uint8)
    opaque = np.zeros((hauteur, largeur), bool)
    for y in range(hauteur):
        for x in range(largeur):
            bloc = src[y * h // hauteur:(y + 1) * h // hauteur, x * w // largeur:(x + 1) * w // largeur].reshape(-1, 4)
            vis = bloc[bloc[:, 3] > 0][:, :3].astype(int)
            if len(vis) < 0.45 * len(bloc):
                continue
            opaque[y, x] = True
            lum = vis.mean(1)
            sombres = vis[lum < 45]
            if len(sombres) >= seuil_trait * len(vis):
                rgb[y, x] = np.median(sombres, 0)
            else:
                rgb[y, x] = np.median(vis[lum >= 45], 0)
    return Image.fromarray(rgb), opaque


def reduire(images):
    alpha = np.max([im[..., 3] for im in images], axis=0)
    ys, xs = np.where(alpha > 0)
    boite = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)   # même boîte pour toutes : rien ne saute
    k = HAUTEUR / (boite[3] - boite[1])
    largeur = int(round((boite[2] - boite[0]) * k))
    reduites = []
    for im in images:
        p = Image.fromarray(im).crop(boite)
        rgb, opaque = reduire_trait(np.array(p), largeur, HAUTEUR)
        reduites.append((rgb, opaque))
    # UNE palette commune (sinon les couleurs scintillent d'une image à l'autre), contraste relevé
    from PIL import ImageEnhance
    mosaique = Image.new("RGB", (largeur * len(reduites), HAUTEUR))
    for k, (rgb, _) in enumerate(reduites):
        mosaique.paste(ImageEnhance.Contrast(ImageEnhance.Color(rgb).enhance(1.2)).enhance(1.25), (k * largeur, 0))
    palette = mosaique.quantize(colors=18, method=Image.MEDIANCUT)
    petites = []
    for k, (_, opaque) in enumerate(reduites):
        q = np.array(palette.crop((k * largeur, 0, (k + 1) * largeur, HAUTEUR)).convert("RGBA"))
        q[..., 3] = np.where(opaque, 255, 0)
        # contour sombre d'1 px côté extérieur (lisibilité à petite taille)
        dehors = ~opaque & ndimage.binary_dilation(opaque)
        q[dehors] = (22, 18, 24, 255)
        petites.append(Image.fromarray(q))
    return petites


def main():
    with tempfile.TemporaryDirectory() as d:
        extraire(d)
        grandes = composer(d)
        if os.environ.get("APERCU_HD"):   # contrôle : le montage en grand (1/3), avant réduction
            hd = Image.new("RGBA", (150 * len(grandes), 240), (58, 60, 72, 255))
            for k, g in enumerate(grandes):
                hd.alpha_composite(Image.fromarray(g).resize((147, 233)), (k * 150, 0))
            hd.save(os.environ["APERCU_HD"])
        petites = reduire(grandes)
    w, h = petites[0].size
    planche = Image.new("RGBA", (w * len(petites), h))
    for k, p in enumerate(petites):
        planche.alpha_composite(p, (k * w, 0))
    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    planche.save(SORTIE)
    # aperçus : planche agrandie x6 sur fond de dalle, et GIF animé x4 à 12 i/s
    fond = (58, 60, 72, 255)
    grand = Image.new("RGBA", planche.size, fond); grand.alpha_composite(planche)
    grand.resize((planche.width * 6, planche.height * 6), Image.NEAREST).save(APERCU)
    cadres = []
    for p in petites:
        c = Image.new("RGBA", (w + 8, h + 4), fond); c.alpha_composite(p, (4, 2))
        cadres.append(c.resize(((w + 8) * 4, (h + 4) * 4), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
    cadres[0].save(GIF, save_all=True, append_images=cadres[1:], duration=83, loop=0)
    print("écrit :", SORTIE, "(%d images de %dx%d)" % (len(petites), w, h), "+", APERCU, GIF)


if __name__ == "__main__":
    main()
