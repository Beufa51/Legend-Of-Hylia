extends Node
# Mémoire de la partie (autoload "Etat" : accessible partout sous le nom Etat).
# Les "drapeaux" sont des mots (ex. "plume1") qu'on lève quand une énigme est résolue ;
# les portes écoutent ces drapeaux pour s'ouvrir.

signal drapeau_change(nom: String)   # un drapeau vient d'être levé
signal message(texte: String)        # un message à afficher à l'écran

var drapeaux := {}


func poser(nom: String) -> void:
	if nom == "" or drapeaux.get(nom, false):
		return
	drapeaux[nom] = true
	drapeau_change.emit(nom)


func est(nom: String) -> bool:
	return nom != "" and drapeaux.get(nom, false)


func annoncer(texte: String) -> void:
	message.emit(texte)
