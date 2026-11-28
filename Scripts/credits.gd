class_name Credits
extends RefCounted
## Texte de l'écran Crédits (menu pause > Options > Crédits). À compléter / corriger ici.
## Le fichier `Assets/Heros/garde_lpc_credits.txt` (bouton « Crédits (TXT) » du générateur LPC) est ajouté à la fin s'il existe :
## l'attribution des éléments LPC est OBLIGATOIRE.

const FICHIER_LPC := "res://Assets/Heros/garde_lpc_credits.txt"

const LIGNES := [
	"— Merci à tous les créateurs —",
	"",
	"Musiques, bruitages et personnages :",
	"pack « Ninja Adventure » de Pixel-boy (CC0)",
	"",
	"Décors du village et de la forêt :",
	"« Pixel Crawler » (Anokolisa)",
	"« Village Top Down » (Jadson Holanda)",
	"pack « Aesthetic base set (Free) »",
	"",
	"Décors des salles de la Forteresse :",
	"pack donjon de Craftpix.net",
	"",
	"Héros :",
	"personnage composé avec le Universal LPC",
	"Spritesheet Character Generator",
	"(Liberated Pixel Cup et ses auteurs)",
	"",
	"Illustrations (statues, façades, objets, coq) :",
	"générées avec Gemini (Google), retravaillées",
	"",
	"Musiques MIDI : pack de 28 morceaux, rendus par synthèse",
	"« First Light in the Village » : musique du village",
	"",
]


## Tout le texte à afficher (la liste ci-dessus + le fichier LPC s'il est présent).
static func texte() -> String:
	var t := "\n".join(LIGNES)
	t += "\nPersonnages du village (Super Retro World, crédit obligatoire) :\nGif (@gif_not_jif), Noiracide (@Noiracide), Romi (@DessRomaric)\n"
	if FileAccess.file_exists(FICHIER_LPC):
		t += "\nCrédits LPC :\n" + FileAccess.get_file_as_string(FICHIER_LPC).strip_edges() + "\n"
	return t
