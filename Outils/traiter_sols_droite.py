"""SOLS DE L'AILE DROITE : planche Gemini `originaux/sols_aile_droite.jpg` (6 bandes de 4 tuiles) ->
`sol_<style>`, `_b` (retournée), `_c` / `_d` (variantes) pour : glace, miroir, ardoise, rouille, rouille2, marbre.
Styles des plumes (generer_aile_droite.py) : D1 rouille, D2 marbre, D3 ardoise (la glace `i` ressort dessus), D4 miroir, D5 rouille2."""
from PIL import Image
D = "Assets/Gemini/"
im = Image.open(D + "originaux/sols_aile_droite.jpg").convert("RGB")
# (boîte de la bande, marge basse : la glace et le miroir ont une lèvre épaisse en bas)
BANDES = {
    "glace":    ((30, 70, 692, 240), 16),
    "miroir":   ((716, 70, 1380, 240), 16),
    "ardoise":  ((30, 310, 692, 486), 9),
    "rouille":  ((716, 310, 1380, 486), 9),
    "rouille2": ((30, 557, 692, 744), 9),
    "marbre":   ((716, 557, 1380, 744), 9),
}
M = 9


def tuile(box, bas, i):
    x0, y0, x1, y1 = box
    w = (x1 - x0) / 4.0
    c = im.crop((int(x0 + i * w + M), y0 + M, int(x0 + (i + 1) * w - M), y1 - bas))
    return c.resize((16, 16), Image.LANCZOS)


for nom, (box, bas) in BANDES.items():
    t = [tuile(box, bas, i) for i in range(4)]
    for suffixe, img in (("", t[0]), ("_b", t[0].transpose(Image.FLIP_LEFT_RIGHT)), ("_c", t[1]), ("_d", t[3])):
        img.save(D + "tuiles/sol_%s%s.png" % (nom, suffixe))
    print(nom)

# Plume D2 (dalles rouges / bleues) : le marbre est trop clair, les dalles ne ressortent pas -> marbre ASSOMBRI (« marbre_sombre »),
# gris chaud neutre, ni rouge ni bleu.
from PIL import ImageEnhance
for suffixe in ("", "_b", "_c", "_d"):
    img = Image.open(D + "tuiles/sol_marbre%s.png" % suffixe).convert("RGB")
    img = ImageEnhance.Brightness(img).enhance(0.42)
    img = ImageEnhance.Contrast(img).enhance(1.15)
    img.save(D + "tuiles/sol_marbre_sombre%s.png" % suffixe)
print("marbre_sombre")

# Plume D4 (le reflet est un fantôme bleu glacé) : le sol « miroir » est trop clair et bleuté, le reflet s'y perd -> sol ASSOMBRI
# et réchauffé (« miroir_sombre » : pierre brun-gris sombre) pour que le reflet bleu ressorte.
for suffixe in ("", "_b", "_c", "_d"):
    img = Image.open(D + "tuiles/sol_miroir%s.png" % suffixe).convert("RGB")
    img = ImageEnhance.Color(img).enhance(0.35)
    img = ImageEnhance.Brightness(img).enhance(0.36)
    img = ImageEnhance.Contrast(img).enhance(1.1)
    r, g, b = img.split()
    r = r.point(lambda v: min(255, int(v * 1.12) + 3)); b = b.point(lambda v: int(v * 0.88))
    Image.merge("RGB", (r, g, b)).save(D + "tuiles/sol_miroir_sombre%s.png" % suffixe)
print("miroir_sombre")
