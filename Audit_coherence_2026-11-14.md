# Audit de cohérence complet — « Épreuve de la Garde » (14/11/2026)

**Méthode.** Godot 4.4.1 headless lancé côté Claude : `Tests/verifier_scenes.gd` = **TOUT BON** (village 19 écrans, aile gauche 22, aile droite 22, corps 3, garde/stèles, donjon final, tactile).
Captures réelles (Xvfb) de 8 écrans : vestibule, entrée, plume 1 (aile gauche), couloir + arène du corps, façade de la Queue, Parvis, Place du Coq. Relecture du CLAUDE.md, des textes de PNJ, des scènes et des scripts.
**Limites :** je n'ai pas *joué* (pas de manette ni de souris) : le ressenti (rythme, difficulté réelle, sons, fluidité) n'est pas noté. Le projet est en Godot 4.7.2 ; mes tests tournent en 4.4.1.

---

## 1. Note objective : **6,5 / 10** (prototype avancé, jouable du début à la fin)

| Axe | Note | Pourquoi |
|---|---|---|
| Boucle de jeu et complétude | **8** | Départ → village → 2 ailes (10 plumes) → stèles → assemblage → boss → adoubement : tout existe et les tests auto passent |
| Design des énigmes | **7** | 1 mécanique par plume, leçon → complication → combinaison, solveurs Python ; mais 27 indices texte, D5 trop dure, 2b = redite |
| Cohérence monde / narration | **6** | Idée forte (le donjon = un coq), mais vocabulaire flottant, GDD obsolète, promesses non tenues (secrets, route du sud, insignes) |
| Cohérence visuelle | **6** | Village homogène et joli, donjon cohérent ; mais 8 sources graphiques, héros ≠ PNJ ≠ façades peintes |
| Cohérence audio | **5** | Musiques et bruitages du pack, 28 MIDI rendus jamais écoutés, peu de sons d'ambiance/pas |
| Contrôles / lisibilité / mobile | **6,5** | Tactile et sauvegarde présents, jamais essayés sur un vrai téléphone |
| Robustesse technique | **7** | Tests verts, générateurs + vérificateurs ; mais `room.gd` = 1467 lignes, code mort, de nombreuses étapes « non testées dans Godot » dans le journal |
| Prêt à publier (web, licences, crédits) | **3** | Pas d'export web configuré, aucun écran de crédits, licences de 5 packs « à vérifier » |

Lecture : pour un projet amateur fait en pas à pas, c'est un **vertical slice complet** ; l'écart avec « 8/10 » tient moins au contenu qu'à l'unité (style, ton, règles) et au fait que beaucoup de choses n'ont jamais été vues par un humain.

---

## 2. Incohérences constatées (par gravité)

### A. Bloquantes pour une sortie
1. **Aucun export web** (`export_presets.cfg` absent) alors que la cible est « navigateur PC + mobile ». Rien n'a été validé : poids (Assets = 200 Mo, dépôt 164 Mo), Light2D/CanvasModulate/shaders en WebGL, `content_scale_mode` basculé en HD pendant la cinématique (risqué sur téléphone).
2. **Licences non réglées** : Craftpix (interdit de redistribuer les fichiers seuls → problème si le dépôt est public), Jadson (aucun fichier de licence), Aesthetic pack (« à vérifier »), pack MIDI (« à vérifier »), planche LPC du héros (**attribution obligatoire**, CC-BY-SA). **Aucun écran de crédits** dans le jeu.
3. **Dossiers parasites dans le dépôt** : `__MACOSX`, `COUPON.pdf/png`, `PSD`, `Tiled_files`, `generic-rpg-pack` (non utilisé) : poids et risque juridique inutiles.

