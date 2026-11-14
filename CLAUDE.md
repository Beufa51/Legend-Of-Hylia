# Mémoire du projet : jeu Godot "Épreuve de la Garde" (titre provisoire)

> Ce fichier sert de mémoire à Claude d'une session à l'autre. Il est lu automatiquement
> par Claude Code à chaque session. À mettre à jour après chaque étape importante.

## Contexte utilisateur
- Débutant complet sur Godot → guider **pas à pas**, expliquer chaque manipulation dans l'éditeur.
- Claude ne peut pas ouvrir l'éditeur Godot : l'utilisateur fait les manipulations dans l'éditeur,
  Claude écrit le GDScript, les fichiers et explique.
- Projet hébergé sur GitHub (comme les précédents projets de l'utilisateur).
- Langue de travail : français.

## Règles absolues
- **0 coût** : uniquement l'abonnement Claude existant. Pas d'API payante, pas de service facturé à l'usage.
- **Godot 4.x**, GDScript uniquement, pas de plugin/dépendance externe.
- Code simple, propre, modulaire, commenté en français. Pas de sur-ingénierie.
- **Économie du quota Claude** : à la fin de chaque réponse importante, indiquer
  1) s'il faut faire `/clear` maintenant (après une étape terminée ET notée dans ce fichier),
  2) quel modèle utiliser pour l'étape suivante (`/model`) :
     - **Haiku** : petites questions, où trouver un menu, vérif rapide, renommer, typo.
     - **Sonnet** (défaut recommandé) : guidage pas à pas, écrire/modifier du GDScript courant.
     - **Opus** : conception (énigmes, architecture des salles), bug coriace, cinématique du blason.
  Toujours mettre à jour ce fichier AVANT de conseiller un `/clear`.
- Réponses courtes et ciblées, pas de répétition inutile.

## GDD résumé (version 1, fournie par l'utilisateur)
- **Genre** : action-aventure 2D top-down, esprit "Link's Awakening". **Zéro combat** :
  exploration, observation, énigmes logiques et spatiales.
