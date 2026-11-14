#!/usr/bin/env python3
"""Outil audio : (1) ROGNE le silence final des musiques rendues depuis les MIDI (`rendre_musiques.py` laisse 3 à 9 s de silence à la fin :
dans le jeu la boucle s'interrompait pendant ce temps) ; (2) MESURE le volume de chaque piste (EBU R128) et écrit `Scripts/niveaux_musiques.gd`,
le gain en dB qui met toutes les pistes au même volume ressenti (cible -16 LUFS ; Musiques.gain_db() l'applique).
À lancer APRÈS rendre_musiques.py. Usage : python3 Outils/rogner_musiques.py [--sans-rogner]"""
import glob, os, re, subprocess, sys

RACINE = os.path.join(os.path.dirname(__file__), "..")
CIBLE = -16.0                     # volume ressenti visé (LUFS)
GAIN_MIN, GAIN_MAX = -6.0, 4.0    # on ne corrige pas plus que ça (évite d'amplifier du bruit ou d'écraser une piste)
QUEUE = 0.6                       # on garde 0,6 s de résonance après la dernière note


def ffmpeg(*args):
    return subprocess.run(["ffmpeg", "-nostats", "-hide_banner", *args], capture_output=True, text=True).stderr


def duree(fichier):
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", ffmpeg("-i", fichier))
    return int(m[1]) * 3600 + int(m[2]) * 60 + float(m[3])


def rogner(fichier):
    """Coupe le silence final (> 1 s). Renvoie la durée retirée."""
    total = duree(fichier)
    sortie = ffmpeg("-i", fichier, "-af", "silencedetect=n=-50dB:d=1", "-f", "null", "-")
    debuts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", sortie)]
    if not debuts or total - debuts[-1] < 1.0:
        return 0.0
    fin = debuts[-1] + QUEUE
    tmp = fichier + ".tmp.ogg"
    ffmpeg("-y", "-i", fichier, "-t", "%.3f" % fin, "-af", "afade=t=out:st=%.3f:d=%.3f" % (fin - 0.3, 0.3), "-c:a", "libvorbis", "-q:a", "4", tmp)
    os.replace(tmp, fichier)
    return total - fin


def lufs(fichier):
    m = re.findall(r"I:\s+(-?[\d.]+) LUFS", ffmpeg("-i", fichier, "-af", "ebur128", "-f", "null", "-"))
    return float(m[-1])


def main():
    musiques = sorted(glob.glob(os.path.join(RACINE, "Assets", "Musique", "*.ogg")) + glob.glob(os.path.join(RACINE, "Assets", "Musique", "*.mp3")))
    musiques += [os.path.join(RACINE, "Assets", "Ninja_adventure", "Audio", "Musics", n) for n in
                 ("21 - Dungeon.ogg", "27 - Chill.ogg", "24 - Final Area.ogg", "36 - Village.ogg")]
    lignes = []
    for f in musiques:
        if not os.path.exists(f):
            continue
        if "--sans-rogner" not in sys.argv and "Musique" + os.sep in f and f.endswith(".ogg"):
            coupe = rogner(f)
            if coupe:
                print("rogné %5.1f s : %s" % (coupe, os.path.basename(f)))
        niveau = lufs(f)
        gain = max(GAIN_MIN, min(GAIN_MAX, CIBLE - niveau))
        chemin = "res://" + os.path.relpath(f, RACINE).replace(os.sep, "/")
        lignes.append('\t"%s": %.1f,   # %.1f LUFS' % (chemin, gain, niveau))
    with open(os.path.join(RACINE, "Scripts", "niveaux_musiques.gd"), "w", encoding="utf-8") as sortie:
        sortie.write("# FICHIER GÉNÉRÉ par Outils/rogner_musiques.py : gain (dB) de chaque musique pour qu'elles aient toutes le même volume ressenti.\n"
                     "class_name NiveauxMusiques\n\nconst GAINS := {\n" + "\n".join(lignes) + "\n}\n")
    print("%d musiques mesurées -> Scripts/niveaux_musiques.gd" % len(lignes))


if __name__ == "__main__":
    main()
