"""LOT 4 GEMINI (aile gauche) : miroirs, tapis à emblème, foyer, stèle à inscription, sols par plume.
Originaux : Assets/Gemini/originaux/{miroirs2,tapis_embleme,foyer,stele_inscription,sols_plumes}.jpg
À LANCER APRÈS traiter_lot_donjon.py, traiter_soleil.py et fabriquer_stele_inscription.py (qui écrivent les anciennes versions).
Écrit dans Assets/Gemini/tuiles/ : miroir_m/n (18x26), tapis_embleme_48, foyer_eteint + foyer_1..4 (22x40),
stele_inscription (18x32), sol_<style>[_b|_c|_d] pour les styles claire, suie, notes, nuit, gris, doree."""
from PIL import Image
import numpy as np
D = "Assets/Gemini/"


def ouvrir(nom):
    return Image.open(D + "originaux/" + nom).convert("RGB")


def sans_magenta(im):
    """RGBA : le fond magenta (#FF00FF et ses dégradés) devient transparent."""
    a = np.asarray(im).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    fond = (r > 150) & (b > 150) & (g < 110) & (abs(r - b) < 90)
    out = np.dstack([a, np.where(fond, 0, 255)]).astype("uint8")
    return Image.fromarray(out, "RGBA")


def boite(im):
    return im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()


def reduire(im, taille, palette=28):
    """Recadre sur l'objet, réduit (Lanczos), palette limitée, alpha net."""
    b = boite(im)
    im = im.crop(b)
    p = im.resize(taille, Image.LANCZOS)
    alpha = p.getchannel("A").point(lambda v: 255 if v > 140 else 0)
    q = p.convert("RGB").quantize(palette, method=Image.MEDIANCUT).convert("RGB")
    q = q.convert("RGBA")
    q.putalpha(alpha)
    return q


def sauver(im, nom):
    im.save(D + "tuiles/%s.png" % nom)
    print(nom, im.size)


# ---------------------------------------------------------------- miroirs
m = sans_magenta(ouvrir("miroirs2.jpg"))
gauche = m.crop((60, 0, 700, 768))
miroir = reduire(gauche, (18, 26), 32)
sauver(miroir, "miroir_m")                                   # « / » (penché vers la droite en haut)
sauver(miroir.transpose(Image.FLIP_LEFT_RIGHT), "miroir_n")  # « \ »

# ---------------------------------------------------------------- tapis à emblème (3x3 cases)
t = ouvrir("tapis_embleme.jpg").crop((355, 45, 1053, 724))
sauver(t.resize((48, 48), Image.LANCZOS).quantize(20, method=Image.MEDIANCUT).convert("RGB").convert("RGBA"), "tapis_embleme_48")

# ---------------------------------------------------------------- foyer (vasque de pierre) : éteint, braises, 3 flammes
f = sans_magenta(ouvrir("foyer.jpg"))
tranches = [(0, 290), (290, 565), (565, 840), (840, 1115), (1115, 1408)]
imgs = [reduire(f.crop((x0, 0, x1, 768)), (22, 40), 32) for x0, x1 in tranches]
# même cadre pour toutes : la base (pied) alignée en bas, centrée
def cadrer(im, w=22, h=40):
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    c.alpha_composite(im, ((w - im.width) // 2, h - im.height))
    return c
imgs = [cadrer(i) for i in imgs]
sauver(imgs[0], "foyer_eteint")
for k, i in enumerate(imgs[1:], 1):
    sauver(i, "foyer_%d" % k)

# ---------------------------------------------------------------- stèle à inscription
s = sans_magenta(ouvrir("stele_inscription.jpg")).crop((150, 0, 720, 768))
sauver(reduire(s, (18, 32), 28), "stele_inscription")

# ---------------------------------------------------------------- sols
sols = ouvrir("sols_plumes.jpg")
# (nom, boîte de la bande de 4 tuiles, indice de la tuile de base, indices des variantes rares)
BANDES = {
    "claire": ((42, 47, 662, 204), 0, (1, 2, 3)),
    "suie":   ((745, 47, 1368, 204), 0, (1, 2, 3)),
    "gris":   ((37, 302, 667, 466), 0, (1, 2, 3)),
    "notes":  ((742, 302, 1370, 466), 2, (0, 1, 3)),
    "nuit":   ((25, 553, 665, 720), 0, (1, 2, 3)),
    "doree":  ((730, 553, 1368, 720), 0, (1, 2, 3)),
}
INSET = 7


def tuile(box, i):
    x0, y0, x1, y1 = box
    w = (x1 - x0) / 4.0
    c = sols.crop((int(x0 + i * w + INSET), y0 + INSET, int(x0 + (i + 1) * w - INSET), y1 - INSET))
    return c.resize((16, 16), Image.LANCZOS)


for nom, (box, base, rares) in BANDES.items():
    b = tuile(box, base)
    if nom == "notes":   # la tuile de base ne garde pas son signe gravé (il se répéterait partout) : dalle lisse
        px = b.load()
        fond = px[3, 8]
        for yy in range(4, 12):
            for xx in range(4, 12):
                px[xx, yy] = fond
    if nom == "gris":   # la pierre grise est très sombre : éclaircie pour que le rayon de la plume 5 reste lisible sans écraser les dalles
        from PIL import ImageEnhance
        e = lambda im: ImageEnhance.Brightness(im).enhance(1.6)
        b = e(b)
    sauver(b, "sol_%s" % nom)
    sauver(b.transpose(Image.FLIP_LEFT_RIGHT), "sol_%s_b" % nom)
    c, d = tuile(box, rares[0]), tuile(box, rares[2])
    if nom == "gris":
        c, d = e(c), e(d)
    sauver(c, "sol_%s_c" % nom)
    sauver(d, "sol_%s_d" % nom)

# sol « sable » (plume 1) : les dalles dorées ternies et désaturées (la bleutée faisait penser à de la glace)
from PIL import ImageEnhance
for suf in ("", "_b", "_c", "_d"):
    t = Image.open(D + "tuiles/sol_doree%s.png" % suf).convert("RGB")
    t = ImageEnhance.Color(t).enhance(0.55)
    t = ImageEnhance.Brightness(t).enhance(0.82)
    t.save(D + "tuiles/sol_sable%s.png" % suf)