- **Pitch** : une recrue de la garde royale passe son examen d'adoubement via un mini-donjon d'énigmes.
- **Donjon en forme de blason** (bouclier + oiseau héraldique) :
  - Entrée en bas, progression vers le haut.
  - Aile gauche : **5 salles** linéaires (une par plume du coq) reliées par couloirs, 1 énigme par salle, 1 fragment à la fin. (Changé le 2026-11-12 : 3 -> 5, car l'utilisateur voit 5 plumes par aile sur le coq.)
  - Aile droite : idem, en symétrie.
  - Convergence (corps + tête) : épreuve finale une fois les 2 fragments obtenus.
- **Twist** : à la fin d'une aile, cinématique où l'aile pivote et s'emboîte sur le grand blason.

## Décisions prises
- Dépôt GitHub : https://github.com/Beufa51/Legend-Of-Hylia (branche `main`). Nom à changer
  quand le titre original sera choisi (GitHub → Settings → Rename, sans perte).
- Godot **4.7.2**, moteur de rendu **Compatibilité** (obligatoire pour le web mobile).
- Caméra : **écran fixe par salle + glissement** lors du changement de salle.
- Cible : **navigateur PC + mobile** (export web) → contrôles tactiles à prévoir.
- Ordre des ailes libre, mais on construit l'**aile gauche en premier**.
- Énigmes : définies plus tard, on pose d'abord les bases (déplacement, salles, transitions).
- Assets proposés : pack **Ninja Adventure** (Pixel-boy, CC0, itch.io) — à confirmer par l'utilisateur.
- Résolution : **400x224 (tuiles 16x16, salle 25x14 tuiles, murs du bord de 2 tuiles)**, fenêtre 1200x672, stretch viewport, filtre Nearest. Le Knight reste à 16 px (scale 1, vitesse 70). (Essai à 32 px le 2026-11-12 : jugé "trop zoomé" par l'utilisateur, abandonné.) Références de style : Zelda ALttP = sol plat uni, peu de détails, gros objets simples, murs épais.
- Workflow Git : l'utilisateur utilise GitHub Desktop ; toujours "Pull" avant de travailler, "Push" après.

- Histoire : préquelle d'un garde royal (inspiré de l'esprit Zelda OoT). Noms de TRAVAIL :
  village **« Village du Coq Chantant »** (nom choisi par l'utilisateur, 2026-11-12 ; ex-Cocoricou/Chantecler), royaume **Hylio** (à changer). Ils restent trop proches de Zelda : avant toute publication
  publique, les remplacer par des noms 100 % originaux (les centraliser dans un seul fichier pour
  les changer facilement). Sinon garder le dépôt privé.
- Graphismes : pack Ninja Adventure (téléchargé) + perso créé dans un générateur (planche ~27x27 px,
  licence du générateur à vérifier ; original à mettre dans `assets/`). On fait marcher d'abord un perso
  Ninja Adventure (16x16), le perso maison viendra après si le style colle.

## Points ouverts / à décider
- [ ] Titre/univers : l'utilisateur a proposé "La Legend d'Hylia" → refusé car Hylia et
      "Legend of..." viennent de Zelda (Nintendo). Trouver un nom 100 % original.
- [ ] Contenu précis des **11 énigmes** (5 gauche, 5 droite, 1 finale).
- [ ] Graphismes : assets gratuits (CC0) ou pixel art maison ? Taille des tuiles / résolution.

- [ ] **Interactions / combat** (idée de l'utilisateur, 2026-11-12) : "ne pas pouvoir taper des pots dans Zelda est frustrant, 0 interaction". Proposition de Claude :
      (1) AJOUTER tôt des interactions SANS combat : épée/coup pour casser les pots (`V`), pousser des blocs, lire des panneaux, leviers/interrupteurs, ramasser des objets (cœurs, clés) ;
      (2) le vrai COMBAT (ennemis) seulement après les 2 ailes, si l'utilisateur le veut : cela modifie le GDD ("zéro combat"). À trancher plus tard.

## Journal des étapes
- 2026-11-12 : GDD v1 reçu, premier avis donné, questions posées. Rien de créé dans Godot encore.
- 2026-11-12 : réponses reçues (voir Décisions). Étape suivante : création du dépôt GitHub + projet Godot.
- 2026-11-12 : dépôt créé par l'utilisateur, CLAUDE.md poussé. En attente : projet Godot créé dans le dossier cloné (rendu Compatibilité).
- 2026-11-12 : projet Godot créé et poussé (project.godot à la racine). Réglages affichage OK.
- 2026-11-12 : rendu passé en gl_compatibility (aussi pour mobile). **ÉTAPE 0 TERMINÉE.**
  Astuce : le sélecteur de rendu en haut à droite n'existe pas chez l'utilisateur → passer par
  Paramètres du projet (Paramètres avancés activés) → Rendu → Moteur de rendu.

- 2026-11-12 : pack Ninja Adventure ajouté (`Assets/Ninja_adventure/`, A majuscule). Perso choisi : **Knight**
  (`Actor/Character/Knight/SeparateAnim/Walk.png` 4x4 et `Idle.png` 4x1, cases 16x16, colonnes = bas, haut, gauche, droite).
- 2026-11-12 : écrits (non testés dans Godot) : `Scripts/player.gd` (animations construites en code),
  `Scenes/player.tscn`, `Scenes/test_room.tscn` (scène principale), actions move_left/right/up/down
  (flèches + WASD physique, donc ZQSD en AZERTY) dans project.godot.

- 2026-11-12 : **ÉTAPE 2 TERMINÉE** : le Knight se déplace et s'anime dans la salle de test (testé par l'utilisateur).
  Le sprite Knight est provisoire : l'utilisateur voudra peut-être un autre perso plus tard (perso maison
  ~27x27 ou autre du pack). Le script player.gd construit les animations en code : changer de perso = changer DOSSIER.

- 2026-11-12 : **ÉTAPE 3 écrite (non testée)** : `Scripts/room.gd` (salle 20x11 tuiles dessinée/collisions depuis un plan texte
  `layout`, `#`=mur, `.`=sol, ouverture au bord = porte, `grille` = position dans le donjon), `Scripts/world.gd`
  (caméra fixe par salle + glissement 0.6 s, joueur figé pendant), `Scenes/room.tscn`, `Scenes/world.tscn`
  (SalleA (0,0) porte à droite, SalleB (1,0) porte à gauche) = nouvelle scène principale.
- 2026-11-12 : pack complet poussé par l'utilisateur. room.gd utilise maintenant de vraies tuiles :
  `Backgrounds/Tilesets/Interior/TilesetInteriorFloor.png`, sol (12,7), mur (12,13) (colonne, ligne de 16 px).

- 2026-11-12 : **ÉTAPE 3 TERMINÉE** (testée par l'utilisateur) : salles + murs + caméra avec glissement fonctionnent.
  LEÇON : `draw_texture_rect_region` dans `_draw()` affichait du BLANC sur le PC de l'utilisateur (GT 740M,
  OpenGL 3.3, Compatibilité). Solution : décor fait de `Sprite2D` (region_enabled) ; éviter le dessin direct
  de textures en `_draw`. Rendu actuel peu esthétique (sol uni vert-gris + mur) : à améliorer plus tard.

- 2026-11-12 : **ÉTAPE 4 écrite (non testée)** : `Scenes/world.tscn` réécrit = aile gauche en colonne x=0, de bas en haut :
  Entree (0,0) -> Salle1 (0,-1) -> Couloir1 (0,-2) -> Salle2 (0,-3) -> Couloir2 (0,-4) -> Salle3 (0,-5, cul-de-sac = futur fragment).
  Chaque couloir = un écran entier (passage de 2 tuiles) → world.gd/room.gd inchangés. Joueur démarre dans Entree (160,140).
  Salles 1-3 ont des piliers/blocs provisoires (futurs emplacements d'énigmes).

- 2026-11-12 : **ÉTAPE 4 TERMINÉE** (testée par l'utilisateur, ça marche). Travail sur la branche `etape-4-aile-gauche`
  (à fusionner dans `main` via GitHub Desktop : Branch → Merge into current branch, depuis `main`, puis Push).
  L'utilisateur ne comprend pas les Pull Requests : ne pas en parler, utiliser seulement le merge local.

- 2026-11-12 : **ÉTAPE 5a écrite (non testée)** : décor amélioré dans `room.gd` (sol avec motifs rares étoile (14,11) / fissure (11,10),
  ombre sous les murs via ColorRect, fonctions `_tuile_sol` et `_poser_tuile`). Aperçu vérifié en image côté Claude, pas dans Godot.

- 2026-11-12 : retour utilisateur sur 5a : "mieux mais loin des jeux SNES classiques". **ÉTAPE 5b écrite (non testée)** : `room.gd` utilise
  maintenant le cadre vert de `TilesetWallSimple.png` (coins/bords biseautés, origine (5,6)) pour les murs reliés au bord de la salle,
  noir (`COULEUR_VIDE`) pour les murs épais, brique sombre pour les piliers isolés. Autotile par voisins (`_piece_cadre`). Aperçu PIL vérifié seulement.
  Idées suivantes pour le look SNES : torches/statues/tapis (Elements.png, TilesetInterior.png), trappe ronde 2x2 du cadre, portes avec encadrement.

- 2026-11-12 : retour sur 5b : "un peu mieux, portes horribles, ajouter torches et détails". **ÉTAPE 5c écrite (non testée)** : `room.gd` :
  portes = bord de mur continu (on ignore les voisins le long du bord) + case de porte assombrie ; torches animées (FX/Particle/Fire.png,
  images 3-6, colonnes 3 et 16 du mur du haut) ; bannières rouges (TilesetHouse.png, colonnes 6 et 13). Pas de torche dans le pack : support dessiné en ColorRect.
  Question utilisateur : sprites fixes via Gemini ? Réponse : oui pour images fixes (blason, fragments, écran titre, accessoires uniques),
  pas pour persos/animations ; garder Ninja Adventure pour tuiles/persos (cohérence). Tester d'abord 1 image avant d'en commander plusieurs.

- 2026-11-12 : retour 5c : "mieux". DÉCISION : tester Gemini (images fixes) quitte à remplacer tous les décors du pack. Prompts donnés à l'utilisateur
  (style commun + sol, murs, accessoires, porte). Fonds magenta #FF00FF pour la transparence ; images à ranger dans `Assets/Gemini/`.
  Claude devra ensuite : nettoyer/réduire (Python PIL, nearest, palette), découper en tuiles 16x16, adapter `room.gd`. Le perso Knight reste du pack Ninja Adventure.

- 2026-11-12 : **ÉTAPE 5d en cours** : 5 planches Gemini reçues (portes, accessoires, blocs, sols A, sols B), classées dans `Assets/Gemini/originaux/`
  (JPG 1408x768, ~55 pixels d'art par tuile = trop fin pour du 16 px). Outils (hors jeu, Python+PIL, dossier `Outils/` ignoré par Godot) :
  `decouper.py` (détecte les cases), `traiter_gemini.py [taille]` (découpe + réduit + magenta->transparent) -> `Assets/Gemini/tuiles/` (32 px, 43 fichiers)
  et `tuiles16/` (16 px). Aperçus : `Outils/apercus/salle_tuiles32.png` et `salle_tuiles16.png`. Constat : à 32 px c'est net et très SNES ; à 16 px c'est flou.
  MANQUE : planche des BORDS DE MURS (bords, coins ext/int) -> à regénérer ; le mur plein (`mur_plein`) sert provisoirement.
  DÉCISION À PRENDRE par l'utilisateur : passer à tuiles 32 px (écran 640x352, Knight agrandi x2 dans la scène) [recommandé] ou rester en 16 px.
  Si 32 px : modifier project.godot (viewport), room.gd (TUILE=32, TAILLE_SALLE), world.gd, player (scale 2), puis brancher les tuiles Gemini.

- 2026-11-12 : utilisateur choisit **32 px**. **ÉTAPE 5d écrite (non testée dans Godot, aperçu PIL vérifié)** : planche de murs Gemini reçue (`originaux/murs.jpg`),
  découpée en liserés/coins (`mur_bord_n/s/e/o`, `mur_coin_*`, `mur_dot_*` + `mur_fond`). `room.gd` RÉÉCRIT : tuiles 32 px, images individuelles de
  `Assets/Gemini/tuiles/` (cache statique `_image`), murs = fond sombre + liserés côté sol (autotile par voisins), piliers = `dalle_unie`,
  lettres du plan : `T` tapis, `B` brasero (animé), `S` statue chevalier, `O` statue oiseau, `V` vase (S/O/B/V/# bloquent), torches animées (colonnes 3 et 16), bannières (6 et 13).
  `world.gd` TAILLE_SALLE (640,352), `project.godot` viewport 640x352 / fenêtre 1280x704, joueur scale 2 + vitesse 140 + départ (320,280). L'Entrée a un tapis, braseros, statues, vases.
  Outils Python (dossier `Outils/`, ignoré par Godot) : `traiter_gemini.py` refait toutes les tuiles depuis `Assets/Gemini/originaux/`.
  Portes Gemini (`porte_*.png`) NON branchées (cases de porte = simple passage assombri) ; sols A, blocs fléchés, interrupteurs etc. disponibles pour les énigmes.
  PI : l'utilisateur voulait l'oiseau rouge de Zelda comme emblème. DÉCISION (2026-11-12) : on crée DÈS MAINTENANT un oiseau héraldique ORIGINAL
  (même esprit, forme différente, proposé : coq héraldique ailes déployées, symétrique) pour éviter un gros remplacement plus tard. Ne jamais donner
  à Gemini l'image du blason Zelda (fichier de référence supprimé du dépôt). Les noms Cocoricou/Hylio restent à remplacer avant publication.
  Le donjon a la forme de l'oiseau : aile gauche (3 salles) / aile droite (3 salles) / corps + tête = convergence.

- 2026-11-12 : test 32 px OK techniquement (bug .tscn corrigé : pas de commentaire `#` dans un .tscn), mais "trop zoomé, pas l'esprit Zelda". L'utilisateur a donné une capture
  d'Zelda ALttP (sol plat bleu-gris, murs épais, Link petit). **ÉTAPE 5e écrite (non testée dans Godot, aperçu PIL fidèle)** : retour à **16 px**, salle 25x14, viewport 400x224,
  murs de 2 tuiles, portes de 3 tuiles (colonnes 11-13), sol plat `sol_plat` (généré par `traiter_gemini.py`), fond de mur en briques (`mur_fond`), `EPAISSEUR=2` dans room.gd,
  torches/bannières sur la 2e ligne de mur. `Outils/traiter_gemini.py` : 16 px par défaut (Lanczos + renforcement), sortie unique `Assets/Gemini/tuiles/`. Les 6 plans de world.tscn
  ont été régénérés en 25x14. Piliers = `dalle_unie` (provisoire). Emblème coq : en attente du choix de l'utilisateur.

- 2026-11-12 : **ÉMBLÈME CHOISI** : coq héraldique, variante **en bas à gauche** des 4 générées (`Assets/Gemini/originaux/embleme_coq_4variantes.jpg`),
  queue en flammes, corps = écu. L'utilisateur voulait MOINS de plumes (limite Gemini atteinte) : simplifié par code (fermeture morphologique 9 px sur les ailes seulement,
  ~3 plumes par aile) -> `Assets/Gemini/embleme/coq_rouge.png` (RGBA 608x324, rouge 168,20,40). Lisible jusqu'à ~64 px de large. (Attention : j'avais d'abord pris
  la variante en bas à droite par erreur ; l'utilisateur a corrigé.) À valider par l'utilisateur ; sinon redemander une variante à Gemini quand la limite sera levée.

- 2026-11-12 : retour 5e : capture Godot = sol GRIS UNI (#4a4a4a) = couleur de fond par défaut de Godot, donc l'image `sol_plat.png` (nouvelle) n'était PAS chargée (pas encore importée).
  Corrigé : `room.gd::_image` charge le PNG directement depuis le fichier si l'import manque (`Image.load_from_file`). Utilisateur : "sol pas aussi lisse que le tien (ALttP), manque de charme".
  **ÉTAPE 5f écrite (non testée)** : sol en damier discret 2 tons + biseau + points aux coins (`sol_plat`, `sol_plat_b`, variantes fissure/usure `_c`/`_d`, générés par `traiter_gemini.py`).
  Nouvel outil `Outils/apercu_salle.py <n> <sortie.png>` (aperçu d'une salle de world.tscn, même logique que room.gd). Pistes charme : lumière/ambiance, murs plus relief,
  props (colonnes rondes, braseros, blocs, cristaux), tapis colorés, variation de couleurs par salle.

- 2026-11-12 : retour 5f : "déjà mieux, manque de vie (et de musique), fais tes 4 corrections". **ÉTAPE 5g écrite (non testée dans Godot)** :
  1) props : nouvelles lettres `P` (plaque orange) et `F` (dalle à flèches) + plus de braseros/statues/vases/tapis dans les 6 plans ; 2) relief des murs : murs profonds assombris (alpha .38) ;
  3) `@export var teinte` par salle (modulate de la Room, ne touche pas le joueur) : Entrée chaude, Salle1 bleutée, Couloirs sombres, Salle2 verte, Salle3 or/violet ;
  4) lueurs additives vacillantes (GradientTexture2D radial + CanvasItemMaterial ADD) autour des torches et braseros.
  + MUSIQUE : `world.gd::_lancer_musique` joue "21 - Dungeon.ogg" (pack Ninja Adventure, `Assets/Ninja_adventure/Audio/Musics/`) en boucle, -8 dB.
  Alternatives : 12 Temple, 30 Ruins, 32 Manor. Pas de bruitages encore (dossier Audio/Sounds du pack).

- 2026-11-12 : **ÉTAPE 5 TERMINÉE** (testée par l'utilisateur : "beaucoup mieux", quelques points d'amélioration à voir plus tard). Décor Gemini 16 px, sol damier,
  murs épais, props, teintes par salle, lueurs, musique Dungeon. Coq héraldique (`Assets/Gemini/embleme/coq_rouge.png`) : validation de l'utilisateur pas encore confirmée.
  Idées d'amélioration restantes : bruitages (pas, portes), portes Gemini (`porte_*.png` non branchées), vrais piliers ronds/cristaux, prompts pixel art avec le coq
  (bannière, porte scellée, rune, grand blason, fragments). Branche `etape-4-aile-gauche` : à fusionner dans `main` (GitHub Desktop : Branch -> Merge into current branch, depuis main).

- 2026-11-12 : l'utilisateur préfère une **LANCE** (le garde royal de Zelda OoT a une lance ; piste d'origin story : la lance de la recrue/du garde, à garder pour l'histoire).
  **ÉTAPE 5h écrite (non testée dans Godot)** : coup de lance = action `attack` (Espace ou J, project.godot) ; `player.gd` : animations `attaque_*` (Attack.png), lance construite en code
  (Items/Weapons/Lance/SpriteInHand.png + Area2D, sort/rentre en ~0.26 s, immobile pendant le coup) ; `Scripts/pot.gd` (class Pot, StaticBody2D, groupe "cassable", méthode `casser()` : morceaux + bruit)
  et `room.gd` : la lettre `V` crée un Pot cassable (V retiré de SOLIDES). Bruits : Jump2.wav (lance), Impact3.wav (pot), modifiables en tête des scripts.
  À FAIRE ensuite : pots qui lâchent des objets (cœur/clé), herbe coupable, panneaux, leviers ; contrôles tactiles pour mobile (bouton d'attaque).

- 2026-11-12 : correction lance : l'image `SpriteInHand.png` a la pointe vers le BAS (pas vers le haut) -> rotation = angle - PI/2 dans `player.gd::_attaquer`. Utilisateur : "le reste est ok".

- 2026-11-12 : correction lance vue de dos : `z_index = -1` la plaçait DERRIÈRE le sol du décor (z relatif au parent = absolu -1) -> on ne voyait que le bâton. Maintenant `z_index = 1` toujours.

- 2026-11-12 : **LANCE + POTS TERMINÉS** (testés par l'utilisateur : "c'est bon pour moi", y compris la vue de dos).

- 2026-11-12 : coq : l'utilisateur compte encore 5 plumes par aile -> re-simplifié (flou gaussien sigma 5 + seuil .40 sur les ailes, ~3 lobes/plumes par aile, bords lisses) via `Outils/simplifier_coq.py [sigma] [seuil]`
  (sigma 7 = 2 gros lobes, trop mou). `Assets/Gemini/embleme/coq_rouge.png` régénéré. Validation de l'utilisateur en attente.

- 2026-11-12 : l'utilisateur voit toujours 5 plumes par aile sur le coq (même après simplification) : on ACCEPTE et on passe à **5 salles par aile** (une par plume). Le coq reste tel quel (validé de fait). `world.tscn` a encore 3 salles gauche (Entree + Salle1-3 + 2 couloirs) : à étendre à 5 salles + 4 couloirs.

- 2026-11-12 : **CONCEPT DE L'AILE (utilisateur, avec image d'une aile verticale : 5 plumes dressées, de plus en plus longues de gauche à droite, racine en bas)** :
  l'aile se présente à la VERTICALE. Plan : une SALLE D'ENTRÉE (racine de l'aile, en bas) -> une sorte de COULOIR (l'axe/épine de l'aile) qui part vers la droite -> 5 PLUMES = 5 salles allongées
  (verticales) de plus en plus LONGUES et DURES de gauche à droite (longueur de la plume = longueur/difficulté de la salle). Les énigmes doivent suivre cette progression.
  Le fragment est au bout de la plus longue plume (pointe de l'aile). Cinématique : l'aile pivote et s'emboîte sur le blason.
  Proposition de Claude (à valider) : plume n = n écrans de haut (1,2,3,4,5) ; chaque plume = une chaîne d'énigmes qui se termine à la pointe ; finir la plume n ouvre la porte n+1 sur l'épine ;
  construction INCRÉMENTALE (plume 1 d'abord, test, puis la suivante). Alternative plus compacte si trop long : 1-2-2-3-4 écrans.
  Utilisateur : veut un MÉLANGE d'énigmes, plus original que "pousser un bloc" (mais le bloc reste la base, plume 1 = didactique). Il veut BRAINSTORMER.
  Idées proposées (à voter) : 1) blocs à pousser (base) ; 2) salle SOMBRE : allumer les braseros à la lance pour révéler le chemin (lueurs déjà codées) ; 3) CHANT DU COQ : frapper des statues/cloches dans l'ordre de la mélodie entendue ;
  4) SENTINELLES : statues de garde qui tournent la tête, ne pas être vu (sans combat, retour au début de la salle) ; 5) SALLE QUI PIVOTE : un levier tourne la salle de 90° (écho du pivot de l'aile) ;
  6) POTS-INDICES : casser les pots pour trouver des symboles/clés ; 7) SALLE MIROIR (symétrie gauche/droite du blason, plutôt pour l'aile droite) ; 8) lance comme outil (actionner leviers à distance, lancer).

- 2026-11-12 : utilisateur : "ok vas-y sur tout, je corrigerai / donnerai des idées au fur et à mesure". **ÉTAPE 6a écrite (non testée dans Godot)** = PREMIÈRE TRANCHE de l'aile verticale :
  `world.tscn` REFAIT : Entrée (0,0) -> Épine1 (1,0) -> Plume1 (1,-1) ; Épine2 (2,0) provisoire (fermée). Épine = couloir horizontal (rangées 5-8) + tige vers le haut (colonnes 11-13).
  Anciennes salles (Salle1-3, Couloirs) SUPPRIMÉES. Plume1 = didactique : casser le pot (lance) -> pousser le bloc sur la plaque -> la porte de l'alcôve s'ouvre -> plume dorée -> la porte est de l'Épine1 s'ouvre.
  NOUVEAU CODE : autoload `Etat` (`Scripts/etat.gd`, drapeaux + messages, déclaré dans project.godot [autoload]) ; `bloc.gd` (class Bloc, poussable case par case) ; `porte.gd` (class Porte, dessinée en code, s'ouvre sur drapeau) ;
  `ramassable.gd` (class Ramassable, plume dorée en Polygon2D) ; `room.gd` : lettres `X` bloc, `D` porte, `G` plume, exports `drapeau_plaque` / `drapeau_porte` / `drapeau_gemme`, registre des cases occupées (`_occupe`, `case_libre`, `verifier_plaques`, `reinitialiser`) ;
  `player.gd` : groupe "joueur", poussée des blocs (0.3 s d'appui, via get_slide_collision) ; `world.gd` : touche R (action `reset`) recommence la salle, texte de message en bas d'écran (Etat.annoncer), rappel des touches au début.
  À remplacer plus tard : visuel des portes (code) -> art Gemini ; plume dorée (Polygon2D) -> vraie image ; fragment final.
  TODO suite : plumes 2 à 5 + épines 3-5 (une plume à la fois : 2 écrans de haut = 2 salles empilées en (2,-1),(2,-2)...), énigmes variées (salle sombre, chant du coq, sentinelles, salle qui pivote).

- 2026-11-12 : retours sur la plume 1 ("ça fonctionne") : 1) AJOUT d'une salle de départ **Vestibule (0,1)** sous l'Entrée (partie basse de l'aile) ; leçon : frapper le CRISTAL bleu (`K`, `cristal.gd`) à la lance ouvre la porte nord (drapeau `vestibule_cristal`).
  2) le "plaque" (flèche vers le haut) était illogique -> remplacé par un **BOUTON** de sol (`bouton` / `bouton_enfonce`, tuiles générées en PIL dans `traiter_gemini.py`) qui s'enfonce sous un bloc (`Room._maj_boutons`).
  3) PRINCIPE DE DESIGN (utilisateur, comme dans Zelda) : **chaque énigme facile enseigne une mécanique** (Vestibule = lance/cristal ; Plume 1 = pot -> pousser un bloc -> bouton). À respecter pour la suite.
  4) SON à chaque résolution d'énigme et chaque plume : `world.gd::_jouer_jingle` (Success2.wav pour un drapeau d'énigme, LevelUp2.wav si le drapeau commence par "plume") ; le cristal ne joue plus de son propre bruit.
  5) Nouveau `Outils/generer_monde.py` : ÉCRIT `Scenes/world.tscn` (modifier les plans LÀ, pas dans le .tscn). Nouvelle API : `Etat.poser/est/annoncer`, groupe "frappable" (méthode `frapper()` : pots, cristaux).
  6) NOMS : `Scripts/noms.gd` (class Noms : TITRE_JEU, VILLAGE, ROYAUME) = SEUL endroit des noms. Village = "le village du coq qui chante" (une poule caquette, c'est le COQ qui chante !) -> proposé **Chantecler**
  (nom du coq dans le Roman de Renart, domaine public, "chante clair"). "Cocoricou" abandonné : trop proche de "Cocorico" = Kakariko en français. Alternatives : Chantecoq. À valider.

- 2026-11-12 : clin d'œil voulu par l'utilisateur : le village du coq chantant = hommage au coq volant de Link's Awakening (easter egg assumé, mais NOMS et dessins restent originaux). Idées : girouette/statue de coq au village et dans le donjon,
  chant du coq (son) comme fanfare finale, énigme "le chant du coq" (frapper des cloches/statues dans l'ordre d'une mélodie). NOM DU VILLAGE CONFIRMÉ : « Village du Coq Chantant » (dans `Scripts/noms.gd`).

- 2026-11-12 : utilisateur : "construis la plume 2 avec la salle sombre ; le cristal doit faire quelque chose (ouvrir la porte de la prochaine salle) et il faut un bruit quand on l'active". **ÉTAPE 6b écrite (non testée dans Godot)** :
  FEEDBACK : cristal = bruit (Magic2.wav) ; toute porte qui s'ouvre = bruit (Impact5.wav) + secousse d'écran (`Etat.secousse`) ; si la porte est dans une AUTRE salle que celle de la caméra (`Etat.salle_courante`), message "Un bruit sourd : une porte s'est ouverte quelque part...".
  PLUME 2 (2 écrans) : **Plume2a (2,-1) SALLE SOMBRE** : 4 braseros `L` (`brasero.gd`, class Brasero) à allumer à la lance, s'éteignent après 14 s (`duree_braseros`), il faut TOUS les allumer en même temps (clignotent les 3 dernières secondes) -> `drapeau_braseros` "p2_braseros"
  ouvre la porte du haut. **Plume2b (2,-2)** : le cristal `K` ouvre la porte de l'alcôve ("p2_cristal") ; la plume dorée (drapeau "plume2") ouvre la porte est de l'Épine2 (-> Épine3 (3,0), provisoire, fermée).
  OBSCURITÉ : `@export var sombre` dans Room ; `world.gd::_regler_obscurite` (CanvasModulate global, COULEUR_NUIT, tween 0.4 s) + lumière du joueur (`player.regler_lumiere`, PointLight2D) ; `lumiere.gd` (class Lumiere.creer) fabrique les PointLight2D ; pas de torches/bannières dans une salle sombre.
  Nouvelle tuile `brasero_eteint` (flamme effacée, générée par `traiter_gemini.py`). `Outils/generer_monde.py` reste la source de `world.tscn` (modifier les plans LÀ).
  Leçons de design : chaque énigme enseigne UNE mécanique (vestibule = lance/cristal ; plume 1 = pot + bloc + bouton ; plume 2 = la lance allume, il faut s'organiser dans le noir).
  Risque à vérifier au test : Light2D en rendu Compatibilité (devrait marcher), lisibilité des braseros éteints dans le noir (CanvasModulate 0.13,0.14,0.24).

- 2026-11-12 : retour sur 6b : "ça fonctionne, un peu trop lumineux ; les portes sont très laides ; une fois l'aile finie on REVOIT les énigmes et la difficulté, là on TERMINE l'aile".
  **ÉTAPE 6c écrite (non testée)** : nuit plus noire (`COULEUR_NUIT` (0.05,0.055,0.11), lumière du joueur 0.6/0.7, braseros éteints = petite braise pour les repérer) ; PORTES refaites : double battant de bois cerclé de fer dans un cadre de pierre,
  images `porte_48x32` / `porte_48x16` / `porte_32x64` générées en pixels par `traiter_gemini.py` ; UNE `Porte` par groupe de cases `D` voisines (`Room._poser_portes`, taille = boîte englobante) ; dans les plans, les portes du haut/bas font 3x2 cases (rangées 0-1),
  les portes latérales 2x4 (colonnes 23-24), les portes intérieures 3x1. À RE-TESTER : lisibilité du noir, esthétique des portes. DÉCISION : finir d'abord toute l'aile (plumes 3, 4, 5), puis rééquilibrer énigmes/difficulté.

- 2026-11-12 : retour 6c : "le noir c'est OK ; les portes sont mal mises, on dirait une TRAPPE, pas très beau". Cause : une grande plaque de bois à plat dans une encoche du mur = trappe.
  **CORRECTION 6d (non testée)** : portes = **GRILLES DE FER (herses)** à barreaux sur fond sombre, cadre de pierre (`porte_48x32`, `porte_48x16`, `porte_16x64`, générées par `traiter_gemini.py::fabrique_grille`) ;
  la porte latérale ne fait plus qu'1 colonne de large (colonne 23, rangées 5-8) ; à l'ouverture la grille SE RELÈVE (scale:y -> 0, ou scale:x -> 0 pour la porte étroite) au lieu de s'effacer.
  NB : la session a été longue ; recommandation donnée à l'utilisateur de faire `/clear` puis `/model` Opus avant la conception des plumes 3-5.

- 2026-11-12 : retour 6d : "mieux pour les grilles, mais le HAUT de la grille fait bizarre : on ne sait pas si la grille est coupée ou si c'est le plafond". Cause : la grille touchait le bord haut de l'écran avec un linteau fin de 4 px.
  **CORRECTION 6e (non testée dans Godot, aperçu PIL vérifié)** : `traiter_gemini.py::fabrique_grille(w, h, linteau)` : GROS linteau de briques (11 px pour la porte 48x32, 6 px pour 48x16) avec lumière en haut et ombre portée sur les barreaux,
  montants de briques, fond d'embrasure dégradé ; la porte latérale (16x64) n'a que des montants (linteau 0).

- 2026-11-12 : **PLAN DES PLUMES 3-5 VALIDÉ** par l'utilisateur (1 mécanique nouvelle par plume ; 1er écran = leçon, suivants = complication, dernier = combinaison) :
  - Plume 3 (3 écrans, colonne x=3) « LE CHANT DU COQ » : frapper la statue du coq -> mélodie, chaque cloche s'illumine sur sa note ; rejouer la mélodie sur les cloches.
    3a = 3 cloches/3 notes (leçon) ; 3b = 4 notes, une cloche dans une niche derrière un bloc ; 3c = SOMBRE, 5 notes, ouvre l'alcôve de la plume.
  - Plume 4 (4 écrans, x=4) « LES SENTINELLES » : statues de garde, cône de regard visible au sol. Vu = alerte + **un garde te RACCOMPAGNE À L'ENTRÉE DE LA PLUME** (choix de l'utilisateur, pas de dégâts).
    4a = 1 sentinelle fixe + piliers ; 4b = 2 sentinelles qui tournent à des rythmes différents ; 4c = se cacher derrière un bloc poussé ; 4d = sombre, allumer un brasero révèle les cônes mais attire les regards.
  - Plume 5 (5 écrans, x=5, pointe de l'aile) « LE PIVOT » : rayon de lumière + miroirs qui pivotent de 90° d'un coup de lance -> guider le rayon vers une cible.
    5a = 1 miroir ; 5b = 2 miroirs + faux chemin ; 5c = un bloc coupe/laisse passer le rayon ; 5d = sombre (le rayon éclaire) ; 5e = salle finale (miroirs + bloc + mélodie) -> FRAGMENT D'AILE en (5,-5).
  - Alternative gardée en réserve : plots qui basculent orange/bleu au coup de cristal (façon ALttP).
- 2026-11-12 : **ÉTAPE 6f écrite (non testée dans Godot)** = PLUME 3. Nouveau : `Scripts/cloche.gd` (class Cloche, lettres `1`-`5` = note, dessinée en code, taille selon la note, son `Bonus/Coin.wav` avec `pitch_scale`
  gamme pentatonique `HAUTEURS`, anti-répétition 400 ms car la lance frappe à chaque image) ; `Scripts/chanteur.gd` (class Chanteur, lettre `C`, image `statue_oiseau`) ; `room.gd` : exports `melodie`, `drapeau_melodie`, `indice`,
  `jouer_melodie()` (0.6 s par note), `cloche_frappee()` (fausse note = cloches rouges + `Menu/Cancel.wav`, on recommence) ; `world.gd::_montrer_indice` (message à la 1re visite d'une salle, sans drapeau donc sans jingle).
  `generer_monde.py` : Épine3 (3,0) porte est = drapeau `plume3` -> Épine4 (4,0) provisoire fermée ; Plume3a (3,-1) « 132 », Plume3b (3,-2) « 2413 », Plume3c (3,-3) sombre « 31524 » + plume dorée.
  Drapeaux : p3_chant1, p3_chant2, p3_chant3, plume3. Godot n'a pas pu être lancé côté Claude (non autorisé) : code relu à la main seulement.

- 2026-11-12 : **PLUME 3 TESTÉE : "ça fonctionne"**. Demande : fonction COURIR.
- 2026-11-12 : **ÉTAPE 6g écrite (non testée dans Godot)** = COURSE + PLUME 4 « LES SENTINELLES ».
  COURSE : action `run` (Maj ou K) dans project.godot ; `player.gd` : vitesse x `FACTEUR_COURSE` (1.7), animation plus rapide.
  SENTINELLES : `Scripts/sentinelle.gd` (class Sentinelle, lettres `^ v < >`, image `statue_chevalier` + triangle « œil », quart de tour horaire toutes les `periode` s, clignote 0.6 s avant).
  `room.gd` : exports `periodes_sentinelles` (PackedFloat32Array, ordre de lecture du plan), `retour` (Vector2, position monde), `drapeau_repos` (sentinelles endormies) ;
  `_surveiller` (seulement dans la salle courante), `_cases_vues` = cône portée 7 (largeur 1, 3, 3, puis 5), arrêté par `_opaque` (#SOBK + tout ce qui est dans `_occupe` : blocs, pots, portes, braseros...),
  `_dessiner_regards` (draw_rect jaune translucide sur un calque, signal draw), pieds du joueur dans une case vue -> `Etat.repere.emit(retour)`.
  Une FLAMME allumée attire le regard : chaque sentinelle fixe le brasero `L` allumé le plus proche. `verifier_braseros` ne fait rien si `drapeau_braseros` est vide (braseros « leurres »).
  `world.gd::_raccompagner` : alerte (Alert/Alert.wav), message, fondu au noir (`_fondu`), joueur ramené à `retour`, salle remise à zéro (blocs, sentinelles, braseros), fondu retour.
  SALLES : Plume4a (4,-1) 1 sentinelle fixe, passer dans l'ombre du pilier ; Plume4b (4,-2) 2 sentinelles qui tournent (2 s et 3 s) ; Plume4c (4,-3) couloir surveillé, pousser le bloc devant soi ;
  Plume4d (4,-4) SOMBRE : allumer les 2 braseros pour que chaque sentinelle regarde de son côté, puis monter vers la plume (drapeau `plume4`, qui endort aussi les sentinelles des 4 salles).
  Retour = Vector2(1800, -30) (bas de 4a). Épine4 porte est = `plume4` -> Épine5 (5,0) provisoire fermée.
  Outil `Outils/simuler_sentinelles.py` : même règle de regard en Python, vérifie qu'un passage existe (4a-4d vérifiées ; 4c impossible SANS pousser le bloc, voulu).
  `generer_monde.py` : valeurs Vector2(...)/PackedFloat32Array(...)/nombres écrites sans guillemets.

- 2026-11-12 : retour utilisateur : "bug salle des cloches : taper la statue ne déclenche plus le son ; cloches et plumes moches ; il faudrait un mode développeur". **CORRECTIONS 6g2 (non testées dans Godot)** :
  1) statue chanteuse : collision sur toute la hauteur de l'image (14x26, tête comprise) -> frappable aussi par le haut (cause probable : seule la case du bas réagissait).
  2) nouvel outil `Outils/fabriquer_objets.py` -> `Assets/Gemini/tuiles/plume_doree.png` (feather.png du pack recolorée en or), `cloche_support.png`, `cloche_1..5.png` (bronze ombré, 12 à 8 px de large) ;
     `cloche.gd` utilise ces images (teintes par `modulate` : ECLAT, ROUGE, DOREE) ; `ramassable.gd` = image plume_doree + lueur + pulsation.
  3) MODE DÉVELOPPEUR : touche **F1** (seulement `OS.is_debug_build()`, donc pas dans un export final) -> menu avec un bouton par salle -> téléportation (`world.gd::_teleporter`, `Room.point_arrivee()` = case libre la plus proche de (12,11)).

- 2026-11-12 : **VRAI BUG DE LA STATUE TROUVÉ** : depuis 6g, `generer_monde.py` écrivait `melodie = 132` (nombre) au lieu de `"132"` -> Godot ne lisait pas la mélodie -> la statue ne jouait rien.
  Corrigé : seuls les nombres À VIRGULE (ex. 14.0) sont écrits sans guillemets. LEÇON : toujours vérifier `world.tscn` après une modif du générateur.
- 2026-11-12 : utilisateur : "plume 5 maintenant (Opus), corrections des plumes 3-4 après (Sonnet)". **ÉTAPE 6h écrite (non testée dans Godot, solutions vérifiées par un traceur Python)** = PLUME 5 « LE PIVOT » + FRAGMENT.
  NOUVEAU : `Scripts/miroir.gd` (class Miroir, lettres `M` = « / », `N` = « \ », frappé = pivote (anim scale:x + Whoosh2.wav), `renvoyer(dir)`) ; `Scripts/cible.gd` (class Cible, lettre `Y`, s'allume) ;
  `room.gd` : lettre `R` = soleil dans le mur (compte comme mur : `_est_mur`, `_murs_du_cadre`, SOLIDES, `_opaque`), direction = la case de sol voisine ; `_tracer_rayon()` chaque image dans la salle courante
  (rebonds sur miroirs, arrêt sur `_opaque`, max 300 cases), `_dessiner_rayon` (draw_line halo + cœur, matériau ADD, scintille), `_eclairer_rayon` (PointLight2D toutes les 2 cases en salle sombre) ;
  exports `drapeau_rayon`, `drapeau_porte2` (portes `H`, `_poser_portes_lettre`), `chanteur_au_soleil` (la statue ne chante que si le rayon l'éclaire : `statue_frappee()`, et chante d'elle-même quand le soleil arrive sur elle) ;
  lettre `W` = fragment d'aile (Ramassable avec image `fragment_aile`). `ramassable.gd::initialiser(drapeau, texte, texture = null)`. Jingle « plume » aussi pour les drapeaux `fragment*`.
  Images (Outils/fabriquer_objets.py) : `miroir_m/n`, `source_soleil`, `cible`, `cible_allumee`, `fragment_aile` (aile gauche de coq_rouge.png, 24x21).
  SALLES (colonne x=5) : Épine5 (5,0) tige ouverte, fermée à l'est (fin de l'aile). 5a (5,-1) 1 miroir ; 5b (5,-2) 3 miroirs + faux chemin (le rayon monte vers un pilier) ;
  5c (5,-3) bloc sur bouton -> porte H de la chambre du réceptacle, puis pousser le bloc DE CÔTÉ (il coupe le rayon) ; 5d (5,-4) SOMBRE, 3 miroirs + 2 leurres ;
  5e (5,-5) POINTE : dégager le bloc, 2 miroirs -> le soleil éclaire la statue -> elle chante « 3142 » -> rejouer sur les cloches -> alcôve -> FRAGMENT (drapeau `fragment_gauche`).
  **L'AILE GAUCHE EST COMPLÈTE (en code)** : vestibule, entrée, 5 épines, 15 écrans de plumes.

- 2026-11-12 : retours sur les plumes 4 et 5. **CORRECTIONS 7a écrites (non testées dans Godot)** :
  PLUME 5c : le bloc bloquait le rayon une fois sur le bouton (pas compris). REFAITE : le bloc est AU DÉPART dans le rayon (miroir `N` en (18,4), bloc (18,6)) ;
  le pousser à droite jusqu'au bouton (21,6) libère le rayon ET ouvre la grille H. Réceptacle `Y` redessiné = SOLEIL ÉTEINT sur socle (même motif que le soleil R),
  pulsation dorée tant qu'il est éteint (`cible.gd`). Indices ajoutés en 5a/5b/5c. Bug du texte « frappe le cristal » : rappel de début de partie montré seulement si on est au vestibule.
  Messages en bas d'écran : 2 lignes avec retour à la ligne automatique.
  SENTINELLES : sprite = garde GladiatorBlue du pack (teinté pierre, sur socle), il se tourne vraiment ; VRAI CÔNE de vision (façon MGS) : 24 rayons, demi-angle 26°, portée 7 cases,
  arrêté par les obstacles, rotation douce de la tête (7 rad/s), dégradé + contour, rouge si repéré ; détection = pieds du joueur dans le cône (`room.gd::_voit`, `_portee_libre`, `_cone`).
  Cônes et bulles dessinés dans un CanvasLayer (`follow_viewport_enabled`) -> visibles même dans les salles sombres. Bulles « ? » (attirée par une flamme) et « ! » (repéré), Ui/Emote du pack.
  Message unique « La flamme attire le regard de la sentinelle ! ». 4d REFAITE : sentinelles (7,7) > et (17,7) <, braseros (3,10) et (21,10) ; la rangée du bas n'est jamais vue ;
  une flamme ne suffit pas, les deux oui. `Outils/simuler_sentinelles.py` réécrit avec la même géométrie (lit `world.tscn`) : 4a, 4b, 4c (bloc poussé), 4d vérifiées.

- 2026-11-12 : corrections 7b (testées, "ça marche") : image du fragment d'aile refaite (`Outils/fabriquer_objets.py::fragment`, aile entière sans le corps du coq, centrée sur sa case dans `ramassable.gd`) ;
  rayon 5C : `room.gd::_opaque` ignore une porte `ouverte` (la grille invisible bloquait encore le rayon). Plumes 4-5 validées par l'utilisateur.

- 2026-11-12 : **ÉTAPE 7c écrite (non testée dans Godot, aperçu PIL vérifié)** = CINÉMATIQUE DE FIN D'AILE. `world.gd::_cinematique_aile(cote)` (lancée 1,6 s après le drapeau `fragment_gauche`, `_sur_drapeau`) :
  écran assombri (CanvasLayer 2 ; messages/fondu passés en calque 3), musique baissée, GRAND BLASON = coq en PIERRE grise avec les empreintes des ailes vides cerclées d'or + halo doré ;
  l'aile arrive À LA VERTICALE (racine en bas, plumes dressées = la forme du donjon), pivote d'un quart de tour autour de sa racine (TRANS_BACK = s'emboîte avec un petit dépassement),
  « clac » (Impact5) + éclair + secousse + jingle Secret2, message, puis fondu et RETOUR À L'ENTRÉE. Gère déjà l'aile droite (rotation inverse) et les 2 ailes (message « épreuve finale »).
  Images : `Assets/Gemini/embleme/blason_socle.png`, `blason_aile_gauche.png`, `blason_aile_droite.png` (244x132, `Outils/fabriquer_objets.py::blason`, pivots affichés par le script = constante `PIVOTS` de world.gd).
  Mode dev F1 : bouton « Cinématique aile gauche » pour la rejouer. Idée suivante : afficher le grand blason (progression) dans l'Entrée.

- 2026-11-12 : idée de l'utilisateur : la cinématique doit se jouer EN SORTANT DU DONJON, en VUE AÉRIENNE : le joueur découvre que le plan des salles parcourues forme une aile,
  qui pivote et rejoint le CORPS du donjon (autre donjon, pas encore construit). **ÉTAPE 7d écrite (non testée dans Godot, aperçus PIL vérifiés)** — remplace l'ancienne `_cinematique_aile` :
  1) fragment ramassé -> `world.gd::_retour_entree` (fondu, joueur posé dans l'Entrée, message « sors du donjon ») ; la GRANDE PORTE DU SUD du vestibule (porte `H`, rangées 12-13, colonnes 11-13,
  `drapeau_porte2 = fragment_gauche`, dans `generer_monde.py`) s'ouvre.
  2) le joueur sort par là (écran `SORTIE_DONJON` (0,2), détecté dans `_process`) -> `_vue_aerienne(cote)` : fond d'herbe, PLAN VU DU CIEL fabriqué EN CODE depuis les `layout` des salles
  (`_plan_vu_du_ciel` : 1 pixel par case, sol clair, murs proches du sol sombres, reste transparent ; suit automatiquement les modifs du donjon), point rouge clignotant = le joueur à la sortie ;
  messages « Vu du ciel, les salles... dessinent... une AILE ! » + liseré doré qui pulse ; zoom arrière, le CORPS du donjon (`blason_socle.png`, coq de pierre) apparaît ;
  le plan pivote d'un quart de tour autour de sa racine (centre de l'Entrée) et prend la forme de l'aile (`ECHELLE_AILE` (0.5, 1.15)) dans l'empreinte ; clac + éclair + secousse : le plan devient l'aile rouge (`blason_aile_gauche.png`).
  Puis retour dans le vestibule (le corps du donjon n'existe pas encore). Joué une seule fois (`_vue_aerienne_vue`). F1 -> « Vue aérienne aile gauche » pour la rejouer.
  À vérifier au test : aspect de la grille `porte_48x32` utilisée sur le mur du BAS (linteau côté salle).

- 2026-11-12 : vue aérienne 7d testée : « pas mal ». À TERME : l'aile doit rejoindre le VRAI bâtiment principal (corps du donjon, pas encore créé) -> refaire la fin de la cinématique quand le corps existera (pour l'instant : coq de pierre du blason).