### B. Cohérence du monde et de l'histoire
4. **Le GDD du CLAUDE.md est faux** : il dit « zéro combat » et « twist = cinématique à la fin d'une aile » ; le jeu a une lance, un boss à 6 PV, 5 cœurs, et le twist est à la stèle. À réécrire (les décisions sont bonnes, la doc est périmée).
5. **Vocabulaire flottant** : « temple » (dialogues, noms d'écrans `TempleGauche`), « donjon », « épreuve », « blason », « Gardien du blason », « aile ». Le joueur lit « le temple est au nord » mais voit des façades de forteresse. Choisir 3 mots et s'y tenir.
6. **Promesses non tenues** : route du sud barrée « jusqu'à l'épilogue » (il n'y a pas d'épilogue), Bois/Cascade jamais faits, 4 maisons « fermées à clé » sur 7. Dans un Zelda, une porte fermée sans raison se lit comme un bug.
7. **Récompenses sans effet** : 9 insignes, rubans de mini-jeux, records : affichés au tableau d'honneur, **ne débloquent rien**. Les pots des donjons sont vides. Le joueur apprend vite à ne plus fouiller.
8. **Un seul endroit où l'on peut être blessé** (le boss) : cohérent avec « pas de dégâts », mais le joueur n'est pas prévenu que les cœurs existent avant le boss ; la barre apparaît brusquement.
9. **Noms de travail** (`Noms.ROYAUME = "Hylio"`, titre provisoire) toujours en place ; centralisés, donc facile à changer, mais le titre du jeu n'existe pas.

### C. Cohérence des règles et des énigmes
10. **Règle « énigmes sans aucun texte » non appliquée** : 27 `indice` texte (9 aile gauche, 18 aile droite) + messages de règle. C'est la règle de design la plus claire de l'utilisateur et la moins respectée.
11. **Aile droite plus dense que la gauche** : D5 a été jugée trop dure (« j'ai réussi mais il faudra revoir »), 3 mécaniques par écran ; la gauche reste à une mécanique par écran. Courbe de difficulté irrégulière entre les deux ailes alors que l'ordre est forcé (gauche d'abord).
12. **Plume 2b = simple cristal** (déjà la leçon du vestibule) : redite relevée dans l'audit du 12/11, jamais traitée.
13. **Verbe unique cohérent (point fort)** : la lance sert partout (cristal, braseros, pots, miroirs, cloches, poules). C'est la meilleure source de cohérence du jeu.
14. **Sanctions hétérogènes** : sentinelles = on te raccompagne, pics = retour, glace/reflet = R, boss = KO. Chaque sanction est logique, mais sans signe commun (même son, même fondu) le joueur ne sait pas à quoi s'attendre.

### D. Cohérence visuelle (captures)
15. **Héros (LPC) / PNJ (Pixel Crawler « grosse tête ») / façades (peinture Gemini réaliste) / décor village (Jadson + Pixel Crawler)** : 3 niveaux de réalisme. Visible sur la Place du Coq : héros et habitants ne semblent pas du même monde. Connu et accepté jusqu'ici.
16. **Restes de l'ancien style** : étal, tonneaux, caisses, bannières, panneaux, intérieurs (Pixel Crawler intérieur, mais meubles d'autres packs).
17. **Échelles** : griffes/façade de la Queue à 0,8 dans le village, 1,0 dans la cinématique ; toléré, mais visible à l'œil exercé.
18. **Donjon (captures vestibule / entrée / plume 1)** : pierre gris-bleu très uniforme d'une salle à l'autre ; seules les teintes et la frise de runes les distinguent. Le corps du coq (arène, ciel étoilé, couloir) est nettement plus réussi que les ailes : **l'apogée visuelle est à la fin, le milieu est plat**.
19. **Corps du coq : maintenant cohérent** avec l'image (5 couloirs séparés, 6 flammes, cour à ciel ouvert, griffes uniquement sur le château). C'est le bon niveau d'exigence à viser partout.

### E. Technique
20. **Code mort** : `mode7.gd` (242 lignes), `vue_aerienne.gd` (195, coupée par `VUE_AERIENNE_A_LA_SORTIE := false`), `Etat.chute`, lettres `C`/`D` et images `v_griffe_*`, `chemin_braseros` de `room.gd`, `fabriquer_plans_mode7.py`.
21. **`room.gd` 1467 lignes** (sentinelles, rayon, chant, reflet, glace, dalles, feu…) : bon tant que les tests le protègent, mais chaque nouvelle énigme y ajoute de l'état partagé. À découper **après** le passage sur les énigmes (décision déjà prise).
22. **Chaîne d'outils fragile** : 12 scripts à lancer dans un ordre précis (documenté dans le CLAUDE.md seulement). Une erreur d'ordre écrase des images. Un `Outils/tout_regenerer.py` ou un `Makefile` supprimerait ce risque.
23. **Écart de version** : le projet est en 4.7.2, les tests en 4.4.1 ; chaque lancement réécrit ~2750 fichiers `.import`.
24. **Beaucoup de code jamais vu par un humain** (étapes 10a à 14p, façades, allées, assemblage : « non testé dans Godot » ou testé en rendu logiciel). Les tests prouvent que ça charge, pas que c'est agréable.

---

## 3. Points forts (à protéger)
- Un **concept unifiant rare** : le coq est partout (girouette, plumes, HUD, stèles, façades, boss, cinématique). Le joueur peut deviner la forme du donjon : excellent.
- **Les deux issues du boss** (combattre / baisser la lance) sont des victoires : cohérent avec le thème « garde ».
- **Pédagogie Zelda** : chaque salle d'ouverture enseigne une mécanique.
- **Outillage de vérification** (solveurs d'énigmes, `verifier_carte.py`, tests auto, mode dev F1, sauvegarde v2 avec migration).
- **Cinématique d'assemblage** : validée par l'utilisateur, cohérente avec l'image de référence.

---

## 4. Plan de priorités proposé

| # | Action | Effort | Modèle |
|---|---|---|---|
| 1 | Configurer l'export web + test réel (PC et téléphone) ; mesurer poids et FPS | moyen | Sonnet |
| 2 | Licences : trier les packs, retirer parasites/non utilisés, écran **Crédits** | moyen | Sonnet |
| 3 | Réécrire le GDD + vocabulaire (temple/donjon/épreuve), choisir le titre | petit | Haiku/Sonnet |
| 4 | Passage « énigmes sans texte » (27 indices), une salle à la fois avec l'utilisateur | gros | Opus |
| 5 | Donner un effet aux insignes (ex. 3 = cœur en plus pour le boss, 6 = lance plus longue, 9 = secret final) et du butin dans les pots | moyen | Opus |
| 6 | Épilogue : route du sud OU retirer la barrière ; ouvrir/retirer les portes « fermées à clé » | moyen | Sonnet |
| 7 | Harmoniser héros ↔ PNJ ↔ façades (une règle : même grain, mêmes contours) ; donner du relief aux ailes du donjon (comme le corps) | gros | Opus |
| 8 | Audio : écouter les 28 MIDI, ajouter pas (herbe/pierre), ambiances donjon | moyen | Sonnet |
| 9 | Nettoyage : code mort, `tout_regenerer`, découpage de `room.gd` | moyen | Sonnet |
| 10 | Session de test humaine guidée (liste de 20 points) | utilisateur | — |
