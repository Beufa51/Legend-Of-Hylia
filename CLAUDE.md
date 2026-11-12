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
- Résolution proposée : 320x180 (16:9), tuiles 16x16 — à confirmer.
- Workflow Git : l'utilisateur utilise GitHub Desktop ; toujours "Pull" avant de travailler, "Push" après.

## Points ouverts / à décider
- [ ] Titre/univers : l'utilisateur a proposé "La Legend d'Hylia" → refusé car Hylia et
      "Legend of..." viennent de Zelda (Nintendo). Trouver un nom 100 % original.
- [ ] Contenu précis des 7 énigmes (3 gauche, 3 droite, 1 finale).
- [ ] Graphismes : assets gratuits (CC0) ou pixel art maison ? Taille des tuiles / résolution.

## Journal des étapes
- 2026-11-12 : GDD v1 reçu, premier avis donné, questions posées. Rien de créé dans Godot encore.
- 2026-11-12 : réponses reçues (voir Décisions). Étape suivante : création du dépôt GitHub + projet Godot.
- 2026-11-12 : dépôt créé par l'utilisateur, CLAUDE.md poussé. En attente : projet Godot créé dans le dossier cloné (rendu Compatibilité).