- 2026-11-12 : **AUDIT JOUEUR de l'aile gauche** (relecture des plans et du code, pas de vraie partie) :
  BLOQUANTS/IMPORTANTS : (A) AUCUNE SAUVEGARDE : fermer le navigateur = tout perdre -> sauver `Etat.drapeaux` dans `user://` (marche aussi sur le web) ;
  (B) Plume 4 : repéré = retour en bas de 4a même depuis 4d (jusqu'à 4 écrans à refaire) -> retour au bas de l'écran COURANT ;
  (C) aller-retour : après chaque plume il faut redescendre n écrans + l'épine (jusqu'à 4 écrans à vide) -> raccourci (retour à l'épine après la plume, comme pour le fragment) ;
  (D) pas de contrôles tactiles (cible mobile) ; (E) aucune progression visible -> HUD : 5 plumes en haut de l'écran (renforce l'idée de l'aile).
  DESIGN : Plume 2b = simple cristal, redite du vestibule (à enrichir) ; épines = 5 couloirs identiques et vides ; pots vides (aucune récompense) ; 3c = 5 notes dans le noir (dur, mais on peut réécouter) ;
  rappel des touches = un seul long message de 5 s (R recommencer peu visible) ; aucune histoire / aucun PNJ (le village va le donner) ; après le fragment, plus rien à faire (aile droite absente).
  POINTS FORTS : 1 mécanique par plume avec leçon -> complication -> combinaison ; feedback sonore/visuel partout ; indices à la 1re visite ; mode dev F1.

- 2026-11-12 : choix de l'utilisateur après l'audit : corriger A, B, C, E ; carte MOYENNE (~15 écrans) ; PNJ + maisons VISITABLES.
  **CORRECTIONS 7e écrites (non testées dans Godot)** :
  A) SAUVEGARDE : `etat.gd` écrit `user://sauvegarde.json` (drapeaux + `position_sauvee`) à chaque `poser` ; `charger()` au démarrage ; `noter(nom)` = drapeau silencieux (sans jingle) ;
     `memoriser_position` à chaque entrée de salle (`_glisser_vers`), retour rapide, téléportation ; `world._ready` replace le joueur ; `room.gd` : `G`/`W` déjà ramassés ne réapparaissent pas (`"G" when ...`).
     F1 -> « Effacer la sauvegarde (nouvelle partie) » (`Etat.effacer` + rechargement). La vue aérienne est mémorisée (`vue_aerienne_gauche`).
  B) Sentinelles : `retour` = bas de l'écran COURANT (`generer_monde.py::retour_p4(n)`), message « au début de la salle ».
  C) RETOUR RAPIDE : `world.gd::_ramener(salle, case, texte)` : après plume1-4 -> épine N case (12,6) ; après le fragment -> Entrée.
  E) HUD : 5 plumes en haut à gauche (grises -> dorées), + icône du fragment ; la 5e s'allume avec le fragment ; caché pendant la vue aérienne.

