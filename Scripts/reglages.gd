class_name Reglages
extends RefCounted
## Réglages du joueur : volume général et volume de la musique (0 à 10), sauvegardés dans `user://reglages.cfg`.
## Les musiques et ambiances passent par le bus « Musique » (créé ici, envoie vers « Master ») ; les bruitages restent sur « Master ».
## Appelé au démarrage par `Etat._ready` ; modifié depuis le menu pause (pause.gd, page Options).

const FICHIER := "user://reglages.cfg"
const BUS_MUSIQUE := "Musique"
const NIVEAU_MAX := 10

static var general := NIVEAU_MAX
static var musique := NIVEAU_MAX


## Crée le bus « Musique », relit le fichier de réglages et applique les volumes.
static func demarrer() -> void:
	if AudioServer.get_bus_index(BUS_MUSIQUE) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS_MUSIQUE)
		AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK:
		general = clampi(int(cfg.get_value("audio", "general", NIVEAU_MAX)), 0, NIVEAU_MAX)
		musique = clampi(int(cfg.get_value("audio", "musique", NIVEAU_MAX)), 0, NIVEAU_MAX)
	appliquer()


## Applique les deux niveaux aux bus (0 = muet, 10 = volume normal).
static func appliquer() -> void:
	_regler_bus("Master", general)
	_regler_bus(BUS_MUSIQUE, musique)


static func _regler_bus(nom: String, niveau: int) -> void:
	var i := AudioServer.get_bus_index(nom)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, niveau <= 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(niveau, 1) / float(NIVEAU_MAX)))


## Change un niveau (« general » ou « musique ») de `pas` crans, l'applique et le sauvegarde. Renvoie le nouveau niveau.
static func changer(nom: String, pas: int) -> int:
	if nom == "general":
		general = clampi(general + pas, 0, NIVEAU_MAX)
	else:
		musique = clampi(musique + pas, 0, NIVEAU_MAX)
	appliquer()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "general", general)
	cfg.set_value("audio", "musique", musique)
	cfg.save(FICHIER)
	return general if nom == "general" else musique


static func niveau(nom: String) -> int:
	return general if nom == "general" else musique


## À appeler sur chaque lecteur de MUSIQUE ou d'AMBIANCE (pas sur les bruitages).
static func vers_musique(lecteur: AudioStreamPlayer) -> void:
	lecteur.bus = BUS_MUSIQUE
