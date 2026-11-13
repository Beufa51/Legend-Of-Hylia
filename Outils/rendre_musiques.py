"""Outil de développement : transforme les fichiers MIDI de `Assets/Midi files/` en OGG jouables par Godot (`Assets/Musique/`).
Godot ne sait PAS lire les .mid : on les « joue » avec FluidSynth + la banque de sons FluidR3_GM, puis ffmpeg les compresse en OGG.
Prérequis (Linux) : apt-get install fluidsynth fluid-soundfont-gm ffmpeg.   Usage : python3 Outils/rendre_musiques.py"""
import os, re, subprocess, tempfile

RACINE = os.path.join(os.path.dirname(__file__), "..", "Assets")
SOURCE = os.path.join(RACINE, "Midi files")
SORTIE = os.path.join(RACINE, "Musique")
BANQUE = "/usr/share/sounds/sf2/FluidR3_GM.sf2"

os.makedirs(SORTIE, exist_ok=True)
for f in sorted(os.listdir(SOURCE)):
    m = re.match(r"(\d+)\.\s*(.*?)(?: MIDI)?\.mid$", f)
    if not m:
        continue
    slug = re.sub(r"[^a-z0-9]+", "_", m.group(2).lower()).strip("_")
    sortie = os.path.join(SORTIE, "%s_%s.ogg" % (m.group(1), slug))
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "m.wav")
        subprocess.run(["fluidsynth", "-ni", "-q", "-g", "0.8", "-F", wav, "-r", "44100", BANQUE, os.path.join(SOURCE, f)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "2", sortie], check=True)
    print(os.path.basename(sortie))