- 2026-11-12 : **PROPOSITION DE CARTE EXTÉRIEURE (à valider par l'utilisateur)** : scène séparée `overworld.tscn` (même système d'écrans 400x224 + glissement), musique village/extérieur,
  passage donjon <-> extérieur = changement de scène à la porte sud du vestibule (la vue aérienne se joue à ce moment). 5 x 3 écrans :
  ```
           x=0              x=1               x=2                 x=3               x=4
  y=0   Bois (secret)    Temple aile G     Parvis + CORPS      Temple aile D     Falaise (vue)
                          (entrée donjon)   (scellé, final)     (aile droite)
  y=1   Rivière + pont   Chemin forestier  Grand chemin        Chemin            Cascade (secret)
  y=2   Ferme / champs   Village ouest     PLACE DU COQ        Village est       Maison du héros
                          (maisons, PNJ)   (statue-girouette,   (CASERNE de la     (départ du jeu)
                                            puits, marché)       Garde, capitaine)
  ```
  Intérieurs visitables (1 écran chacun, grille à part, porte = téléport) : maison du héros (départ), caserne (le capitaine lance l'épreuve), auberge/boutique.
  Début du jeu : réveil dans la maison du héros -> caserne -> le capitaine envoie à l'épreuve -> chemin vers le nord -> temple de l'aile gauche.
  Tuiles du pack : TilesetField, TilesetNature (arbres), TilesetHouse, TilesetWater, TilesetRelief (falaises) ; PNJ : OldMan/OldWoman/Child/Noble..., capitaine = KnightGold.
  Technique prévue : script `exterieur.gd` (même principe que room.gd : plan texte -> tuiles + collisions, autres lettres : herbe, chemin, arbre, eau, maison, clôture...), `pnj.gd` + boîte de dialogue.

- 2026-11-12 : carte validée par l'utilisateur. **ÉTAPE 8a écrite (non testée dans Godot, aperçu PIL vérifié)** = PLACE DU COQ :
  `Scripts/exterieur.gd` (class Exterieur, **extends Room** : world.gd le traite comme une salle ; redéfinit `_creer_decor`, `_creer_collisions`, `point_arrivee`) :
  herbe + détails (TilesetFloor (11,12) et (12..15,12)), chemin de terre `:` auto-bordé (bloc 3x3 en (11,7), coins intérieurs (16,8) se / (17,8) so / (16,9) ne / (17,9) no) ;
  objets (lettre au coin haut-gauche) : `A`/`a` arbres ronds 2x2, `P` sapin, `b` buisson, `f`/`g` fleurs, `M`/`N` maisons 4x3, `E` étal 3x2, `o` tonneau, `j` bannière, `Q` statue du coq 3x3, `W` puits 2x2.
  Images maison (Outils/fabriquer_objets.py) : `statue_coq.png` (socle de pierre + coq héraldique rouge), `puits.png`.
  `Outils/generer_village.py [apercu.png]` écrit `Scenes/village.tscn` (+ aperçu image) ; `Scenes/exterieur.tscn`. PlaceDuCoq = grille (2,2) ; sorties N/O/E fermées par des buissons tant que les voisins n'existent pas.
  `world.gd` : exports `musique` (village = « 36 - Village.ogg ») et `donjon` (faux = pas de HUD plumes, pas de sortie du donjon) ; F1 -> « Aller au village / au donjon ».
  SAUVEGARDE : `Etat.scene_sauvee` (scène où reprendre). Nouvelle scène principale `Scenes/demarrage.tscn` (`demarrage.gd`) : partie sauvée -> sa scène, sinon -> village.

- 2026-11-12 : retour 8a : « pas mal mais pas le charme d'un Zelda, pas assez vivant : vent, fleurs, animaux, poules ». Question archi : séparer extérieur / chaque donjon pour qu'une modif ne casse pas tout.
  **ÉTAPE 8b écrite (non testée dans Godot, aperçu PIL vérifié pour l'image fixe)** :
  ARCHITECTURE : nouvelle base `Scripts/ecran.gd` (class Ecran : TUILE, TAILLE_SALLE, DOSSIER, exports layout/grille/teinte/sombre/indice, cache `_image`, `_poser`, `_poser_rect`,
  `reinitialiser()` et `point_arrivee()` par défaut). `room.gd` (donjon) et `exterieur.gd` (extérieur) en héritent SÉPARÉMENT (Exterieur n'hérite plus de Room).
  `world.gd` parle aux écrans via `Ecran` (seule la vue aérienne garde `Room`). RÈGLE : commun -> ecran.gd ; donjon -> room.gd ; extérieur -> exterieur.gd ;
  chaque lieu a son générateur (`generer_monde.py` = aile gauche, `generer_village.py` = village) et sa scène.
  VIE : `Scripts/ambiance.gd` (class Ambiance, créée par world.gd si `donjon = false`, suit la caméra) : `static var force_vent` (rafales toutes les 7-13 s),
  feuilles/pétales (FX/Particle/Leaf.png, LeafPink.png) qui traversent l'écran, 2 ombres de nuages (Clouds.png, noir 12 %), 2 papillons (dessinés), vent (Ambient/Wind.wav -24 dB) + oiseaux (Creature/Bird.wav).
  `exterieur.gd` : plantes/arbres/bannières qui se balancent (`skew`, base fixe, `_plantes`), touffes d'herbe semées seules (~1/6, pas au bord des chemins ni sous un objet),
  fleurs `f` tournesol / `g` rouge / `w` marguerite ; export `animaux` ("lettre x y") -> `Scripts/animal.gd` (class Animal, CharacterBody2D couche 1 : promenade, picore,
  la poule fuit le joueur ; coup de lance = sursaut + cri (Bird.wav aigu / Dog.wav) + plumes (CPUParticles2D) + fuite ; gag après 6 coups de poule ; le chat se rendort).
  Place : 3 poules, 1 chat devant la maison orange, 1 chien.

- 2026-11-12 : retours 8b : « trop de vent, attaque de poules comme Zelda, girouette au centre avec le coq ». **ÉTAPE 8c écrite (non testée dans Godot, aperçu PIL vérifié)** :
  VENT adouci (`ambiance.gd` : force 0.3 + rafales +0.5 toutes les 16-28 s, 4 feuilles max, son -32 dB). POULES EN COLÈRE (`animal.gd`) : 5 coups de lance en moins de 8 s -> toutes les poules + 5 renforts
  (blanches, venues des bords) foncent sur le joueur 12 s, le repoussent à coups de bec (`player.gd::repousser`, aucun dégât), se calment ensuite, renforts disparaissent. GIROUETTE : `Q` = mât de fer + socle 3x4
  (`girouette_mat.png`) + coq (`girouette_coq.png`) qui se retourne doucement (`exterieur.gd::_coq`), au centre de la place (11,4) ; l'ancienne statue du coq n'est plus utilisée. Images via `Outils/fabriquer_objets.py`.

- 2026-11-12 : **ÉTAPE 8d écrite (non testée dans Godot, aperçu PIL vérifié)** = VILLAGE OUEST (1,2) + VILLAGE EST (3,2, CASERNE) + PNJ/DIALOGUES.
  `generer_village.py` : 3 écrans (sorties ouest/est de la place OUVERTES ; ferme (0,2) et maison du héros (4,2) fermées par des buissons, nord fermé). Ouest : 2 maisons, marché, 3 habitants (Colette, Gaspard, Tom).
  Est : caserne (maison beige + bannières), Capitaine Aubrac (KnightGold, annonce l'épreuve au temple), Soldat Merle, Marchande Rosine. Les maisons ne s'ouvrent pas encore (intérieurs à faire).
  NOUVEAU : `Scripts/pnj.gd` (class Pnj : StaticBody2D, groupe "pnj", tourne la tête vers le joueur, `parler`) ; `Scripts/dialogue.gd` (class Dialogue, CanvasLayer 4, texte lettre par lettre, créée par world.gd) ;
  `Etat.dialogue_demande` + `Etat.en_dialogue` ; `player.gd` : près d'un habitant (26 px), Espace/J = PARLER au lieu de frapper ; `exterieur.gd` : export `pnjs` (lignes "Perso x y direction | Nom | phrase // phrase").
  Textes des PNJ dans `generer_village.py` (éviter les guillemets droits ", utiliser « »).

- 2026-11-12 : **ÉTAPE 8e écrite (non testée dans Godot, aperçu PIL vérifié)** = MAISON DU HÉROS + INTÉRIEURS VISITABLES.
  `ecran.gd` (commun) : `pnjs` (déplacé depuis exterieur.gd) + `passages` ("x y Ecran dx dy" = marcher sur la case -> arriver dans l'écran nommé, case (dx,dy) ; "x y ! texte" = message, ex. porte fermée) ; `interieur` (vrai = pas de vent/feuilles : `world.gd::_regler_obscurite` coupe l'Ambiance).
  `Etat.passage` (signal) -> `world.gd` -> `_ramener(ecran, case, "")` (fondu, joueur déplacé ; `_montrer_indice` appelé). NOUVEAU `Scripts/interieur.gd` (class Interieur extends Ecran, `Scenes/interieur.tscn`) :
  plan texte (' ' noir, # mur brique, . sol, m paillasson, L lit, S étagère, o tonneau, B banc), sol TilesetInteriorFloor (4,13), meubles de `tileset_bed.png`.
  `generer_village.py` : écran **MaisonHeros (4,2)** (maison orange, porte case (12,4), chemin depuis la caserne), intérieurs à la rangée 5 de la grille : **InterieurHeros (4,5)** (Maman) et **InterieurCaserne (3,5)** (Soldat Gilles) ;
  les 4 autres maisons du village = « porte fermée à clé ». NOUVELLE PARTIE : le joueur démarre DANS la maison du héros (indice de début). La case de porte d'une maison extérieure n'est pas solide (`exterieur.gd::_creer_collisions`).

- 2026-11-12 : l'utilisateur veut un vrai rendu SNES : 4 planches Gemini reçues (maisons, nature, intérieur, caserne) -> `Assets/Gemini/originaux/village_*.jpg`.
  **ÉTAPE 8f écrite (non testée dans Godot, aperçus PIL vérifiés)** : nouvel outil `Outils/traiter_village.py` (table d'objets : boîte source -> taille en px ; fond magenta/ardoise retiré par remplissage depuis les bords,
  réduction Lanczos + palette 28 couleurs) -> 59 images `Assets/Gemini/tuiles/v_*.png` (arbres, buissons, fleurs, herbe, roche, puits, 6 maisons 64x64 avec porte calée sur une case, meubles, sols, murs, objets de caserne).
  `exterieur.gd` : table `OBJETS_G` (lettre -> image, emprise, bloque, vent), image CENTRÉE sur l'emprise et ALIGNÉE EN BAS (`_poser_sprite`) ; MAISONS 4x4 : `M` orange, `N` bleue, `T` chaume, `R` rouge, `K` caserne, `L` bois ;
  la porte est sur la 4e rangée (colonne dans `PORTES_MAISONS`) -> passage en (x+col, y+3), arrivée dehors en (x+col, y+4). Nouvelles lettres `B` baies, `x` caisse, `n` panneau, `u` souche, `r` roche. Sol (herbe/chemin) et étal `E` encore du pack Ninja.
  `interieur.gd` RÉÉCRIT : export `style` ("maison" bois/crème, "caserne" pierre), pans de mur du haut 2x2 (lettres w x y v z), meubles par lettre (table `MEUBLES`, voir en-tête du script), tout en images Gemini.
  `generer_village.py` : maisons 4x4, passages recalculés, intérieurs refaits (hero : lit, cheminée, étagère, table, tapis ; caserne : lits, râteliers, boucliers, table de carte, brasero, coffre).

- 2026-11-12 : idée de l'utilisateur : des MINI-JEUX comme dans Zelda (maisons/tentes). Liste proposée : 1 stand de tir à la lance, 2 chasse aux poules, 3 jeu des cloches (Simon), 4 parcours de la garde (chrono + course), 5 les trois pots, 6 pêche (avec la rivière).
  Choisis : 1 et 2. **ÉTAPE 9a écrite (non testée dans Godot)** :
  FRAMEWORK : `Scripts/minijeu.gd` (class MiniJeu : `_depart`, `_maj`, `_texte_hud`, `_nettoyer`, `_terminer(valeur, plus_grand, seuils[bronze,argent,or], nom_ruban, unite)` : record + ruban + message + jingle ; HUD en haut ; abandon si le joueur quitte l'écran).
  Lancement : la ligne d'un habitant dans `pnjs` peut avoir une 4e partie `| id` ; `Pnj.parler` -> fin de la boîte de dialogue (`Etat.dialogue_fini`) -> `Etat.minijeu_demande(id)`. L'écran a l'export `minijeu` ("tir" / "poules") -> `Ecran._poser_minijeu`.
  `Etat.records` (sauvegardés) + `noter_record`. Rubans = drapeaux `ruban_tir_bronze|argent|or`, `ruban_poules_...` (pas encore affichés quelque part).
  STAND DE TIR (`mini_tir.gd`) : **InterieurStand (1,5)** = maison ROUGE du village ouest (porte (13,5)), Maître Tirard ; pots (`Pot`) sur les cases `c` (rangée 5), 30 s, 1 pot toutes les 0,75 s (3 max, 2 s de vie), bronze 8 / argent 14 / or 20.
  CHASSE AUX POULES (`mini_poules.gd`) : nouvel écran **Ferme (0,2)** (ouest du village ouest, buissons retirés), enclos en clôtures (`e` 2 cases, `z` poteau ; images `v_cloture`, `v_poteau`), cases `k` = intérieur de l'enclos, cases `s` = départs des 6 poules,
  fermière (Villager5) ; poule entrée dans l'enclos = bloquée dedans (`Animal.limiter`) ; 75 s ; rubans au temps : < 60 s / 45 s / 30 s. Grange (L) fermée.
  À FAIRE : afficher les rubans et records (ex. dans la maison du héros), récompenses utiles, mini-jeux 3-4-5.
- 2026-11-12 : retour 9a : « le jeu de la poule n'est pas marrant et galère à jouer ; je n'aime pas le style des maisons ». **POULES REFAITES (9b, non testé)** façon cocottes de Zelda : près d'une poule du jeu (groupe `poules_ferme`), Espace/J la PREND (`Animal.attraper`, tenue au-dessus de la tête, joueur x0.85),
  Espace/J la LANCE (`player.gd::_lancer_poule` : 44, 30 ou 14 px devant sur une place libre, vol de 0,3 s par-dessus les clôtures, `Animal.lancer`) ; les poules ne fuient plus ; 5 poules, 60 s, rubans < 50 / 35 / 22 s ; une poule rentrée est `verrouillee`.
  MAISONS : style Gemini rejeté (raison précise à demander : vue de face vs dessus ? trop cartoon ? couleurs ?) -> à refaire.
- 2026-11-12 : l'utilisateur aime le style ALttP (maison = grand toit vu d'en haut, forêt dense) puis précise : **couleurs JOYEUSES, comme Link's Awakening DX** (les planches Gemini 2 étaient sombres).
  3 planches reçues (`Assets/Gemini/originaux/village2_{maisons,nature,sol}.jpg`). **ÉTAPE 9c écrite (non testée dans Godot, aperçu PIL vérifié)** : nouvel outil `Outils/traiter_village2.py` (à lancer APRÈS `traiter_village.py`) : découpe + `joyeux()` (saturation x1.5, luminosité x1.6, verts vers le jaune ; réglables SAT/LUM en tête du script)
  -> remplace `v_maison_*` (toits vus d'en haut ; + `v_maison_pierre`, caserne 96x64 = 6 cases), `v_arbre_a/b` (40x40, emprise 2x2), `v_sapin`, buissons, roche, souche, herbes, fleurs, clôture ; et FABRIQUE EN CODE le sol : `v_herbe_sol`(+_1/_2 touffes), chemin beige à bords irréguliers `v_chemin_<bits>` (1 N, 2 S, 4 O, 8 E) et `v_chemin_f<coins>` (case pleine + coins d'herbe).
  `exterieur.gd` : `_poser_sol` / `_nom_chemin` (plus de tuiles du pack pour le sol) ; maisons : `S` pierre, `K` caserne 6x4 (door col 1) ; `generer_village.py` : `bordure(g, trou=...)` = forêt dense (2 rangées décalées), caserne en (11,2), capitaine en (14,6).
  Reste du pack Ninja : étal `E`, girouette (images maison), intérieurs = anciennes images Gemini (v_ meubles, couleurs déjà vives).
- 2026-11-12 : l'utilisateur montre des captures de maisons de Zelda (toit à 4 pans vu d'en haut) comme style préféré, puis une image Zelda retouchée : **REFUSÉ** (sprites Nintendo : jamais dans le dépôt ni envoyés à Gemini ; on décrit le style en mots).
  **ÉTAPE 9d écrite (non testée dans Godot, aperçus PIL vérifiés)** : `Outils/fabriquer_maisons.py` DESSINE EN CODE des maisons ORIGINALES (à lancer APRÈS `traiter_village2.py`) : toit à 4 pans (panneau central + pans inclinés, 6 motifs : losanges, briques, chaume, ardoise, écailles, bois),
  mur de pierre avec 2 fenêtres, porte cintrée sous un auvent, 3 dalles, ombre à droite, petit coq doré sur le toit. Maisons **80x64 = 5x4 cases (porte colonne 2)**, caserne **112x64 = 7x4 (porte colonne 3)** ; `PORTES_MAISONS` mis à jour.
  `generer_village.py` : maisons déplacées (portes : place (5,5) et (20,5) fermées ; ouest (5,5) fermée + (14,5) STAND DE TIR ; caserne (13,5) ; héros (13,5) ; grange (19,5)), `degager_maisons()` retire les décors posés sous une maison, intérieurs -> sorties recalées.
  ORDRE DES OUTILS : traiter_village.py -> traiter_village2.py -> fabriquer_maisons.py -> generer_village.py. Les planches Gemini de maisons (village2_maisons.jpg) ne sont plus utilisées (remplaçables par du Gemini plus tard, même emprise 5x4).

- 2026-11-13 : conflit Git sur mini_tir.gd : l'utilisateur avait collé mon explication dans le script -> nettoyé (leçon : donner le code final dans un bloc à copier). Nouveau pack ajouté par l'utilisateur :
  `Assets/Aesthetic pack base set (Free)/` (cases de 24 px : Grassland Tileset, Pack 1 expansion, Reg tree wall, Alt-water cliffs, Player Sample, Player Sword Sample). Licence à vérifier (usage commercial ?).
  **ÉTAPE 10a écrite (non testée dans Godot, aperçu PIL vérifié)** : `Outils/traiter_pack_aesthetic.py` (à lancer APRÈS fabriquer_maisons.py, AVANT generer_village.py) remplace le décor EXTÉRIEUR en gardant les MÊMES noms `v_*.png`
  (exterieur.gd inchangé) : sol herbe/chemin (couleurs du pack, fabriqué par traiter_village2), arbres, sapin, buissons, roche, souche, puits, clôture, fleurs, maisons (toit teinté, 80x81 ; caserne 112x88, porte colonne 3). Échelle 2/3 (24 -> 16 px).
  Restent de l'ancien style : tonneau, caisse, bannière, étal, girouette, intérieurs. Décision utilisateur : on continue ensuite la liste A puis retour aux corrections ; PNJ jugés laids -> chercher un pack de persos 16 bits (le « Player Sample » du pack est de la même série).

- 2026-11-13 : **ÉTAPE 10b écrite (non testée dans Godot)** : (1) dialogues conditionnés (`[drapeau]`, `[!drapeau]`, `>> drapeau`, versions séparées par `##`, voir `ecran.gd::_poser_pnjs` et `pnj.gd`) ;
  (2) chemin du temple : écrans `GrandChemin` (2,1), `Parvis` (2,0, corps du donjon scellé), `TempleGauche` (1,0, porte -> donjon) ; passage entre scènes : cible `"@donjon:Ecran"`/`"@village:Ecran"` dans `passages` (`world.gd::_changer_de_scene`, `Etat.arrivee_*`) ;
  la porte du donjon se referme derrière le joueur (sortie seulement avec le fragment, puis vue aérienne -> village). (3) NOUVEAU HÉROS : `Assets/character-spritesheet.png` (planche LPC 1536x4736, cases 64 px) -> `Outils/preparer_heros.py` -> `Assets/Heros/heros_marche.png` + `heros_coup.png` (cases 32 px) ;
  `player.gd` les utilise (marche 8 images, estoc 8 images ; `sprite.offset` (0,-5)). Reste : écrans nord restants, secrets, musique d'intérieur, rubans/records (liste A points 4-5).

- 2026-11-13 : retour utilisateur : héros OK mais « il rentre dans certains arbres » (arbres du pack plus larges que leur zone de collision 2x2) et son style jure avec les PNJ (à changer plus tard : PNJ à refaire, ex. générateur LPC, même série que le héros).
  **ÉTAPE 10c écrite (non testée dans Godot)** : (1) `exterieur.gd` : grands objets (arbres, maisons, puits : image >= 24 px de haut) passent DEVANT le héros quand il est derrière eux (`_hauts`, z_index mis à jour dans `_process`) ;
  (2) MUSIQUES : `@export musique_ecran` par écran (Parvis et Temple = « 12 - Temple »), maisons = « 27 - Chill » (`world.gd::_changer_musique`, fondu) ; (3) TABLEAU D'HONNEUR : passage `"x y $records"` -> `Etat.texte_records()` (records + rubans), posé en (14,6) dans InterieurHeros.
  Liste A : points 1 (tests utilisateur), 2, 3 faits ; 4 fait à moitié (musique d'intérieur OK, SECRETS bois/cascade PAS faits) ; 5 fait (affichage rubans/records, récompenses utiles PAS faites).
  À FAIRE : retester collisions arbres (si besoin élargir l'emprise des arbres ou ajouter une 5e valeur « emprise de collision » dans OBJETS_G) ; remplacer les PNJ ; secrets ; récompenses ; aile droite ; contrôles tactiles.

- 2026-11-13 : l'utilisateur ajoute `Assets/Midi files/` (28 MIDI). Godot ne lit PAS le MIDI -> `Outils/rendre_musiques.py` (FluidSynth + FluidR3_GM + ffmpeg) -> `Assets/Musique/NN_nom.ogg` (28 fichiers, ~21 Mo, rendus SANS écoute côté Claude : qualité à valider par l'utilisateur ; licence du pack MIDI à vérifier).
  Branchés : village = `04_peaceful_village`, parvis/temple = `13_magic_temple` (via generer_village.py). Pistes dispo : 01/09/16/24 combat, 02 ville animée, 03 château royal, 05 long voyage, 06 caverne cachée, 07 forêt, 08 ville forestière, 13 temple magique,
  18 vieux magicien, 19 ville est, 20 base militaire (caserne ?), 22 bibliothèque, 28 sanctuaire sacré (fin ?). Le donjon et les intérieurs gardent les musiques Ninja Adventure (« 21 - Dungeon », « 27 - Chill »).

- 2026-11-13 : À FAIRE (demandes de l'utilisateur, après les musiques) : (1) HABITANTS dans le style du héros (planches LPC) ; (2) AILE DROITE du donjon ; (3) REFAIRE L'ENTRÉE DU DONJON (le temple = la maison-forge mousse réutilisée, ressemble à une maison) ;
  (4) TAILLE DES PORTES : la porte des maisons (~19 px) est plus petite que le héros (24 px) -> pas crédible ; (5) « on a l'impression de rentrer dans le RIEN » en entrant dans un bâtiment (intérieur = écran noir séparé, aucune transition crédible : pas de porte qui s'ouvre, pas de bruit, intérieur sans rapport avec l'extérieur).
  Pistes : arche de pierre du pack Aesthetic (Grassland Tileset, cases (10..13,11..13)) + escalier sombre pour l'entrée du donjon ; maisons/portes à l'échelle du héros ; porte qui s'ouvre + bruit + héros qui monte d'une case ; intérieur apparaissant dans la continuité de la porte.

- 2026-11-13 : **ÉTAPE 10d écrite (non testée dans Godot, aperçu PIL vérifié)** : MAISONS AGRANDIES x1,3 (porte ~29 px pour un héros de 24 px). Toutes les maisons font maintenant 7x4 cases de collision (sprite 112x106, porte colonne 3),
  la caserne/temple `K` 7x4 (sprite 112x110). `generer_village.py` : helpers `maison(g, lettre, x_ancien, y_ancien)` (décale de (-1,+1)) et `grande(g, x, y)` ; TOUTES les portes sont une rangée plus bas (ex. (5,6) au lieu de (5,5)), arrivées dehors en rangée 7 ;
  `world.gd` : retour du donjon en (12,7). `exterieur.gd` : emprise 7x4, PORTES_MAISONS colonne 3. Reste à faire : transition d'entrée crédible (porte qui s'ouvre + bruit), entrée du donjon refaite (arche), habitants style héros, aile droite.

- 2026-11-13 : **ÉTAPE 10e écrite (non testée dans Godot)** : (1) TRANSITION DE PORTE crédible : `world.gd::_passer_porte` (bruit de porte `Assets/Sons/porte.wav` fabriqué par `Outils/fabriquer_sons.py`, un pas de 12 px vers l'intérieur/extérieur avec animation de marche, puis fondu, arrivée dans le bon sens via `Etat.arrivee_direction`) ;
  (2) ENTRÉE DU TEMPLE refaite : lettre `U` (`Outils/fabriquer_temple.py` -> `v_temple_entree.png` 112x96 : arche de pierre verte du pack Aesthetic, ouverture sombre, 3 marches ; emprise 7x4, porte colonne 3) dans `TempleGauche` ;
  (3) HABITANTS style héros : `Outils/preparer_pnj.py` recolore la planche du héros en 9 variantes (`Assets/Heros/pnj_<NomNinja>.png` : Woman, OldMan, Boy (plus petit), KnightGold, Villager..5) ; `pnj.gd` les utilise si le fichier existe (sinon ancien pack). LIMITE : tous ont le même corps/visage (barbu) = simple recoloration -> pour de vrais personnages variés, il faut d'autres planches LPC (générateur LPC).
  RESTE : aile droite (Opus), secrets, récompenses, contrôles tactiles, corps du donjon.

- 2026-11-13 : **ÉTAPE 11a écrite (non testée dans Godot)** = DÉBUT DE L'AILE DROITE. Scène séparée `Scenes/aile_droite.tscn` écrite par `Outils/generer_aile_droite.py` (MIROIR de l'aile gauche : `miroir()` retourne un plan, échange < > et M N).
  Grille : Vestibule (0,1) (pas d'énigme, grande porte sud H = `fragment_droite`), Entree (0,0) sortie OUEST, Epine1 (-1,0) porte ouest (colonne 1) = `plumeD1`, PlumeD1 (-1,-1), Epine2 (-2,0) provisoire (cul-de-sac).
  DRAPEAUX de l'aile droite : `plumeD1`..`plumeD4`, `fragment_droite`, `vue_aerienne_droite`. `world.gd` : export `cote` ("gauche"/"droite"), `_plume(n)`, `_temple()`, table `SCENES` (passages "@donjon:", "@aile_droite:", "@village:"), F1 = aller au village / aile gauche / aile droite ; HUD, retour rapide, sortie + vue aérienne suivent `cote`.
  PLUME D1 « LES PLOTS » : `Scripts/plot.gd` (class Plot, lettres `o` orange levé / `u` bleu baissé, dessinés en code, ne se lèvent pas sous le joueur ou un bloc) ; dans une salle à plots, le cristal `K` = COMMUTATEUR (`cristal.gd`, 1 bascule par coup, prend la couleur des plots levés ; `Room.basculer_plots`, R remet orange levés).
  Énigme : barrière orange (rangée 9) avec le cristal dedans ; frapper du sud (orange baissés mais grille bleue du nord levée), passer, refrapper du nord -> plume.
  VILLAGE : `TempleDroit` (3,0) (même arche `U`, porte (12,6) -> `@aile_droite:Vestibule`) ; le chemin du Parvis est ouvert vers l'est. Ordre des ailes libre.
  PLAN PROPOSÉ (à valider) : D2 (2 écrans) SOL FRAGILE (dalles qui s'effondrent après un passage : tout parcourir une seule fois), D3 (3) GLACE (on glisse jusqu'à un obstacle), D4 (4) LE REFLET (un double inverse tes mouvements gauche/droite), D5 (5) combinaison -> fragment droit en (-5,-5).

- 2026-11-13 : plan D2-D5 VALIDÉ par l'utilisateur. **ÉTAPE 11b écrite (non testée dans Godot, solutions vérifiées par un solveur Python)** = PLUME D2 « LE SOL FRAGILE ».
  `Scripts/dalle.gd` (class Dalle, lettre `z`, dessinée en code : INTACTE -> MARQUEE (pied dessus, lueur) -> TROU (en la quittant : tremble + tombe, son Impact2) ; `raffermir()` = énigme résolue, ne tombe plus).
  `room.gd::_suivre_pas` (salle courante) : changement de case seulement si les pieds sont à 3 px dans la case (pas de marquage en coupant un coin) ; pieds dans un TROU (2 px de marge) -> `Etat.chute(retour)` ;
  toutes les dalles foulées -> `drapeau_fragile` + dalles raffermies. R / chute = dalles réparées. `world.gd::_raccompagner(retour, chute)` : chute = héros qui rapetisse en tournant + Whoosh, puis même retour que les sentinelles.
  SALLES : Epine2 (-2,0) porte ouest = `plumeD2` (tige ouverte) ; PlumeD2a (-2,-1) leçon 5x4 dalles (`d2_sol1` ouvre la grille du haut) ; PlumeD2b (-2,-2) 34 dalles + 2 piliers, il faut FINIR devant la grille de l'alcôve (20 solutions, `d2_sol2`) -> plume `plumeD2` ;
  Epine3 (-3,0) provisoire (cul-de-sac). Retours = bas de l'écran courant (`retour_d2(n)`). À vérifier au test : sensation de la règle des 3 px, lisibilité dalle/trou.

- 2026-11-13 : retour D2 : « règles pas claires, les dalles ne se réinitialisent pas quand on se trompe ». **CORRECTION 11c (non testée dans Godot)** : `room.gd::_suivre_pas` détecte les ERREURS et reforme
  les dalles (`_reformer_dalles` : son Cancel, message, dalles qui remontent des trous via `Dalle.reparer(true)`, la dalle sous le joueur = nouveau départ) : (1) sortir du champ avant d'avoir tout foulé ;
  (2) impasse (aucune dalle intacte à côté). Règle annoncée au 1er pas sur une dalle (« Chaque dalle s'effondre quand tu la quittes... »). Indices D2a/D2b réécrits (D2b n'exige PAS de finir devant la grille :
  dès que tout est foulé, grille ouverte + dalles raffermies). La chute (trou) ramène toujours au bas de la salle.

- 2026-11-13 : utilisateur : « façon Zelda, des dalles qui CHANGENT DE COULEUR, c'est plus parlant (tout faire en bleu) ; revoir l'esthétique ». **ÉTAPE 11d (non testée dans Godot, aperçu PIL du dessin vérifié)** :
  PLUME D2 = « LES DALLES DE COULEUR » (remplace le sol fragile : plus de trous ni de chute). `dalle.gd` RÉÉCRIT : chaque pas RETOURNE la dalle (rouge <-> bleue, animation scale:x + Menu/Move2.wav aigu/grave),
  dessin = cadre de pierre + dalle biseautée + panneau + gemme (dorée une fois validée) ; `retourner()`, `remettre()` (R), `valider()`. `room.gd::_suivre_pas` : règle des 3 px gardée, toutes bleues -> `drapeau_fragile`.
  Message au 1er pas. Mêmes plans D2a/D2b (indices réécrits). `Etat.chute` + `world._raccompagner(retour, chute)` restent dans le code (inutilisés pour l'instant).

- 2026-11-13 : l'utilisateur ajoute un PACK DONJON Craftpix (16 px, vue 3/4) : `Assets/PNG/` (walls_floor, Objects, doors_lever_chest_animation, fire_animation(2), trap_animation, decorative_cracks_*, Water_*), + `Assets/PSD/`, `Assets/Tiled_files/`.
  Licence craftpix.net (usage dans un jeu OK, pas de redistribution des fichiers seuls -> attention si le dépôt devient public). **ÉTAPE 12a (non testée dans Godot, aperçu PIL vérifié)** :
  `Outils/traiter_pack_donjon.py` (à lancer APRÈS traiter_gemini.py) écrit dans `Assets/Gemini/tuiles/` : `brasero_1..6` + `brasero_eteint` (20x26, flamme retirée + braises ; décalage `Room.DECALAGE_BRASERO` (-2,-10)),
  `torche_1..6` (12x24, posées en (x*16+2, 8)), `vase_1` bleu / `vase_2` brun (16x16, `pot.gd` sprite en (0,-1)). `room.gd` : constantes `BRASERO`, `TORCHE` (6 images). `apercu_salle.py` mis à jour.
  PISTES (à décider avec l'utilisateur) : murs/sol du pack (briques sombres en vue 3/4, sol gris-bleu uni) à la place des murs Gemini verts ; PORTES en arche avec herse qui se relève (animation 5 images) ou porte en bois ;
  coffres (ouverture animée), leviers (5 images), clés, pics (trap_animation), fissures décoratives, eau. Limite : arches de 2 cases de large (nos portes en font 3).

- 2026-11-13 : utilisateur : « fais les 4 points » (murs/sol, portes en arche, coffres/leviers/clés, pics/eau). **ÉTAPE 12b écrite (non testée dans Godot, aperçus PIL vérifiés)** :
  1) MURS/SOL du pack (vue 3/4) : `traiter_pack_donjon.py` écrit `mur_fond`, `mur_bord_*`, `mur_coin_*`, `mur_dot_*` (rebords de briques = différence avec le mur sombre uni), `mur_face_haut/bas` (+ `_g`/`_d` bouts), `pilier` (16x24), `sol_plat` gris-bleu uni,
     `sol_plat_c/_d` (dalles gravées rares). `room.gd::_poser_mur` : sol juste en dessous = FACE de briques (et le mur au-dessus d'une face aussi si lui-même a un mur au-dessus -> mur du haut = 2 rangées de briques) ; sinon vu de dessus (sombre + rebord côté sol) ;
     mur isolé d'1 case = `pilier`. `_murs_du_cadre` et `dalle_unie` supprimés. (decorative_cracks_floor.png = des TROUS, pas des fissures : non utilisé.)
  2) PORTES : `porte.gd` RÉÉCRIT : `initialiser(taille, texture, images=[])` ; images = arche animée qui RESTE (dernière image) ; `ouvrir(instantane)` (au chargement d'une salle : sans bruit, sans secousse, sans message « porte quelque part » -> `Room._chargement`).
     `room.gd::_poser_portes_lettre` : groupe 48x32 en haut (rangée 0) = `arche_herse_1..5` (ou `arche_bois_1..5` pour E) ; 48x16 intérieur = `arche_basse_1..5` ; le reste (bas, côtés) = ancienne grille. Arches 32 px du pack ÉLARGIES à 48 (`elargir`).
  3) COFFRE `Q` (`coffre.gd`, frappé -> animation, objet qui s'élève, `drapeau_coffre`, `texte_coffre`), LEVIER `J` (`levier.gd`, `drapeau_levier`), PORTE À SERRURE `E` (`Porte.activer_serrure(drapeau_cle, drapeau_serrure)` : le joueur la touche avec la clé).
  4) PICS `Z` (`pics.gd` : cycle `periode_pics` 2.4 s, colonnes paires/impaires décalées d'un demi-cycle, sortis = `Etat.pique(retour)`) ; `world._raccompagner(retour, raison)` : "garde" / "chute" / "pics". EAU `~` (bloque, 2 images alternées, bord sombre + reflet).
  UTILISATION (aile droite, `generer_aile_droite.py`) : Vestibule = leçon CLÉ (coffre (19,8) -> clé `d_cle_vestibule` -> porte de bois E au nord, `d_porte_vestibule`) ; Entrée = leçon LEVIER (J (4,9) -> grille ouest D colonne 1, `d_levier_entree`) + 2 bassins d'eau ;
  Épine2 = 2 colonnes de pics (x 16 et 19) entre l'entrée est et la tige (retour (23,6)). L'aile gauche profite automatiquement des nouveaux murs/sols/arches.
  ORDRE DES OUTILS donjon : traiter_gemini.py -> fabriquer_objets.py -> traiter_pack_donjon.py. `apercu_salle.py <n> <png> [scene.tscn]` montre aussi coffres, leviers, pics, eau, arches.

- 2026-11-13 : **ÉTAPE 11e écrite (non testée dans Godot, 3 salles vérifiées par un solveur)** = PLUME D3 « LA GLACE » (colonne x=-3).
  Lettre `i` = GLACE (`glace_1/2`, dessinées par `traiter_pack_donjon.py::glace`). RÈGLES : en posant le pied sur la glace, on glisse tout droit (sens de la marche) jusqu'à un obstacle ; une case libre NON glacée (sol, plot baissé, case de départ d'un bloc) arrête la glissade dessus ;
  arrêté sur la glace, une direction = nouvelle glissade, ou pousser le bloc devant (il glisse aussi, `bloc.gd`). `room.gd` (section Glace) : `case_des_pieds`, `position_sur_case`, `est_glace`, `case_bloquee`, `destination_glissade`, `pousser_bloc`, la salle s'annonce dans `joueur.terrain` (`_annoncer_glace`).
  `player.gd::_gerer_glace` (glissade à 130 px/s, Whoosh2 au départ, Impact à la butée), `arreter_glissade()` (appelé par world lors des téléportations). Touche R dans une salle de glace = retour au début (`_raccompagner(retour, "recommencer")`).
  SALLES : Épine3 porte ouest = `plumeD3` ; D3a (-3,-1) leçon (3 glissades) ; D3b (-3,-2) BLOC comme butée (12 coups, impossible sans le bloc) ; D3c (-3,-3) glace + PLOTS + CRISTAL (13 coups, impossible sans le cristal) -> plume `plumeD3` ;
  Épine4 (-4,0) provisoire (cul-de-sac). Sorties de D3a/D3b = remonter la colonne 12 jusqu'au sol de la rangée 2. `Outils/resoudre_glace.py` revérifie les 3 salles depuis aile_droite.tscn (à relancer après toute modif).

- 2026-11-13 : **ÉTAPE 11f écrite (non testée dans Godot, 4 salles vérifiées par un solveur)** = PLUME D4 « LE REFLET » (colonne x=-4).
  `Scripts/reflet.gd` (class Reflet, CharacterBody2D) : double fantôme du joueur (même SpriteFrames, bleuté, pulse, lumière en salle sombre) qui part de la case `r` ; chaque image il reproduit le DÉPLACEMENT RÉEL du joueur
  avec x inversé (`velocity = (-dx, dy)/delta`, move_and_slide) : bloqué par murs/objets/portes fermées (masque 1), traverse le joueur (exception) ; saut > 12 px (téléportation) ignoré ; `disparaitre()` une fois l'énigme résolue.
  `room.gd` (section Reflet) : lettres `r` (départ) et `a` (dalle du reflet, `dalle_reflet(_on)`, lueur en salle sombre) ; export `drapeau_reflet` (toutes les dalles `a` occupées en même temps par joueur/reflet) ;
  le reflet ENFONCE les boutons `P` (`_reflet_sur`, `verifier_plaques`/`_maj_boutons`) ; créé à la 1re entrée dans la salle, remis au départ à chaque entrée et à R. `recommence_au_debut()` (glace ou reflet non résolu) -> R = retour au début (world.gd).
  SALLES : Épine4 porte ouest = `plumeD4` ; D4a (-4,-1) leçon (6 coups) ; D4b (-4,-2) décalage contre un mur (9 coups) ; D4c (-4,-3) le reflet entre dans la niche du bouton -> herse H du haut (41 coups) ;
  D4d (-4,-4) SOMBRE : bouton -> herse H de l'enclos, puis dalles -> alcôve D -> plume `plumeD4` (30 coups). Épine5 (-5,0) provisoire (cul-de-sac). `Outils/resoudre_reflet.py` revérifie (modèle par cases).
  À VÉRIFIER AU TEST : sensation du reflet (décalage d'1 image), passage du reflet dans les ouvertures d'1 case (niche 4c).

- 2026-11-13 : nouvelle musique du VILLAGE fournie par l'utilisateur : `Assets/Musique/First Light in the Village.mp3` (branchée dans `generer_village.py`, remplace `04_peaceful_village`). Godot lit le MP3 (boucle via `flux.loop`).

- 2026-11-13 : **ÉTAPE 11g écrite (non testée dans Godot)** = PLUME D5, POINTE DE L'AILE DROITE (colonne x=-5) -> **L'AILE DROITE EST COMPLÈTE (en code)**. Épine5 : tige ouverte, fermée à l'ouest.
  Chaque écran COMBINE : D5a (-5,-1) CLÉ + LEVIER + PICS (levier (21,3) derrière 2 colonnes de pics x=15/18 -> herse de la niche du coffre -> clé -> porte de bois E du haut ; rythme des pics non simulé) ;
  D5b (-5,-2) REFLET + PLOTS (29 coups) ; D5c (-5,-3) GLACE + BLOC + BOUTON (le bouton = sol normal qui arrête le bloc ; 17 coups) ; D5d (-5,-4) DALLES + PLOTS + CRISTAL au milieu du champ 5x3, herse H du couloir de sortie (19 coups) ;
  D5e (-5,-5) GLACE + PLOTS + CRISTAL + COFFRE -> clé -> grille à serrure E de l'alcôve -> FRAGMENT `fragment_droite` (26 coups). Chacune impossible sans sa mécanique clé.
  NOUVEL OUTIL `Outils/resoudre_d5.py` = SOLVEUR GÉNÉRAL (glace, blocs, plots/cristal, boutons/herses, coffre/serrure, reflet/dalles du reflet, dalles de couleur), réutilisable pour l'épreuve finale ; `python3 Outils/resoudre_d5.py` revérifie D5b-e.
  Les plans 5d et 5e ont été choisis par RECHERCHE AUTOMATIQUE (milliers de dispositions testées, contrainte « impossible sans le cristal »).
  À TESTER : toute l'aile droite (D1 à D5), sortie avec le fragment -> vue aérienne droite -> village (TempleDroit). Ensuite : rééquilibrage des énigmes, CORPS du donjon (épreuve finale).

- 2026-11-13 : plume D5 TESTÉE par l'utilisateur : « j'ai réussi mais il faudra revoir ça » (trop dure / pas assez lisible ; solutions détaillées données en chat). À REVOIR lors du rééquilibrage des énigmes.
  Pistes : indices plus précis, raccourcir D5b, panneau expliquant « un plot baissé = passage qui ne retourne aucune dalle / qui arrête la glissade ».

- 2026-11-13 : VISION DE LA FIN (utilisateur) : les 2 ailes s'insèrent dans une STÈLE du coq ; ça ouvre les ARBRES derrière (qui cachaient le CORPS du coq) ; les 3 parties se rassemblent, vues en MODE 7 ;
  dedans : (peut-être une énigme finale puis) un GARDIEN : le joueur CHOISIT de le combattre (combat de boss) ou de REFUSER (« un garde ne choisit pas toujours la violence ») ; les DEUX issues sont des victoires.
  Découpage : A = stèle + forêt + mode 7 (fait) ; B = intérieur du corps + Gardien + choix + boss ; C = fin (adoubement au village, générique).
- 2026-11-13 : **ÉTAPE 13a écrite (non testée dans Godot, aperçus PIL vérifiés, shader simulé en Python)** = LA STÈLE ET LE MODE 7.
  `Outils/fabriquer_stele.py` -> `v_stele_vide.png` / `v_stele_pleine.png` (36x48, coq du blason gravé ; lettres extérieures `Y` / `y`, emprise 1x1). PARVIS (generer_village.py) : `parvis_commun()` ;
  AVANT = forêt dense (rangées 1-4) + stèle `Y` en (12,5), passage "12 6 $stele" ; APRÈS (`drapeau_revele = corps_revele`) = forêt retirée, temple `U` (corps du coq) en (9,1), porte (12,4) (pour l'instant un message), stèle pleine `y` en (10,5).
  `ecran.gd` : exports `drapeau_revele`, `layout_revele`, `passages_revele` + `_appliquer_revelation()` (appelé par `exterieur.gd::_ready`) ; passage `$stele` -> `Etat.stele_touchee`.
  `world.gd::_ceremonie_stele` (seulement en MONTANT vers la stèle) : sans les 2 fragments = message ; sinon les 2 ailes volent dans la stèle, clac + jingle, 3 secousses, fondu,
  `Scripts/mode7.gd` (class Mode7 : SubViewport = carte 512x384 (herbe, chemin, forêt, blason_socle + les 2 ailes qui glissent vers le corps) + SHADER canvas_item de perspective (ciel dégradé, brume) ; caméra en ORBITE autour du coq `_voler(Vector3(angle, distance, altitude))`, ~11 s),
  puis `Etat.noter("corps_revele")` et rechargement du village au Parvis (12,7). F1 -> « Test stèle » (donne les 2 fragments, remet la forêt).
  À VÉRIFIER : shader dans le rendu Compatibilité, lisibilité du mode 7. PROCHAINE ÉTAPE : B (intérieur du corps, Gardien, choix combattre/refuser, boss).

- 2026-11-13 : retour 13a : « s'affiche, mais pas ce que j'avais en tête ». (1) les ailes ne vont pas au bon endroit sur la stèle + l'ASSET DE LA STÈLE ne plaît pas -> À REFAIRE plus tard ;
  (2) la FORÊT doit s'ÉCARTER DEVANT LE HÉROS (en direct) pour rejoindre le corps, qui doit être un BÂTIMENT ; (3) en mode 7, il faut voir les BÂTIMENTS du donjon (la forme des salles) se soulever, se remettre
  dans le bon sens et rejoindre le corps ; vu de haut, les BÂTIMENTS dessinent le coq (pas juste l'image du coq).
  **CORRECTION 13b écrite (non testée dans Godot, séquence simulée image par image en Python)** :
  `Outils/fabriquer_plans_mode7.py` -> `Assets/Gemini/embleme/plan_aile_gauche.png` / `plan_aile_droite.png` (VRAI plan des salles lu dans world.tscn / aile_droite.tscn, 2 px/case, murs en relief, sols dallés ; à relancer si les ailes changent),
  `plan_corps.png` (silhouette de pierre du coq du blason = bâtiment : enceinte + cloisons tous les 9 px), `plans_mode7.json` (racines = centre de l'Entrée : gauche (25,154), droite (275,154)).
  `mode7.gd` RÉÉCRIT : carte 1024x768 (herbe, forêt, grand chemin, corps en (268,128) avec ombre, ailes posées à l'ouest/est (230,250)/(794,250)) ; échelle du shader 160 ; séquence : approche -> les ailes SE SOULÈVENT (grossissent + ombre qui s'éloigne, `_poser_aile`)
  -> pivotent d'un quart de tour et volent aux épaules du corps (PIVOTS (196,122)/(292,122), forme finale `ECHELLE_EMBOITEE` (0.4, 1.0)) -> se reposent (clac) -> montée -> FONDU vers une VRAIE VUE DE DESSUS (Sprite2D = texture du SubViewport, région du coq) : le coq de bâtiments.
  PARVIS : `exterieur.gd::ecarter_foret(zone, axe_x)` (les arbres glissent sur les côtés en s'effaçant) + `faire_apparaitre(lettre, case)` (le temple `U` du corps apparaît derrière) appelés par `world.gd::_ceremonie_stele` après les secousses, AVANT le mode 7.
  Le parvis révélé n'a plus les arbres des colonnes 7-18, rangées 0-3 (mêmes que ceux qui s'écartent).

- 2026-11-13 : retour 13b : « un peu mieux, à affiner ». DÉCISION utilisateur : PAS d'énigme finale, directement le BOSS ; le bâtiment du corps doit ressembler à la vue mode 7.
  **ÉTAPE 13c écrite (non testée dans Godot)** = CORPS DU COQ + GARDIEN + FIN :
  PARVIS révélé : bâtiment `Z` (`v_corps_coq.png` 144x92, emprise 9x5, porte colonne 4, fait par `fabriquer_plans_mode7.py::batiment_parvis` = le même plan de coq que le mode 7 + façade et grande arche) en (8,0) ; porte (12,4) -> `@corps:Arene 12 11`.
  NOUVELLE SCÈNE `Scenes/corps.tscn` (écrite par `Outils/generer_corps.py`, world.gd avec `cote = "corps"`, musique « 24 - Final Area ») : salle « Arene » (statues S et braseros B = obstacles), sortie en bas -> parvis.
  `Scripts/gardien.gd` (class Gardien, GiantBlueSamurai du pack) : à l'approche, CHOIX (`Etat.choix_demande` / `choix_fait`, options dans `dialogue.gd`) « Combattre » / « Baisser ma lance ».
  COMBAT : garde parfaite de face (clang) ; il marche, brille, FONCE ; s'il percute un mur/une statue = ÉTOURDI -> le frapper ; 6 PV ; à 3 PV phase 2 (plus vite + pierres qui tombent, ombre au sol) ; musique 24_battle_theme_iv.
  HÉROS : 5 cœurs (`player.gd::blesser`, `soigner`, signal `coeurs_change`, clignote 1,2 s) ; KO = le Gardien le relève, tout recommence, le choix revient. HUD cœurs + barre du Gardien (dans gardien.gd).
  PAIX : discours « un garde ne choisit pas toujours la violence ». LES DEUX ISSUES : drapeaux `epreuve_reussie` + `fin_paix` / `fin_combat`, écran de fin (musique 28_holy_sanctuary), puis retour au village devant la caserne :
  le capitaine fait l'ADOUBEMENT (versions `[fin_paix]` / `[fin_combat]` dans generer_village.py), Maman aussi (`[epreuve_reussie]`). F1 -> « Aller au Gardien (fin) ».
  NB technique : la boîte de choix émet `dialogue_fini` 0,15 s APRÈS `choix_fait` -> gardien.gd attend ce signal avant d'ouvrir la réplique suivante.
  **LE JEU EST JOUABLE DU DÉBUT À LA FIN (en code).** SUITE (Sonnet) : AUDIT + refonte graphique/disposition du VILLAGE ; puis stèle à refaire, D5 et énigmes à rééquilibrer, mode 7 à affiner, contrôles tactiles.

- 2026-11-13 : boss testé par l'utilisateur : « il fonctionne ». **REFONTE DU VILLAGE décidée** (critiques : disposition, PNJ laids, le sud « donne sur rien », girouette, animaux qui traversent les arbres, style).
  CHOIX UTILISATEUR : (1) carte en **COQ DEBOUT** : tête = Parvis (nord), ailes = 2 temples (gauche/droite), corps = Place du Coq (centre), pattes/queue = chemins du SUD (maison du héros, pont, route : le sud doit MENER quelque part) ;
  (2) girouette CONSERVÉE mais au **design plus travaillé** (à redessiner) ; (3) **PNJ peu nombreux (~6), bien placés, avec une vraie activité** (jardinier, forgeron, enfant qui court...) ; demander à l'utilisateur ce qui choque dans leur look ;
  (4) STYLE : **auditer tous les packs** (Ninja Adventure, Aesthetic, Craftpix donjon, `generic-rpg-pack` Vaca Roxa [16 px, arbres 53x74, auberge 70x88, ponts, clôtures, PNJ 16x23 : à examiner], LPC) et compléter par des packs itch.io (à télécharger par l'utilisateur) ou Gemini.
  FAIT (non testé dans Godot) : **animaux/PNJ derrière les arbres** : `exterieur.gd::_process` règle le `z_index` du héros, des animaux (groupe `animaux`, ajouté dans `animal.gd`) et des PNJ : 0 = derrière un grand objet, 2 = devant (arbres/maisons fixés à z 1). Cause : animaux toujours dessinés au-dessus.
  À FAIRE : plan de la carte en coq (grille à définir, ex. Parvis (2,0) / ailes (1,1)-(3,1) / corps (2,2) / pattes (1,3)-(3,3)) dans `generer_village.py` ; girouette ; PNJ ; audit de style.
- 2026-11-13 : retour utilisateur : « gros problèmes de collisions entre les PNG, le héros, les maisons et les arbres ». CAUSE : arbres du pack Aesthetic 59x72 px pour une collision de 32x32 (cimes qui se chevauchent, murs invisibles).
  **CORRECTION 10f (non testée dans Godot, rendu fidèle PIL vérifié avec contours de collision)** : `Outils/traiter_pack_aesthetic.py` : constante `ARBRE = 0.36` -> arbres 32x39 / 28x37, sapin 26x43, buissons 15x13, puits 31x26 (emprise 2x2 = 32 px) ; images régénérées. Maisons inchangées (112x106, collision 7x4 = 112x64, le toit dépasse vers le haut).
  Outil de contrôle : rendre un écran avec les cases bloquantes en rouge (script jetable ; la logique = `exterieur.gd::OBJETS_G`). Si d'autres collisions gênent, donner l'écran et l'endroit exact.
- 2026-11-13 : **AUDIT DU VILLAGE (lecture seule, avant la carte en coq)** — 9 écrans extérieurs (Ferme (0,2), VillageOuest (1,2), PlaceDuCoq (2,2), VillageEst (3,2), MaisonHeros (4,2), GrandChemin (2,1), Parvis (2,0), TempleGauche (1,0), TempleDroit (3,0)) + 3 intérieurs (rangée 5 de la grille : Heros (4,5), Stand (1,5), Caserne (3,5)).
  JOUEUR : (1) tous les écrans se ressemblent : un chemin horizontal + une bordure de ~50 arbres ; (2) AUCUN écran n'a de sortie au SUD ni au NORD hors du couloir Parvis (le sud = mur d'arbres partout) ; (3) la carte est une ligne de 5 écrans + une colonne : pas de places, d'impasses à explorer, de secrets (bois/cascade/rivière jamais faits) ;
  (4) 8 PNJ / 13 animaux, 0 PNJ sur la place, 0 sur le chemin du temple, 0 sur le parvis ; (5) pas de carte ni de panneaux d'orientation ; (6) seulement 2 mini-jeux, aucune récompense utile (rubans sans effet) ; (7) un seul morceau de musique pour tout le village ;
  (8) pas de contrôles tactiles (cible mobile) ; (9) les textes citent la géographie (« temple au nord », « caserne à l'ouest ») : à réécrire avec la nouvelle carte.
  DÉVELOPPEUR : (1) COORDONNÉES EN DUR à revoir si la grille change : `world.gd` (arrivées `Vector2i(12, 7)` x3, `STELE_CASE`, écran nommé "Parvis", `_temple()` -> "TempleGauche"/"TempleDroit"), `gardien.gd` ("@village:VillageEst" case (13,7)), `generer_village.py` (`depart`, `ferme_place`, `ferme_ouest`, passages) ;
  (2) SAUVEGARDE : `Etat.position_sauvee` est en coordonnées monde de l'ancienne grille : après changement de carte, une vieille sauvegarde peut replacer le héros dans un arbre/le vide -> remettre à zéro ou valider la position au chargement ;
  (3) `world.gd` ne vérifie pas qu'un écran voisin existe : seule la bordure d'arbres/buissons empêche de sortir de la carte -> toute sortie fermée doit l'être par des objets bloquants ; (4) plans en texte 25x14 DUPLIQUÉS dans `generer_village.py` (bordure/chemin/fleurs répétés à la main) : factoriser avant d'ajouter des écrans ;
  (5) aperçu `generer_village.py::apercu` PÉRIMÉ (maisons 5x4, tuiles Ninja) : utiliser un rendu fidèle à `exterieur.gd::OBJETS_G` (collisions en rouge) ; (6) chaîne d'outils ordonnée et destructive : traiter_village -> traiter_village2 -> fabriquer_maisons -> traiter_pack_aesthetic -> generer_village (relancer tout après un changement d'échelle) ;
  (7) collisions = 1 forme par case (pas de forme par objet) : OK mais pas de collision partielle (tronc seul) ; (8) restes de l'ancien style : étal `E`, tonneau, caisse, bannière, girouette, tous les intérieurs ; `Etat.chute` inutilisé ; (9) code des écrans 10a-10f et du correctif z-index : NON TESTÉ dans Godot.
  POUR LA CARTE EN COQ : la grille accepte n'importe quelles coordonnées adjacentes (garder la rangée 5 libre pour les intérieurs) ; le Parvis (stèle (12,5), forêt qui s'écarte colonnes 7-18 rangées 0-3, bâtiment Z (8,0)) doit rester la TÊTE ; chaque écran doit avoir une identité visuelle (place, rivière/pont, champs, falaise, bois secret).

- 2026-11-13 : **PLAN DE LA CARTE EN COQ (proposé, à valider)** — ailes déployées vers le haut, 7 écrans inchangés :
  y=0 : TempleGauche (1,0) – PARVIS (2,0) – TempleDroit (3,0) [+ secrets plus tard : Bois (0,0), Cascade (4,0)] ;
  y=1 : Verger (1,1, NOUVEAU, N/S) – Cou = GrandChemin (2,1, N/S, côtés fermés) – Terrain de la Garde (3,1, NOUVEAU, N/S) ;
  y=2 : VillageOuest (1,2, N/E/S, ouest fermé) – PlaceDuCoq (2,2, + sortie S) – VillageEst (3,2, N/O/S, est fermé) ;
  y=3 : MaisonHeros (4,2 -> 1,3, N/E, plan refait) – Rivière+Pont (2,3, NOUVEAU, 4 sorties, rivière rangées 3-4) – Ferme (0,2 -> 3,3, N/O, plan refait) ;
  y=4 : Route du Sud (2,4, NOUVEAU, N ; sud bloqué par une barrière + sentinelle jusqu'à `epreuve_reussie`, futur épilogue).
  Temples : + sortie S. Ouvertures standard N/S colonnes 11-13, E/O rangées 6-8. Intérieurs restent en rangée 5 (RÈGLE : aucun écran en y=4 sauf (2,4)).
  SAUVEGARDE v2 : `{"version":2, scene, ecran (nom), case [x,y], drapeaux, records}` ; chargement par NOM d'écran + `point_arrivee()` si case bloquée.
  Migration v1 (pixels) dans `Etat.charger` : village -> table `ANCIENNE_GRILLE_VILLAGE` (ancienne grille -> nom) ; donjons/corps -> écrans réels (grilles inchangées) ; puis réécriture en v2.
  Repli : InterieurHeros sans `capitaine_vu`, sinon PlaceDuCoq. Test : bouton F1 « Simuler une vieille sauvegarde ».
  ORDRE : 1) sauvegarde v2 sur la carte ACTUELLE ; 2) factoriser generer_village.py (`ecran(sorties=...)`) + `Outils/verifier_carte.py` ; 3) déplacer/créer les écrans ; 4) réécrire textes géographiques ; 5) secrets, girouette, PNJ.

- 2026-11-13 : nouveau pack ajouté par l'utilisateur : `Assets/Pixel Crawler - Free Pack/` (Anokolisa, cases 16 px, vue 3/4). Licence : usage commercial OK, modifs OK, pas de revente des assets seuls ni du pack ;
  crédit facultatif. Contenu : arbres (3 modèles x 5 tailles, ~60-100 px), buissons/fleurs/herbes (`Vegetation.png`), sols herbe/terre/neige (`Floors_Tiles.png`, blocs 3x3 avec coins), eau (`Water_tiles.png`), toits/murs de maisons en bois
  (`Roofs.png`, `Walls.png`, style isométrique), mobiliers, cuisines/forge, et PERSOS = corps nus à habiller (couches `Body_A`, 64x64) + `Npc's` (Knight, Wizzard, Rogue, Citizen_F). Pas encore utilisé sauf l'eau (rivière). À EXPLOITER à l'étape « audit des packs / style du village ».
- 2026-11-13 : **ÉTAPE 14a écrite (non testée dans Godot ; carte vérifiée par `Outils/verifier_carte.py`)** = CARTE EN COQ du village (plan validé) :
  1) SAUVEGARDE v2 (`etat.gd`) : `ecran_sauve` + `decalage_sauve` (nom d'écran + position en pixels dans l'écran), fichier `version: 2` ; migration v1 -> v2 par `ANCIENNE_GRILLE_VILLAGE` ; `world.gd::_position_reprise()` retrouve l'écran PAR SON NOM, repli sur `point_arrivee()` si la case est bloquée
     (`Ecran.position_bloquee`, redéfini dans `exterieur.gd`), repli sur InterieurHeros/PlaceDuCoq si l'écran n'existe plus. F1 -> « Simuler une vieille sauvegarde (village) ».
  2) `generer_village.py` factorisé : `ouvrir(g, cote, prof)` creuse une sortie (chemin 3 cases + arbres retirés), `fermer_bords` ferme tout le reste par des buissons, `finaliser(g, sorties)`, tables `SORTIES` / `PROFONDEURS`. `Outils/verifier_carte.py [--carte]` : bords cohérents, tout atteignable, portes/passages OK, PNJ/animaux libres.
  3) NOUVELLE GRILLE : y=0 TempleGauche (1,0) / Parvis (2,0) / TempleDroit (3,0) ; y=1 Verger (1,1) / GrandChemin (2,1) / TerrainGarde (3,1) ; y=2 VillageOuest (1,2) / PlaceDuCoq (2,2) / VillageEst (3,2) ;
     y=3 MaisonHeros (1,3) / Riviere (2,3) / Ferme (3,3) ; y=4 RouteSud (2,4) (barrière + garde, sud fermé jusqu'à la fin) ; intérieurs toujours rangée 5.
     Écrans NOUVEAUX : Verger (pommiers, jardinier Anselme), TerrainGarde (enclos d'entraînement, soldat Hugues), Riviere (rivière rangées 3-4 + pont colonnes 11-13, pêcheur Bastien), RouteSud (garde de la route).
     Écrans DÉPLACÉS/refaits : MaisonHeros (porte (6,6)), Ferme (enclos à droite, grange (5,6), entrée ouest + nord), VillageOuest (stand de tir : porte (17,6)), VillageEst (caserne : porte (18,6), capitaine (16,7)). Temples : + sortie sud.
  4) RIVIÈRE : lettres `~` (eau, bloque) et `=` (pont) dans `exterieur.gd` (rive claire selon les voisins, 2 images qui alternent toutes les 0,7 s) ; images `v_eau*`, `v_pont_*` par `Outils/fabriquer_riviere.py` (eau du pack Pixel Crawler).
  5) Textes géographiques de Maman/capitaine/indice corrigés (caserne = à l'est de la place) ; `gardien.gd` retour en (18,7). RESTE (étape 5 du plan) : secrets (bois/cascade), girouette redessinée, PNJ restants/style, route du sud ouverte à l'épilogue, panneaux.
  ORDRE DES OUTILS village : traiter_village -> traiter_village2 -> fabriquer_maisons -> traiter_pack_aesthetic -> fabriquer_riviere -> generer_village -> verifier_carte.

- 2026-11-13 : utilisateur : « j'ai testé, tout marche » (carte en coq 14a OK). **ÉTAPE 14b écrite (non testée dans Godot ; aperçus PIL fidèles vérifiés)** = GIROUETTE + STYLE PIXEL CRAWLER + HABITANTS :
  1) GIROUETTE redessinée (`Outils/fabriquer_objets.py::girouette_mat/girouette_coq`) : socle de pierre rond à 2 marches, mât de fer, boule dorée, croix des points cardinaux avec plaques O/E/N/S ; coq de PROFIL dessiné à la main (crête, bec doré, barbillon, queue verte et rouge, perchoir de fer), toujours 48x64 + coq qui se retourne (code inchangé).
  2) STYLE DU VILLAGE : `Outils/traiter_pixel_crawler.py` (à lancer APRÈS traiter_pack_aesthetic.py, AVANT generer_village.py) remplace les `v_*.png` de nature par ceux de Pixel Crawler : herbe/chemin (couleurs du pack, fabriqués par traiter_village2), 2 feuillus (32x62), sapin, buissons, fleurs, touffes, roche.
     Les arbres sont plus hauts (62 px) mais gardent l'emprise 2x2. PAS touchés : maisons (code), caserne/temple, clôtures, puits, panneau, tonneau, caisse, bannière, étal, intérieurs (restes d'autres packs).
  3) HABITANTS : `Outils/preparer_pnj_pixelcrawler.py` (après preparer_pnj.py) écrit `Assets/Heros/pnj_<Nom>.png` depuis les persos du pack (Citizen_F, Knight, Rogue, Wizzard, recolorés) : Woman, Villager, Villager5, Villager4 (capuche), OldMan (mage vert), KnightGold, Villager3 (soldat), Boy.
     Ils sont de PROFIL seulement : gauche = miroir, haut/bas = profil. LIMITE : ils sont plus grands/détaillés que le héros LPC (style qui jure un peu) -> proposer de remplacer AUSSI le héros par un perso du pack.
  4) Nouvel outil `Outils/apercu_village.py sortie.png Ecran...` = aperçu fidèle d'écrans du village (images + emprises lues dans exterieur.gd, habitants dessinés).
  ORDRE DES OUTILS village : traiter_village -> traiter_village2 -> fabriquer_maisons -> traiter_pack_aesthetic -> traiter_pixel_crawler -> fabriquer_riviere -> generer_village -> verifier_carte (+ preparer_pnj -> preparer_pnj_pixelcrawler pour les habitants).

