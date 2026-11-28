class_name Decors
# CATALOGUE des décors qu'on achète chez Rosine (boutique.gd) et qu'on place dans la maison du héros (decoration.gd).
# Les décors possédés sont dans Etat.decors : [{ "id": "chaise", "x": 9, "y": 9 }, ...] ; x = -1 : rangé dans la malle.
# Les cases (x, y) sont celles de l'écran InterieurHeros (25 x 14 cases).

# id -> nom affiché, image (Assets/Gemini/tuiles/), emprise en cases, bloque le passage ?, prix en rubis, nombre maximum, petite description
const CATALOGUE := {
	"pot":          {"nom": "Pot de terre",     "image": "v_pot",             "emprise": Vector2i(1, 1), "bloque": true,  "prix": 5,  "max": 4, "texte": "Un pot tout simple. On a envie de le casser... mais non !"},
	"pot_fleurs":   {"nom": "Pot de fleurs",    "image": "v_pot_fleurs",      "emprise": Vector2i(1, 1), "bloque": true,  "prix": 12, "max": 4, "texte": "Des fleurs du jardin d'Anselme. Ça sent bon !"},
	"seau":         {"nom": "Seau",             "image": "v_seau",            "emprise": Vector2i(1, 1), "bloque": true,  "prix": 6,  "max": 2, "texte": "Un seau d'eau du puits."},
	"chaise":       {"nom": "Chaise",           "image": "v_chaise",          "emprise": Vector2i(1, 1), "bloque": true,  "prix": 8,  "max": 4, "texte": "Pour s'asseoir après une longue épreuve."},
	"tonneau":      {"nom": "Tonneau",          "image": "v_tonneau",         "emprise": Vector2i(1, 1), "bloque": true,  "prix": 10, "max": 3, "texte": "Plein de pommes de la ferme."},
	"caisse":       {"nom": "Caisse",           "image": "v_caisse2",         "emprise": Vector2i(1, 1), "bloque": true,  "prix": 8,  "max": 3, "texte": "Une caisse de bois solide."},
	"foin":         {"nom": "Botte de foin",    "image": "v_foin",            "emprise": Vector2i(1, 1), "bloque": true,  "prix": 7,  "max": 2, "texte": "Les poules adorent. Toi un peu moins."},
	"tapis_rouge":  {"nom": "Tapis rouge",      "image": "v_tapis_rouge",     "emprise": Vector2i(3, 2), "bloque": false, "prix": 20, "max": 2, "texte": "Un tapis doux. On peut poser des meubles dessus."},
	"tapis_rond":   {"nom": "Grand tapis rond", "image": "v_tapis_rond",      "emprise": Vector2i(3, 3), "bloque": false, "prix": 30, "max": 1, "texte": "Le tapis des grandes maisons du royaume."},
	"banniere":     {"nom": "Bannière du coq",  "image": "v_banniere",        "emprise": Vector2i(1, 2), "bloque": false, "prix": 30, "max": 2, "texte": "Le coq doré du village, fier sur son drap rouge."},
	"banc":         {"nom": "Petit banc",       "image": "v_banc",            "emprise": Vector2i(2, 1), "bloque": true,  "prix": 15, "max": 2, "texte": "Un banc de bois pour deux."},
	"table_ronde":  {"nom": "Table ronde",      "image": "v_table_ronde",     "emprise": Vector2i(2, 2), "bloque": true,  "prix": 25, "max": 2, "texte": "La table des repas de famille."},
	"coffre":       {"nom": "Coffre",           "image": "v_coffre",          "emprise": Vector2i(2, 2), "bloque": true,  "prix": 35, "max": 1, "texte": "Un beau coffre ferré."},
	"mannequin":    {"nom": "Mannequin d'armure", "image": "v_mannequin",     "emprise": Vector2i(1, 2), "bloque": true,  "prix": 45, "max": 1, "texte": "Comme à la caserne. Tu t'y crois déjà !"},
	"etagere":      {"nom": "Étagère",          "image": "v_etagere",         "emprise": Vector2i(3, 2), "bloque": true,  "prix": 40, "max": 1, "texte": "Des livres, des pots, des souvenirs."},
	"table":        {"nom": "Grande table",     "image": "v_table",           "emprise": Vector2i(4, 2), "bloque": true,  "prix": 50, "max": 1, "texte": "Assez grande pour inviter tout le village."},
	"armoire":      {"nom": "Armoire",          "image": "v_armoire",         "emprise": Vector2i(2, 3), "bloque": true,  "prix": 60, "max": 1, "texte": "Une grande armoire de chêne."},
	"ratelier":     {"nom": "Râtelier de lances", "image": "v_ratelier_lances", "emprise": Vector2i(4, 2), "bloque": true, "prix": 70, "max": 1, "texte": "Le rêve de toute recrue de la Garde."},
	"lit_bleu":     {"nom": "Lit d'ami",        "image": "v_lit_bleu",        "emprise": Vector2i(2, 3), "bloque": true,  "prix": 80, "max": 1, "texte": "Pour recevoir un ami... ou un soldat fatigué."},
}

# Ce qui n'est pas un meuble : on l'achète une seule fois, ça agrandit la maison (drapeau « maison_agrandie »).
const AGRANDIR := "agrandir"
const PRIX_AGRANDIR := 150
const DRAPEAU_AGRANDIE := "maison_agrandie"

# L'ordre des articles dans la boutique (du moins cher au plus cher, l'agrandissement à la fin)
const ORDRE := ["pot", "seau", "foin", "chaise", "caisse", "pot_fleurs", "tonneau", "banc", "tapis_rouge", "table_ronde",
	"tapis_rond", "banniere", "coffre", "etagere", "mannequin", "table", "armoire", "ratelier", "lit_bleu", AGRANDIR]

# Les meubles de départ de la maison (ceux de Maman) : déplaçables dès le début du jeu.
const DEPART := [["tapis_rouge", 9, 7], ["table_ronde", 7, 8], ["chaise", 9, 9], ["tonneau", 16, 7], ["pot", 13, 5]]


# Combien d'exemplaires de ce décor le joueur possède (placés ou dans la malle).
static func nombre(id: String) -> int:
	var n := 0
	for d in Etat.decors:
		if d["id"] == id:
			n += 1
	return n


# Les meubles de Maman, la première fois qu'on entre dans la maison.
static func preparer() -> void:
	if Etat.est("decors_init"):
		return
	for d in DEPART:
		Etat.decors.append({"id": d[0], "x": d[1], "y": d[2]})
	Etat.noter("decors_init")   # (sauvegarde aussi les décors)
