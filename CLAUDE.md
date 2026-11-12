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

## PROCHAINE ÉTAPE : Étape 6f
- L'utilisateur re-teste les portes (Pull, F5). Puis plumes 3, 4, 5 (3, 4, 5 écrans), épine 3-5, fragment ; ensuite rééquilibrage des énigmes. (Conception = Opus ; faire /clear avant /model.)