- 2026-11-13 : retours 14b : « la rivière est moche, les arbres beaucoup mieux, pas fan des PNJ (les faire bouger pour voir s'il faut les remplacer), girouette bien mais un peu grosse ». **ÉTAPE 14c écrite (non testée dans Godot ; aperçus PIL vérifiés)** :
  1) RIVIÈRE refaite : AUTOTILE comme le chemin (`Outils/fabriquer_riviere.py` : `v_eau_<bits>_<1|2>` et `v_eau_f<coins>_<1|2>`, rive en terre mouillée + liseré sombre + écume, reflets qui bougent) ; `exterieur.gd::_nom_eau` ; la rivière SERPENTE sur 3 rangées (`rangees_eau(x)` dans generer_village.py), pont `=` colonnes 11-13 rangées 2-4. Écran Rivière : sortie nord = rangées 0-1.
  2) GIROUETTE réduite x0,75 : image 48x48, emprise 3x3 (au lieu de 3x4), coq posé en (24,13) ; plaques O/E/N/S sans lettres (illisibles à cette taille).
  3) HABITANTS ANIMÉS : `Outils/preparer_pnj_pixelcrawler.py` écrit aussi `pnj_<Nom>_repos.png` (4 images) et `pnj_<Nom>_marche.png` (6 images) ; `pnj.gd` est maintenant un CharacterBody2D : repos animé, PROMENADE lente (16 px/s) dans un petit rayon autour de sa place (34x16 px),
     s'arrête et se tourne (miroir) vers le joueur à moins de 56 px ou pendant un dialogue ; s'arrête s'il heurte un obstacle. Sans ces images (anciens habitants) : comportement d'avant. But : juger visuellement s'il faut REMPLACER les habitants (pack Pixel Crawler jugé « pas fan »).
  PISTES si les PNJ déplaisent : planches LPC variées (générateur), ou recolorer/agrandir le héros pour harmoniser, ou retour aux Ninja Adventure 16x16 (plus petits, plus simples).

