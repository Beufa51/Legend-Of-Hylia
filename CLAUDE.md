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
  - Aile gauche : 3 salles linéaires reliées par couloirs, 1 énigme par salle, 1 fragment à la fin.
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
- Résolution : 320x180 (16:9), fenêtre 1280x720, stretch viewport, filtre Nearest. Tuiles 16x16.
- Workflow Git : l'utilisateur utilise GitHub Desktop ; toujours "Pull" avant de travailler, "Push" après.

- Histoire : préquelle d'un garde royal (inspiré de l'esprit Zelda OoT). Noms de TRAVAIL :
  village **Cocoricou**, royaume **Hylio**. Ils restent trop proches de Zelda : avant toute publication
  publique, les remplacer par des noms 100 % originaux (les centraliser dans un seul fichier pour
  les changer facilement). Sinon garder le dépôt privé.
- Graphismes : pack Ninja Adventure (téléchargé) + perso créé dans un générateur (planche ~27x27 px,
  licence du générateur à vérifier ; original à mettre dans `assets/`). On fait marcher d'abord un perso
  Ninja Adventure (16x16), le perso maison viendra après si le style colle.

## Points ouverts / à décider
- [ ] Titre/univers : l'utilisateur a proposé "La Legend d'Hylia" → refusé car Hylia et
      "Legend of..." viennent de Zelda (Nintendo). Trouver un nom 100 % original.
- [ ] Contenu précis des 7 énigmes (3 gauche, 3 droite, 1 finale).
- [ ] Graphismes : assets gratuits (CC0) ou pixel art maison ? Taille des tuiles / résolution.

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
  NB : le dépôt ne contient que `Assets/Ninja_adventure/Actor` (pas les Tilesets) → graphismes de salle en couleurs
  provisoires ; ajouter le dossier `Backgrounds/Tilesets` du pack pour passer aux vraies tuiles.

## PROCHAINE ÉTAPE : tester l'étape 3, puis Étape 4 — vrais graphismes de tuiles + 3 salles de l'aile gauche
