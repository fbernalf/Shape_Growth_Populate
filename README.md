Shape_Growth_Populate

Un module Julia pour la modélisation de la croissance et de la dynamique de forme de cellules. Ce projet permet de simuler la prolifération, la différenciation et les interactions spatiales de divers types cellulaires, offrant des outils pour l'initialisation, la simulation et la visualisation de ces processus complexes.
Fonctionnalités principales

    Modélisation Cellulaire: Définition et gestion de structures cellulaires avec des propriétés telles que le type, la position, la couleur et le potentiel de division.
    Gestion de l'Environnement: Représentation d'un environnement discret (grille 3D) pour les interactions cellulaires.
    Chargement de Données: Lecture des configurations de types cellulaires et de leurs propriétés depuis des fichiers XML.
    Simulation de Croissance: Implémentation de dynamiques cellulaires incluant la division et la différenciation selon des règles définies.
    Visualisation 3D: Outils pour visualiser l'état des cellules à différentes étapes de la simulation, y compris des animations interactives.

Structure du Projet

Le module ShapeGrowthModels est organisé comme suit :

Shape_Growth_Populate/
├── src/
│   ├── ShapeGrowthModels.jl    # Module principal
│   ├── struct_cell_env.jl      # Définition des structures Cell, CellModel, etc.
│   ├── data_xml.jl             # Fonctions de lecture/écriture des fichiers XML (par ex., cellTypes.xml)
│   ├── functions.jl            # Fonctions utilitaires générales
│   ├── functions_max.jl        # Fonctions utilitaires spécifiques (si distinctes)
│   ├── visualization_xml.jl    # Fonctions de visualisation basées sur XML (si applicable)
│   ├── visualization_3D.jl     # Fonctions pour la visualisation 3D avec PlotlyJS
│   └── capture_basin.jl        # Logique spécifique (par ex., pour l'analyse des bassins de capture)
├── expl/
│   └── flag.jl                 # Script d'exemple ou de lancement de simulation
└── xml/
    └── cellTypes130.xml        # Exemple de fichier de définition des types cellulaires

Installation

Pour utiliser ce module, assurez-vous d'avoir Julia (version 1.6 ou supérieure recommandée) installé sur votre système.

    Cloner le dépôt (si c'est un dépôt Git) :
    Bash

git clone https://github.com/votre_utilisateur/Shape_Growth_Populate.git
cd Shape_Growth_Populate

Si ce n'est pas un dépôt Git, naviguez simplement vers le dossier racine du projet.

Lancer Julia et installer les dépendances :
Dans le répertoire racine du projet (là où se trouve le dossier src), lancez Julia :
Bash

julia

Une fois dans le REPL Julia, activez l'environnement du projet et installez les dépendances :
Julia

    julia> using Pkg
    julia> Pkg.activate(".") # Active l'environnement du projet actuel
    julia> Pkg.instantiate() # Installe toutes les dépendances listées dans Project.toml

    (Assurez-vous qu'un fichier Project.toml existe et liste les dépendances comme EzXML, ColorSchemes, ColorTypes, Plots, Parameters, PlotlyJS, PlotlyBase).

Utilisation

Voici un exemple basique de comment lancer une simulation et visualiser les résultats en utilisant le module.

Le script d'exemple principal est expl/flag.jl. Vous pouvez le lancer depuis le REPL Julia :
Julia

julia> include("expl/flag.jl")

Configuration des Types Cellulaires

Les propriétés des types cellulaires (couleurs, divisions maximales, directions de croissance) sont définies dans des fichiers XML, comme xml/cellTypes130.xml. Vous pouvez modifier ces fichiers pour adapter le comportement de vos cellules simulées.
Contributions

Les contributions sont les bienvenues ! Veuillez ouvrir une issue ou soumettre une pull request si vous avez des suggestions ou des améliorations.
Licence

Ce projet est sous licence [MIT License].
Contact

Pour toute question ou commentaire, veuillez contacter [Alexandra Fronville alexandra.fronville@univ-brest.fr/ https://github.com/afronvil/Shape_Growth_Populate].

J'espère que ce README vous sera utile ! N'hésitez pas à le modifier et à l'adapter davantage à vos besoins spécifiques.