- 2026-11-13 : retour 14c : « j'aime bien la femme ; soldats et pêcheur : on dirait qu'ils n'ont pas de bras ; ils ne bougent pas assez ». **ÉTAPE 14d écrite (non testée dans Godot ; planches vérifiées en image)** :
  1) `Outils/habiller_pnj.py` (à lancer APRÈS preparer_pnj_pixelcrawler.py) : HABILLE le corps nu `Body_A` du pack (repeint par zones : cheveux, tunique, manches/armure, ceinture, pantalon, bottes, casque, chapeau de paille) -> habitants VUS DE 3 CÔTÉS (bas, haut, côté) avec bras visibles :
     Villager3 (soldat : casque + armure grise), KnightGold (capitaine : armure dorée, tunique rouge), Villager4 (pêcheur : chapeau de paille, tunique verte). Planches `repos` (4 images x 3 rangées) et `marche` (6 x 3). Les autres habitants (Woman, Villager, Villager5, OldMan, Boy) restent à 1 rangée (profil).
  2) `pnj.gd` : planches à 1 ou 3 rangées (`_rangees`, `_orienter`, `_montrer`) ; promenade plus ample (60x30 px autour de la place), plus rapide (22 px/s), pauses courtes (0,8-3 s) ; il se tourne vers le joueur (haut/bas/côté) quand on approche.
  Limite : le corps du pack est « grosse tête » : à juger au test ; sinon passer à des planches LPC variées.

- 2026-11-13 : utilisateur : « refais les maisons dans le style du pack ». **ÉTAPE 14e écrite (non testée dans Godot ; aperçus PIL fidèles vérifiés)** : `Outils/fabriquer_maisons_pixelcrawler.py` (à lancer APRÈS traiter_pack_aesthetic / traiter_pixel_crawler, AVANT generer_village) refait `v_maison_orange/bleue/chaume/rouge/pierre/bois/caserne`
  avec Pixel Crawler : mur à colombages de face (Walls.png, 5 pièces = 112 px, types fenêtres / plein / brique / planches), porte arrondie à ferrures au milieu (colonne 3), 2 fenêtres (carreaux ou volets verts), grand toit du pack (126 px) recoloré (brun, bleu, chaume, rouge, gris-pierre, brun sombre, vert menthe pour la caserne),
  pignon de planches sous la crête (le creux du toit laissait voir l'herbe). Sprites 128x127, emprise 7x4 INCHANGÉE (exterieur.gd/generer_village.py non modifiés) ; le toit dépasse d'environ 15 px au-dessus de l'écran pour les maisons de la rangée 3.
  Restent dans l'ancien style : temple/corps du coq (`U`, `Z`), étal `E`, tonneau, caisse, bannière, clôture, puits, panneau, intérieurs. ORDRE DES OUTILS village : ... traiter_pixel_crawler -> fabriquer_maisons_pixelcrawler -> fabriquer_riviere -> generer_village.

- 2026-11-13 : l'utilisateur ajoute `Assets/TILESET VILLAGE TOP DOWN/` (Jadson Holanda : herbe/terre 16 px, 3 arbres ronds 48x48, HOUSE 1 80x112 / HOUSE 2 128x112 / CHURCH 128x112, clôtures, puits, pont, escalier, TERRASSES à falaise, eau ; pas de fichier de licence dans le dossier : À VÉRIFIER) :
  « c'est mieux, inspire-toi de l'image (`(THANK YOU).png`), je veux du RELIEF dans le village ». **ÉTAPE 14f écrite (non testée dans Godot ; aperçus PIL fidèles vérifiés, `verifier_carte.py` OK)** :
  1) `Outils/traiter_village_jadson.py` (APRÈS les autres traiter_*/fabriquer_maisons, AVANT fabriquer_riviere + generer_village) remplace sol (herbe franche + 6 variantes à détails `v_herbe_sol_1..6`, chemin de terre autotile), arbres (`v_arbre_a/b`, `v_sapin` = vert/roux/fleuri, 48x48 = emprise 3x3), buissons, fleurs, roche, souche, clôture, puits, MAISONS (HOUSE 1/2 recolorées),
     temple (`v_temple_entree` = l'église), et fabrique le RELIEF : `v_ter_<rangée 0-3><colonne 0-2>` (12 morceaux de terrasse, centre = herbe unie) et `v_escalier`.
  2) `exterieur.gd` : emprises maisons M/S/L/K/U 8x3, N/T/R 5x3 (porte colonne 2 ; temple colonne 3), arbres 3x3, roche 1x1, 24 « hasards » de sol (1 case sur 4 avec détail) ; NOUVEAUX exports `terrasses` ("x y largeur hauteur", largeur >= 3, hauteur >= 4) et `escaliers` ("x y" = coin haut-gauche, 2x4 cases) -> `_poser_relief` :
     dessus marchable, bord + falaise solides, les escaliers percent la falaise (seul accès).
  3) `generer_village.py` : maisons et portes aux MÊMES coordonnées qu'avant (helpers `maison`/`grande` adaptés), `bordure` = une rangée d'arbres 3x3 en haut/bas, `nettoyer_arbres` retire les arbres 3x3 gênants (chemin, eau, terrasse, hors écran, chevauchement), `cases_relief`.
     RELIEF placé dans : Verger (terrasse à droite), TerrainGarde (estrade d'entraînement à gauche), RouteSud (canyon à 2 terrasses). Les autres écrans sont à plat : en ajouter = `terrasses`/`escaliers` dans `ecrans` + `RELIEF`.
  4) `fabriquer_riviere.py` recoloré (eau du pack). `verifier_carte.py` et `apercu_village.py` gèrent le relief. Ferme : fermière en (12,5), départs des poules déplacés.
  ORDRE DES OUTILS village : traiter_village -> traiter_village2 -> fabriquer_maisons -> traiter_pack_aesthetic -> traiter_pixel_crawler -> fabriquer_maisons_pixelcrawler -> traiter_village_jadson -> fabriquer_riviere -> generer_village -> verifier_carte.
  Restent à l'ancien style : tonneau, caisse, bannière, étal, panneau, corps du coq (`Z`), intérieurs ; le pont du pack (arqué, horizontal) n'est pas utilisé (pont maison). Idées : terrasses avec maisons dessus, falaises en lisière, escaliers vers un secret.

- 2026-11-13 : utilisateur : « refais les intérieurs dans ce style, vérifie les collisions des maisons (on a l'impression de passer en dessous quand on entre), et plus de relief ». **ÉTAPE 14g écrite (non testée dans Godot ; aperçus PIL fidèles vérifiés)** :
  1) INTÉRIEURS : `Outils/traiter_interieur_pixelcrawler.py` (APRÈS traiter_village.py, AVANT generer_village.py) refait avec Pixel Crawler (`Interior_Walls_01`, `Interior_Props_01`) les images attendues par `interieur.gd` : sols (parquet, pierre), murs (pans planches/pierre, fenêtre, tableau, cheminée = four en briques), lits, étagère, armoire, tables, chaise, coffres, tonneau, seaux, banc, râteliers, boucliers ; tapis et paillasson dessinés en code.
     Emprises de `MEUBLES` adaptées (lits L/l 2x3, armoire 2x3, tables U/M 4x2, râteliers 4x2, boucliers 2x1). Plans de la caserne retouchés (J en (15,7), Soldat Gilles en (13,7)).
  2) PORTES : `exterieur.gd` garde le héros DEVANT la maison près d'une porte (`_cases_portes`, avant il pouvait passer « derrière/en dessous ») ; `world.gd::_passer_porte` : en entrant dans un bâtiment le héros s'estompe dans l'ombre de la porte pendant son pas. Collisions des maisons relues avec le nouvel outil
     `Outils/apercu_village.py --collisions sortie.png Ecran...` (cases bloquantes en rouge) : l'emprise = les murs (bas de la maison), le toit dépasse sans bloquer, la case de la porte est libre (marche du perron).
  3) RELIEF en plus : GrandChemin (2 collines), Parvis (2 terrasses qui encadrent la stèle), VillageEst (colline au nord-ouest) ; fleurs/souches/cailloux sur les terrasses. Total : 6 écrans avec relief.
  `apercu_village.py` sait dessiner les intérieurs (`InterieurHeros`, `InterieurCaserne`, `InterieurStand`).

- 2026-11-13 : utilisateur : « coffres et secrets sur les terrasses (des reliefs ne mènent à rien) ; un PNJ avec du vert a des couleurs bizarres ; l'entrée des maisons fait téléportation (porte fermée) ; les temples ne doivent pas être des églises mais de vraies ENTRÉES DE DONJON façon Zelda ; refaire l'intérieur des donjons si le nouveau pack est mieux ».
  **ÉTAPE 14h écrite (non testée dans Godot ; aperçus PIL vérifiés, `verifier_carte.py` OK)** :
  1) COFFRES et SECRETS : `exterieur.gd` exports `coffres` ("x y drapeau | texte") et `secrets` ("sx sy cx cy drapeau | texte" : rocher fissuré `Scripts/secret_pierre.gd`, un coup de lance le brise et révèle un coffre) ; réutilise `coffre.gd` (texte avec `%d` = nombre d'insignes) ;
     récompense = INSIGNES de la Garde (`Etat.nombre_insignes()`, drapeaux `insigne_*`, `TOTAL_INSIGNES` = 9, affichés au tableau d'honneur). 9 coffres : GrandChemin x2, Parvis x2 (un caché), VillageEst, Verger, TerrainGarde, RouteSud x2 (un caché). Images `insigne`, `v_roche_fissuree` (traiter_village_jadson.py).
     Données dans `generer_village.py::COFFRES` ; `verifier_carte.py` vérifie que chaque coffre/rocher est atteignable ; `apercu_village.py` les dessine. GrandChemin : forêt des côtés retirée (les collines la remplacent, pied d'escalier relié au chemin).
  2) PORTES : `exterieur.gd::ouvrir_porte(case, durée)` (rectangle sombre qui s'ouvre sur la porte, puis se referme) ; `world.gd::_passer_porte` l'ouvre avant le pas d'entrée (0,25 s), la rouvre derrière le héros quand il sort.
  3) ENTRÉE DE DONJON (lettre `U`, 7x3, porte colonne 3) : colline (morceaux de terrasse) percée d'une arche de pierre sombre du pack, 2 torches, marche (`traiter_village_jadson.py`) ; ce n'est plus l'église.
  4) PNJ : pêcheur (tunique qui « mangeait » le menton : tête jusqu'à r<0,37) et mage (robe vert sauge sobre, `decaler_teinte(..., lum)`).
  5) DONJONS : comparé le pack Pixel Crawler (`Dungeon_Tiles`, `Wall_Tiles`, `Dungeon_Props`) au décor Craftpix actuel : style proche (pierre sombre, herses, bannières), pas de gain net -> NON remplacé. Pistes si voulu : bannières 3 couleurs du pack, sol sanglant/drain, herses/pics du pack.

- 2026-11-13 : utilisateur : « bug dans la caserne : bloqué sur la table en entrant ; le pêcheur a toujours un peu de vert au menton ; l'aspect colline des donjons ne fait pas assez solennel ; pour les donjons, chercher des murs mieux faits dans les packs importés ».
  **ÉTAPE 14i écrite (non testée dans Godot ; aperçus PIL vérifiés, `verifier_carte.py` OK)** :
  1) CASERNE : la table de carte (4x2 cases) couvrait la case d'arrivée (12,9) -> déplacée en (8,8). `verifier_carte.py` vérifie maintenant aussi les INTÉRIEURS avec les emprises réelles des meubles (lues dans interieur.gd) : arrivée libre, habitants/portes atteignables.
  2) PÊCHEUR : menton repeint par la tunique -> zone « tête et cou » jusqu'à r<0,43 (`habiller_pnj.py`). Les yeux restent verts (couleur d'origine du corps du pack).
  3) ENTRÉE DE DONJON (lettre U) REFAITE : plus de colline ; FAÇADE DE PIERRE à créneaux, corniche, pilastres, 2 bannières rouges à croix, 2 torches, grande arche sombre ouverte ; briques/arche/pilier/bannière/torche du pack Craftpix (déjà découpés dans `Assets/Gemini/tuiles/`), construite dans `traiter_village_jadson.py` (112x72, emprise 7x3, porte colonne 3).
     `exterieur.gd::ouvrir_porte` ne fait rien pour `U` (l'arche est déjà ouverte).
  4) MURS DE DONJON : `Outils/fabriquer_niches.py` (APRÈS traiter_pack_donjon.py) : `mur_fond` = BRIQUES assombries (plus de vide noir : les murs épais paraissent maçonnés) et `niche_grille.png` (arche à barreaux réduite) posée dans le mur du haut des salles claires (`room.gd::COLONNES_NICHES` [9, 14]). `apercu_salle.py` les montre.
     Comparé aux autres packs : Craftpix `walls_floor.png` (dalles claires à biseau, murs à arches/portes en bois, escaliers, piliers) et Pixel Crawler `Dungeon_Tiles` (pierre bleu-vert, herses, bannières 3 couleurs) : pistes pour aller plus loin (dalles de dessus de mur claires, escaliers, arches/portes en bois dans les murs).

- 2026-11-13 : utilisateur : « va plus loin pour les murs ; un effet d'ESCALIER en entrant dans le donjon ; les statues jurent (pas assez détaillées) ».
  **ÉTAPE 14j écrite (non testée dans Godot ; aperçus PIL vérifiés)** :
  1) MURS DE DONJON : `Outils/fabriquer_murs_donjon.py` (APRÈS traiter_pack_donjon.py et fabriquer_niches.py) refait `mur_bord_n/s/e/o`, `mur_coin_*`, `mur_dot_*` : COUVERTINE de dalles claires (biseau lumineux, joints, ombre) sur 6 px le long du sol, sur les briques sombres de `mur_fond` -> murs épais maçonnés (plus de fins liserés dans le vide).
  2) ESCALIER : `Outils/fabriquer_escalier.py` -> `escalier_donjon.png` (48x48, marches de plus en plus sombres vers le nord, rampes) ; `room.gd` export `escaliers_descente` ("x y", 3x3 cases) posé par-dessus les tapis (`_poser_escaliers`), placé en (11,9) dans les deux vestibules (generer_monde.py / generer_aile_droite.py, qui acceptent maintenant `PackedStringArray(...)`).
     Arrivée au donjon en (12,11) (`generer_village.py`) ; `Etat.arrivee_descente` (posé par `world.gd::_changer_de_scene` pour « Vestibule » des scènes donjon / aile_droite) -> `world.gd::_descendre_escalier()` : après le fondu, le héros monte 3 marches (16 px, 0,42 s chacune) avec un PAS DE PIERRE qui résonne (`Assets/Sons/pas_pierre.wav`, fabriqué par `Outils/fabriquer_sons.py`) et entre peu à peu dans la pénombre, puis reprend la main.
  3) STATUES : `Outils/fabriquer_statues.py` (APRÈS fabriquer_objets.py) redessine `statue_chevalier` (armure, heaume à cimier, épée, écu à croix) et `statue_oiseau` (coq de pierre : crête, bec, queue, aile) en 22x34 sur piédestal biseauté, ombrage haut-gauche ; décalage (-3, TUILE-34) dans `room.gd`, `chanteur.gd` (collision 16x30), `apercu_salle.py`.
  Aucune statue n'existe dans les packs importés : elles sont dessinées en code.

- 2026-11-13 : statues dessinées en code jugées « horribles » -> l'utilisateur les a fait générer par Gemini (`Assets/Gemini/originaux/statues.jpg`, 4 colonnes x 2 rangées, fond magenta en dégradé).
  **ÉTAPE 14k écrite (non testée dans Godot, aperçu PIL vérifié)** : `Outils/traiter_statues.py` (À LANCER APRÈS `fabriquer_statues.py`, qui n'est plus qu'un repli) découpe, détoure (clé magenta + plus grande composante), réduit en 22x34 (alignées en bas) -> `statue_chevalier` (épée, utilisée par `S`), `statue_oiseau` (coq vers la droite, `O` et le chanteur `C`),
  + disponibles, pas encore branchées : `statue_lance`, `statue_oiseau_g` (coq vers la gauche), `statue_oiseau_d2`, `statue_capuche`, `statue_gargouille`, `statue_gargouille_ailee`. Offsets inchangés (-3, TUILE-34). Aperçu : `Outils/apercus/statues.png`. Idée : lettres pour capuche/gargouille dans les salles, coq inversé pour la symétrie de l'aile droite.

- 2026-11-13 : statues Gemini validées par l'utilisateur. Retours : « levier et blocs de couleur jurent, levier trop petit, pots mis au hasard ». **ÉTAPE 14l écrite (non testée dans Godot, aperçu PIL vérifié)** :
  1) LEVIER redessiné plus gros (`Outils/fabriquer_levier.py`, APRÈS traiter_pack_donjon.py : 16x24, socle de pierre, tige d'acier, pommeau rouge) ; `levier.gd` décale le sprite de -8 px ; `apercu_salle.py` aussi.
  2) PLOTS (`plot.gd`) et DALLES de couleur (`dalle.gd`) : pierre du donjon (mêmes tons que murs/piliers) + cabochon de couleur ATTÉNUÉE, au lieu d'aplats saturés.
  3) POTS en grappes dans les coins / le long des murs (`generer_monde.py`, `generer_aile_droite.py`) : Vestibules, Entrées, Plumes 1, 2a, 2b, 3a-3c, 5b, 5d (gauche). NON touchées (puzzles à solveur/rayons/sentinelles) : plumes 4, 5a/c/e, D1-D5 sauf Entrée droite ; le pot de la plume 1 (10,9) est une énigme.
  Scènes régénérées (`world.tscn`, `aile_droite.tscn`) ; solveurs `resoudre_d5.py` et `simuler_sentinelles.py` relancés OK.

- 2026-11-13 : retours 14l : « eau pas naturelle au début du donjon, levier mal placé (à mettre contre le mur), blocs de couleur jurent encore -> prompt Gemini ». **14m (non testée dans Godot)** : bassins d'eau RETIRÉS de l'Entrée droite ;
  LEVIER MURAL (`fabriquer_levier.py` : plaque rivetée sur le mur + rebord, sprite décalé de -12 px) posé rangée 2 contre le mur du haut : Entrée droite (12,2), D5a (21,2). Plots/dalles de couleur : prompt Gemini donné à l'utilisateur
  (planche : plots orange/bleu levés + baissés, dalles rouge/bleu + dorée, magenta #FF00FF) ; À FAIRE à réception : `Assets/Gemini/originaux/plots.jpg` -> découper/réduire 16 px, brancher dans `plot.gd` et `dalle.gd` (images au lieu de ColorRect).

- 2026-11-13 : `plots.jpg` reçu (Gemini, vue isométrique). **14n (non testée dans Godot, aperçu PIL vérifié)** : `Outils/traiter_plots.py` -> `plot_haut_o/u` (cubes de pierre 16x18), `cristal_o/u` (pas encore branchés), `dalle_rouge/bleue/doree` (16x16).
  `plot.gd` : plot LEVÉ = image `plot_haut_*` (le baissé reste dessiné en code : dalle de pierre + cabochon) ; `dalle.gd` : sprite qui alterne les 3 images (`textures` fournies par `room.gd`). Non utilisés : dalles losanges, levier et piédestal Gemini (vue de côté), cristaux de l'énigme.

- 2026-11-13 : nouvelle planche `plots.jpg` (vue de FACE, non isométrique, traits noirs de grille entre les cases -> `MARGE` dans l'outil). **14o (non testée dans Godot, aperçu PIL vérifié)** : `traiter_plots.py` produit aussi `plot_bas_o/u` ; `plot.gd` n'est plus dessiné en code (images `plot_haut_*` / `plot_bas_*`) ;
  dalles de couleur = `dalle_rouge/bleue/doree`. Disponibles, non branchés : cristaux `cristal_o/u`, plaque de levier Gemini (2 poses seulement), bouton rond rouge.

- 2026-11-13 : retour : « la grille qui s'ouvre (salle D2b) fait demi-porte ». Cause : `arche_basse_*` (porte intérieure 48x16, mur d'1 rangée) = BAS d'une arche. **14p (non testée dans Godot, aperçu PIL vérifié)** : `Outils/fabriquer_porte_basse.py` dessine un portique complet (linteau de briques, 2 montants, ouverture sombre, grille qui se relève en 5 images) -> `arche_basse_1..5.png` ; à relancer APRÈS `traiter_pack_donjon.py` (qui écrit l'ancienne version).

- 2026-11-13 : **AUDIT (joueur Zelda + développeur) puis CORRECTIONS 15a** (l'utilisateur : « fais tout sauf 3 (objets/récompenses) et 4 (style unique), que je ferai avec Opus ; PI gérée, ne plus en parler »).
  GODOT 4.4.1 headless téléchargé côté Claude (scratchpad, non versionné) : le code a ENFIN été chargé dans un vrai Godot. `Tests/verifier_scenes.gd` (à lancer : `godot --headless --path . -s res://Tests/verifier_scenes.gd`, code de sortie 0 = bon) :
  charge les 4 scènes, visite chaque écran (F1), vérifie plans 25x14 et grilles uniques, lance 5 s de la vue aérienne, teste les contrôles tactiles. Résultat : TOUT BON. Bugs trouvés/corrigés : signal `tree_exiting` connecté en double dans `room.gd::_suivre` (139 erreurs), `Etat.memoriser_position` sans scène courante, `Etat.sauvegarde_active` (faux pendant les tests).
  ATTENTION : lancer Godot 4.4 réécrit ~2750 fichiers `.import` (projet en 4.7) -> toujours `git checkout` des `.import` modifiés avant de commiter.
  1) CONTRÔLES TACTILES : `Scripts/tactile.gd` (class Tactile, ajouté dans `world.gd::_ready`) : joystick flottant (moitié gauche), boutons A (attack), B (run), R (reset), appui ailleurs = avancer un dialogue ; invisible sans écran tactile ou après une touche clavier ; vrais `InputEventAction`.
  2) D5b RAMENÉE DE 29 À 23 COUPS (plan trouvé par `Outils/chercher_d5b.py`, recherche aléatoire + solveur) : reflet (8,2), dalles (8,4)/(18,9), herse bleue rangée 8, cristal (10,9). `resoudre_d5.py` mis à jour. Indice réécrit. D5c/d/e inchangées (17/19/26 coups).
  3) DÉCOUPAGE : `world.gd` 990 -> 808 lignes : la cinématique de vue aérienne est dans `Scripts/vue_aerienne.gd` (class VueAerienne, `VueAerienne.new(self).jouer(cote)`, accède au monde via `monde.`). `room.gd` (1150 lignes) PAS découpé : ses sections (sentinelles, rayon, chant, reflet) partagent trop d'état ; à faire avec le test comme filet.
  4) À FAIRE (Opus) : points 3 (objets + récompenses : outil par aile, effets des insignes) et 4 (style visuel unique). Reste : session de test humaine de 10a-14p, build web mobile (export), perf web.

- 2026-11-13 : **NOUVELLE RÈGLE DE DESIGN (utilisateur)** : les énigmes doivent être VISUELLES, à la Zelda : on les comprend SANS AUCUN TEXTE (forme de la salle, objets, couleurs, sons, animations qui montrent la règle).
  L'utilisateur repassera sur CHAQUE énigme (aile gauche : vestibule, plumes 1-5 ; aile droite : entrée, D1-D5) pour dire quoi changer. Donc : ne PAS refactorer `room.gd` avant ce passage (son contenu va bouger) ;
  à terme, retirer les `indice` textuels et les messages de règle (ex. dalles, glace, reflet) au profit d'indices visuels. Faire UNE énigme à la fois, sur retour de l'utilisateur.

- 2026-11-13 : **ÉNIGME 1 REVUE (Plume 1, aile gauche) — énigme visuelle sans texte** : colonne de 3 BLOCS (x=18, rangées 7-9) + colonne de 3 MARQUES dorées au sol (x=12, mêmes rangées) -> on pousse chaque bloc vers la gauche sur sa marque ; les 3 posés = porte du fond (`p1_plaque`).
  Plus de pot ni de bouton dans cette salle. NOUVEAU DESIGN : `Outils/fabriquer_bloc.py` (APRÈS traiter_gemini.py) -> `bloc_pierre(_actif)` (pierre bleu-gris des murs/plots, rune creusée ; dorée quand le bloc est sur une marque : `Bloc.briller`) et `marque(_active)` (gravure au sol + losange doré, remplace le bouton rond).
  S'applique à TOUS les blocs et lettres `P` (aussi D4c/D4d/D5c ; le reflet allume la marque). Test auto : `Tests/verifier_scenes.gd` pousse les 3 blocs et vérifie l'ouverture.
  MÉTHODE pour la suite : à chaque salle revue, l'utilisateur veut l'AVIS de Claude (forces/faiblesses) avant de modifier.

- 2026-11-13 : **ÉNIGME 2a REVUE (Plume 2a, salle sombre) = « LA TÊTE DE COQ »** (idée de l'utilisateur, validée) : 12 braseros `L` dessinent une tête de coq de profil (crête à 3 pointes, bec, barbillon, œil = le dernier). Un trait doré pâle (pointillé) est GRAVÉ au sol entre eux, dessiné dans un CanvasLayer au-dessus de l'obscurité (visible dans le noir) ;
  on les allume à la lance DANS L'ORDRE du tracé : le prochain pulse + anneau, un mauvais brasero ou 24 s écoulées éteint tout (éclair rouge + Cancel.wav) ; les segments reliés s'illuminent ; dessin complet = tout reste allumé, la porte s'ouvre (`p2_braseros`). Un brasero `B` toujours allumé près de l'entrée. Aucun texte.
  CODE : `room.gd` exports `chemin_braseros` ("x y" dans l'ordre) + `duree_chemin`, section « Les braseros tête de coq » (`_ordonner_braseros`, `brasero_frappe`, `_echouer`, `_rearmer_chemin`, `_gerer_chemin`, `_dessiner_chemin`) ; `brasero.gd` : `ordonne`, `attendu`, `vie` (la flamme rétrécit). Les braseros SANS `chemin_braseros` gardent l'ancien comportement (autres salles, sentinelles 4d). Plan et ordre : `COQ` dans `generer_monde.py`.
  Test auto : mauvais ordre refusé, ordre correct = flag. Idées non faites : tête de coq gravée SUR la porte, brasero plus visible.

- 2026-11-13 : l'utilisateur travaille désormais sur la branche `main` (GitHub Desktop). Retours : Plume 1 = « dalles lumineuses en TRIANGLE, moins une ligne droite » -> FAIT : 3 marques en triangle pointe en haut vers la porte (12,6) / (9,8) / (15,8), 3 blocs alignés en bas (9,10) (12,10) (15,10) à pousser vers le haut (2, 2, 4 poussées) ; test auto adapté.
  Plume 2a : « pas fan de la tête de coq en lumière, pas hyper fun » -> la mécanique « allumer dans l'ordre » est à REMPLACER (code `chemin_braseros` conservé, inutilisé si on change). Propositions faites : (1) lance enflammée qu'on recharge au feu pour allumer des braseros lointains, (2) pont de lumière (sol qui n'apparaît que là où il est éclairé, course contre la montre). En attente du choix.

- 2026-11-13 : **ÉNIGME 2a REFAITE = « LA LANCE ENFLAMMÉE »** (choix 1 de l'utilisateur, remplace la tête de coq ; le code `chemin_braseros` de room.gd reste mais n'est plus utilisé). Salle sombre : un FOYER `l` (12,9) brûle en permanence ; le frapper à la lance ENFLAMME la lance 2,5 s
  (`player.gd` : `prendre_feu`, `eteindre_feu`, `a_feu`, flamme dessinée en code au-dessus de la tête qui rétrécit et clignote, lueur orange, pointe de lance rougeoyante ; Fire.wav) ; avec une lance enflammée, un coup sur un brasero `L` éteint l'allume POUR DE BON (`brasero.gd::_frapper_avec_feu`, mode `mode_feu` via l'export `braseros_feu` de la salle),
  et chaque brasero allumé redonne le feu (RELAIS). FLAQUES `w` (non bloquantes, images `flaque_1/2` par `Outils/fabriquer_feu.py`, lueur bleue dans le noir) : y entrer avec le feu l'éteint (Bubble.wav, `room.gd::_surveiller_flaques`). R éteint la lance et les braseros.
  PLAN : 6 braseros (15,10) (4,10) (20,10) (4,3) (12,3) (20,3), rivière de flaques rangée 6 (x 4..20, gaps x 2-3 et 21-22), 2 barrages x=7 et x=17 rangées 8-11 (B et C ne se rejoignent que par la rangée 7). Aucun texte. 6 allumés = porte du haut (`p2_braseros`).
  `Outils/verifier_feu.py` : vérifie la résolubilité (marche 8,75 cases/s, feu 2,5 s). Seul E (12,3) exige un relais ; les autres sont atteignables depuis le foyer : si c'est trop facile, réduire FEU_DUREE (player.gd + verifier_feu.py) ou rallonger les barrages. Test auto adapté.

- 2026-11-13 : retour : « les flaques sont moches, les cristaux (et "tape" ?) aussi ». FLAQUES REFAITES (15b) : `Outils/fabriquer_feu.py` fabrique 16 formes x 2 images `flaque_<bits>_<1|2>` (autotile : 1 nord, 2 sud, 4 ouest, 8 est), rive sombre arrondie + liseré clair + eau profonde + rides qui bougent (style `Assets/PNG/water_detilazation_v2.png` du pack Craftpix) ; `room.gd` choisit la forme selon les voisins `w` ; les flaques forment des canaux d'eau.
  CRISTAUX : AUCUN dans les packs (Craftpix : coffres, clés, tonneaux, pots ; Ninja Adventure : gemmes 16x16 d'inventaire) ; `cristal.gd` les dessine en Polygon2D (moche) -> demander une planche GEMINI (prompt donné à l'utilisateur) puis `Outils/traiter_cristaux.py` à écrire (découpe 16x24, états éteint/actif/frappé, versions orange et bleue pour les plots). Le mot « tape » de l'utilisateur est à clarifier (tapis ? plots ? dalles ?).

- 2026-11-13 : clarification : « les cristaux » = ceux qu'on frappe pour ouvrir une porte (vestibule, plume 2b, plots). CRISTAUX REFAITS (15c) sans nouvelle image Gemini : la planche des plots contenait déjà `cristal_u` (bleu) et `cristal_o` (orange) sur socle de pierre (16x18).
  `cristal.gd` n'est plus dessiné en polygones : image bleue qui « respire » (pulsation + halo) tant qu'il attend ; frappé = passe à l'orange doré avec éclat blanc qui retombe + halo vif ; commutateur des plots = bleu/orange selon les plots levés. Test auto OK.
  Leçon Git : après un Pull qui apporte des `.import` de l'utilisateur, relancer `godot --headless --import` côté Claude (sinon textures introuvables dans les tests), puis `git checkout` des `.import` modifiés et supprimer les `.import` non suivis créés par Claude.

- 2026-11-14 : **VISION DE LA FIN v2 (utilisateur, À VALIDER : reformulée par Claude, en attente de confirmation)** — l'utilisateur n'aime PAS la vue aérienne actuelle (mode 7 + image du blason) ni la cinématique de rassemblement. Sa vision :
  1) LES DONJONS FORMENT UN COQ : aile gauche d'un côté, aile droite de l'autre, corps + pattes au milieu (+ queue, tête). 2) DEUX STÈLES dont la FORME représente les PATTES du coq (au Parvis) : on y insère les 2 symboles (fragments d'aile).
  3) Les 2 insérés : la forêt s'ouvre ; on avance dans un AUTRE ÉCRAN pour voir la QUEUE (= par où on ENTRE dans le donjon final) et le CORPS (= salle du boss). 4) À l'insertion, le mécanisme se met en marche : le donjon S'ASSEMBLE, les ailes se remettent dans le bon sens à leur place.
  5) AUCUNE image de coq : en vue aérienne, ce sont les BÂTIMENTS (leurs formes seules) qui montrent que c'est un coq.
  Conséquences prévues (à faire après validation) : 2 stèles en forme de pattes (remplacent la stèle unique `Y`/`y`, drapeaux gauche/droite) ; nouvel écran au nord du Parvis (queue = entrée du donjon final, corps/boss à l'intérieur) ; cinématique aérienne refaite à plat (plan de tous les morceaux construit depuis les vrais `layout` des salles, ailes qui pivotent
  depuis les temples jusqu'aux épaules) SANS `blason_*.png` ; silhouette du coq (corps, tête + crête + bec, queue en éventail, pattes) construite avec des blocs de salles de même pierre que les ailes. Ancien code concerné : `world.gd::_ceremonie_stele`, `mode7.gd`, `Outils/fabriquer_plans_mode7.py`, `exterieur.gd::ecarter_foret`.

- 2026-11-14 : **VISION DE LA FIN v2 : RÉPONSES DE L'UTILISATEUR** : (1) ORDRE FORCÉ : d'abord l'aile GAUCHE, ensuite la DROITE ; un GARDE devant la droite dit qu'il faut d'abord réussir la gauche (emplacement exact à confirmer : entrée de l'aile droite ou stèle droite) ;
  (2) donjon final TRÈS SIMPLE : QUEUE = vestibule d'entrée -> on entre dans le CORPS : couloir -> boss (3 écrans empilés vers le haut) ; (3) vue aérienne À PLAT (carte vue de dessus, pas de perspective) ;
  (4) rejette : l'image du coq, un ensemble « pas construit », et les ENTRÉES D'AILES actuelles (arbres derrière la façade : on n'a pas l'impression d'entrer dans un bâtiment qui CONTINUE) -> les façades (temples gauche/droit, queue) doivent être de GRANDS BÂTIMENTS qui montent jusqu'en haut de l'écran
  (la suite est « sur l'écran du dessus », même si on ne le voit pas), SANS arbres derrière, murs latéraux qui continuent. L'aérien et le sol doivent rester cohérents.
  Ordre de travail proposé : A) garde + 2 stèles-pattes + insertion gauche puis droite ; B) façades refaites (2 temples + queue) ; C) vestibule/couloir/arène du boss ; D) IMAGE FIXE de la silhouette finale du coq faite de bâtiments (à valider par l'utilisateur AVANT d'animer) ; E) cinématique d'assemblage à plat.

- 2026-11-14 : **ÉTAPES A + B + C DE LA VISION DE LA FIN v2 FAITES (testées en headless, pas jouées)** : décisions de l'utilisateur : le garde est devant l'ENTRÉE de l'aile droite (pas devant la stèle) ; bâtiments non rectangulaires possibles (arches, tours).
  A) GARDE + STÈLES : `TempleDroit` a deux états (mécanisme `drapeau_revele` d'ecran.gd) : tant que `fragment_gauche` n'est pas levé (testé au CHARGEMENT de la scène village, qui se recharge après chaque donjon) : façade `G` (herse baissée), AUCUN passage, un GARDE (Villager3, `pnjs` avec direction « haut! » = fixe, `Pnj.fixe`) en (12,6) ;
  ensuite : façade `J` (herse levée), 3 passages vers l'aile droite, plus de garde (nouvel export `pnjs_revele`). PARVIS : DEUX STÈLES en forme de PATTES de coq (lettres `V` aile gauche en (10,4), `X` aile droite en (14,4) ; images `v_stele_g|d_vide|pleine` par `Outils/fabriquer_steles_pattes.py` : dalle + 3 griffes + niche au symbole d'aile),
  passages `$stele_g` / `$stele_d` en (10,5) / (14,5) (`Etat.stele_touchee(cote)`), `world.gd::_ceremonie_stele(cote)` : avec le fragment correspondant (et en montant), le symbole vole jusqu'à la niche, clac, la stèle s'allume (`Exterieur.allumer_stele`, drapeau `stele_gauche|droite`) ;
  les DEUX posés -> `_mecanisme_stele` : grondements, la forêt s'écarte (`ecarter_foret`), drapeau `corps_revele`, rechargement du Parvis « révélé » (arbres retirés, chemin du nord ouvert). `peut_changer_scene` (faux en test). SANS cinématique d'assemblage pour l'instant (étape E).
  B) FAÇADES (`Outils/fabriquer_facade.py`, après fabriquer_murs_donjon.py) : bâtiment de pierre 400x96 (25x6 cases) collé en haut de l'écran, mur du fond sombre qui CONTINUE vers le haut (pas d'arbres derrière), 5 tours pointues = plumes : AILE GAUCHE = tours de plus en plus hautes vers la droite (`F`),
  AILE DROITE = miroir (`J` ouverte, `G` herse baissée), QUEUE = éventail de 5 tours légèrement penchées aux pointes en FLAMMES (`H`) ; arche de 3 cases au centre (porte = 3 passages en rangée 5 : x 11-13). Écran NOUVEAU `Queue` (2,-1) au nord du Parvis (accessible une fois la forêt écartée).
  Ces façades sont solides (emprise 25x6) ; plus aucun arbre derrière. `apercu_village.py` les montre. `verifier_carte.py` fait maintenant 2 passes (état fermé, puis état « révélé » : forêt écartée + garde parti).
  C) DONJON FINAL (`Outils/generer_corps.py`, `corps.tscn`) : Vestibule (0,2) = la QUEUE (hall, 3 passages vers `@village:Queue 12 7`) -> Couloir (0,1) -> Arene (0,0, inchangée) ; monter à l'écran = grille y décroissante. Le Gardien est borné à l'arène (`_borner_a_l_arene`).
  Ancienne vue aérienne à la sortie d'une aile (`VueAerienne`, image du coq) COUPÉE (`VUE_AERIENNE_A_LA_SORTIE := false` dans world.gd) : on revient directement devant le temple. Reste D (image fixe de la silhouette du coq faite de bâtiments, à valider) et E (cinématique d'assemblage à plat) : à faire avec OPUS.
  Tests auto : `Tests/verifier_scenes.gd` (garde, stèles, forêt, donjon final). ORDRE des outils : fabriquer_facade.py (donjon) et fabriquer_steles_pattes.py (après fabriquer_objets.py) AVANT generer_village.py. Code de l'ancien mode 7 (`mode7.gd`, `fabriquer_plans_mode7.py`) conservé mais non utilisé.

- 2026-11-14 : l'utilisateur veut que l'assemblage du donjon (étapes D+E) soit « la partie ULTIME du jeu : classe et impressionnante » et pense à faire les PLANS FIXES avec GEMINI. AVIS DE CLAUDE (à confirmer) : OUI pour les images, en approche HYBRIDE : Gemini = les plans fixes (image du coq-forteresse vu du dessus, finale puis variantes), code = chorégraphie (caméra, ailes découpées qui pivotent, lueurs, runes, éclairs, secousses, sons, musique).
  Contraintes : le jeu est en 400x224 (stretch viewport, filtre Nearest) -> une image Gemini sera RÉDUITE (palette/pixel comme pour les statues) ; Gemini ne fait pas l'animation ; cohérence entre images difficile -> générer UNE image finale (coq assemblé) puis la faire ÉDITER (sans les ailes, ailes seules) ou découper les ailes par masques côté Claude.
  Prompts proposés à l'utilisateur : image finale (vue du dessus, à plat, forteresse en forme de coq héraldique de face : tête + crête à 3 tours + bec, corps = donjon rond, 2 ailes de 5 plumes-tours de longueurs croissantes, queue en éventail de 5 tours aux pointes en flammes, 2 pattes, sol sombre, route vers la queue, bannières rouges, runes dorées) ; puis variante « avant » (ailes détachées).
  En attente : l'utilisateur génère l'image finale et la dépose dans `Assets/Gemini/originaux/` (ex. `coq_forteresse.jpg`).

- 2026-11-14 : **IMAGE REÇUE : `Assets/Gemini/originaux/Coq_forteresse.jpg` (1408x768) — VALIDÉE par Claude.** Coq-forteresse vu du dessus (oblique léger) : tête = tour à 3 créneaux + bec (profil, à droite), corps = donjon rond avec COUR/ARÈNE intérieure (le boss !), 2 ailes = 5 coursives en escalier + grandes plumes de pierre aux pointes, queue = 5 couloirs qui convergent vers une porte basse
  (tours à torches), 2 GRIFFES de pierre (= le même motif que les stèles-pattes : cohérent), chemin de terre vers la queue, runes dorées sur les remparts.
  TEST DE DÉCOUPE (Python, masque polygonal + clé « vert = sol ») : OK, les ailes se détachent proprement, le trou se remplit avec du sol (à lisser : un peu tacheté, polygone à compléter sur les plumes du haut) ; l'aile peut pivoter autour de l'épaule (rotation de 35° vue comme une aile repliée qui s'ouvre).
  PROJET : cinématique HAUTE DÉFINITION : pendant l'assemblage on passe `get_tree().root.content_scale_mode` en DISABLED (la fenêtre de 1200x672 est rendue à sa vraie résolution) pour afficher l'image sans la réduire à 400x224, puis on remet le mode du projet. CALQUES à découper : ailes G/D, queue + griffes, tour de tête, donjon rond, sol ;
  chorégraphie : griffes qui s'enfoncent, donjon et queue qui montent du sol (poussière), tête qui se dresse, ailes qui pivotent et se verrouillent (flash, secousse), runes dorées qui s'allument une à une le long des remparts (chemins de lueurs additives), torches de la queue, zoom final vers la cour/arène.
  IDÉE DE L'UTILISATEUR (validée par Claude) : refaire aussi avec GEMINI les FAÇADES vues du village (entrées des 2 ailes + queue) et, en option, les 2 stèles-griffes, pour que tout ait la même qualité que l'image du coq. Prompts donnés à l'utilisateur (façade aile gauche ouverte ; aile droite herse baissée ; queue en éventail de tours-flammes ; planche des stèles).

- 2026-11-14 : retour utilisateur : « la stèle n'est pas exactement pareille que les pattes de l'image globale, qui sont déjà censées être la stèle ». **STÈLES REFAITES = LES VRAIES GRIFFES DE L'IMAGE** : `Outils/traiter_griffes.py` (remplace `fabriquer_steles_pattes.py`, supprimé) découpe les 2 griffes de `Coq_forteresse.jpg` (masque polygonal + clé « vert = sol »), réduit à 72x44 px (palette 28 couleurs, +22 % de clarté),
  GRAVE le symbole d'aile dans la paume (retour utilisateur : la niche encadrée faisait « autocollant » -> maintenant un CREUX dans la pierre sans cadre : vide = gravure sombre avec lèvre éclairée, pleine = gravure dorée + pierre qui rougeoie) -> `v_stele_g|d_vide|pleine.png`. Griffe gauche = stèle de l'aile gauche. Emprise 5x3 cases (`V` en (6,3), `X` en (14,3)), orteils vers le sud ; déclencheurs `$stele_g` en (7..9, 6) et `$stele_d` en (15..17, 6) ; gravure à `cell*16 + (54,16)` (gauche) / `(26,15)` (droite) (`Exterieur.position_niche`, `NICHE_STELE`).
  Parvis : bannières/tonneaux retirés (la place est aux griffes). Même principe pour les façades Gemini à venir : découper dans les images reçues plutôt que redessiner. Tests OK, `verifier_carte.py` OK (2 passes).

## PROCHAINE ÉTAPE (Sonnet) : tester 14b dans Godot, puis harmoniser le reste du village
- Temple, corps du coq, intérieurs, clôtures, puits, tonneau, bannière encore dans l'ancien style (maisons FAITES en 14e) ; héros à harmoniser avec les habitants ; animation « au repos » des habitants (4 images dispo) ; secrets (bois/cascade) ; route du sud à ouvrir à l'épilogue.
- Ensuite : stèle à refaire, rééquilibrage D5/énigmes, mode 7, contrôles tactiles.

- 2026-11-14 : retour : « on voit encore les niches, et le haut des pattes n'est pas naturel (arbres) ». **STÈLES REFAITES (non testées dans Godot, tests headless OK)** : les GRIFFES sont LISSES (aucune niche/gravure ; `Outils/traiter_griffes.py` -> `v_griffe_g|d.png`, jambe prolongée vers le haut) et dessinées SOUS les arbres (`exterieur.gd`, lettres `C`/`D`, emprise 5x2, en (6,3)/(14,3)) ;
  la fenêtre du symbole est sur une PIERRE de briques Gemini posée DEVANT chaque griffe (`Outils/traiter_pierres.py`, source `Assets/Gemini/originaux/pierres_steles.jpg` -> `v_pierre_g|d_vide|pleine.png`, lettres `V`/`X` en (7,5)/(15,5), emprise 3x1, déclencheurs rangée 6). L'insertion illumine aussi la griffe.
  La forêt qui s'écarte ne retire plus que les colonnes 9-12 (rangées 0-2) : les arbres des côtés cachent les jambes. À valider visuellement par l'utilisateur (l'aperçu PIL ne reproduit pas l'ordre de dessin : les jambes y semblent nues).
- 2026-11-14 : stèles : griffes remontées (rangées 1-2, jambes qui sortent de l'écran par le haut) pour ne plus toucher les pierres (rangée 5) ; la forêt n'écarte plus que les colonnes 11-13 (chemin) pour ne pas laisser voir le haut des pattes.

- 2026-11-14 : **FAÇADES GEMINI INTÉGRÉES** (images `Assets/Gemini/originaux/facade_queue.jpg`, `facade_aile_ouverte.jpg`, `facade_aile_fermee.jpg` = aile gauche ; la droite = miroir). `Outils/traiter_facades.py` (AVANT generer_village.py) : COMPLÈTE la flamme de la grande tour (copiée de la 2e tour) et la pointe de la grande plume (copiée de la voisine), remplace le ciel magenta par des briques sombres, réduit en 400x192, élargit les bords par reflets -> `v_facade_queue|aile_g|aile_d|aile_d_fermee.png`.
  NOUVELLE DISPOSITION : façade = 25x12 cases (rangées 0-11), porte = 3 passages en RANGÉE 11, sol sur 2 rangées en dessous ; TempleGauche/TempleDroit/Queue n'ont plus qu'une SORTIE SUD (arrivée en (12,12)) ; le Parvis perd ses sorties ouest/est (chemin du parvis raccourci ; les temples s'atteignent par le sud : verger / terrain de la garde). Garde en (12,12). Tests + verifier_carte OK.

- 2026-11-14 : retour : « la façade ne correspond pas à la vue globale » -> l'utilisateur a regénéré 2 façades AVEC `Coq_forteresse.jpg` en référence : `facade_aile_ouverte.jpg` (aile gauche : 5 plumes de pierre sur un long rempart à runes, porte ouverte) et `facade_queue.jpg` (donjon rond + tour de tête + 4 tours à flammes, porte au centre). Plus aucune retouche nécessaire (rien n'est coupé).
  `Outils/traiter_facades.py` réécrit : 400x192 (échelle 0,25 + bords reflétés), ciel magenta -> briques sombres, aile droite = miroir, variante HERSE BAISSÉE = herse dessinée par code dans l'arche (`herse()`), pas d'image source. `facade_aile_fermee.jpg` supprimée. Disposition 25x12 / porte rangée 11 inchangée. Tests + verifier_carte OK.

- 2026-11-14 : retour : « l'arrivée à l'aile est abrupte, il faudrait un chemin avant d'y arriver, puis la cinématique ». **ALLÉES (non testées dans Godot, tests headless + verifier_carte OK)** : nouveaux écrans `AlleeGauche` (1,0) et `AlleeDroite` (3,0) (avenue de forêt dense + bannières, entrées sud / côté parvis, sortie nord) ;
  les TEMPLES montent en (1,-1) et (3,-1) (même rangée que la Queue (2,-1)) ; le PARVIS retrouve ses sorties ouest/est (chemin 0..24, `SORTIES` 'SOE', révélé 'NSOE'). Chemin : Parvis -> allée -> temple, ou Verger / Terrain de la garde -> allée -> temple. À enrichir : PNJ/statues/braseros dans les allées, plumes géantes de pierre en lisière.
  CINÉMATIQUE D'ASSEMBLAGE (étapes D/E, à faire avec Opus) : plan proposé = (1) stèles brillent + grondement ; (2) fondu vers la vue aérienne à plat HD (Coq_forteresse découpée en calques : ailes G/D, queue+griffes, donjon rond, tour de tête, sol) avec le corps SANS ailes en sommeil au centre et les ailes posées à gauche/droite à l'emplacement des temples ;
  (3) les symboles dorés volent des stèles vers les ailes, les runes s'allument le long des remparts ; (4) les ailes se soulèvent (ombre), pivotent et se verrouillent aux épaules (flash, secousse) ; (5) les torches de la queue s'allument une à une, le coq chante (cocorico), zoom vers l'arène ; (6) retour au Parvis. Image optionnelle à demander à Gemini : la même image SANS les ailes (corps seul, herbe à la place), pour des calques plus propres.
