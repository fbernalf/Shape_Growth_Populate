using ShapeGrowthModels # Assurez-vous que votre module est correctement chargé

# Fonction pour obtenir le n-ième nombre de Fibonacci (supposée exister dans ShapeGrowthModels)
# Si ce n'est pas le cas, la définition standard doit être incluse ici.

# Fonction pour générer automatiquement une fonction fct_i
function generate_fct(i::Int)
    return function(cell::ShapeGrowthModels.Cell)
        return ShapeGrowthModels.fibonacci(i + 1) + 2
    end
end

# Nombre de fonctions fct à générer
num_fct = 10

# Génération automatique du vecteur de fonctions fct
fct = [generate_fct(i) for i in 1:num_fct]

num_steps = 150
xml_file="../xml/cellTypes130.xml"

function generate_and_sample(num_types::Int)
    # Créer un vecteur d'entiers aléatoires pour les types de cellules
    vecteur_aleatoire = rand(1:num_types, 10)
    println("Vecteur aléatoire généré pour cell_type_sequence : ", vecteur_aleatoire)
    return vecteur_aleatoire
end

# Choisir le nombre de types de cellules en fonction du nombre de fonctions générées
num_cell_types = 4
cell_type_sequence = generate_and_sample(num_cell_types)

dist_cellule_fibroblast = 1000.0

initial_cell_origin = if DIM == 2
    (50, 50)
elseif DIM == 3
    (50, 50, 5)
else
    error("Dimension non supportée: $(DIM). Utilisez 2 ou 3.")
end
initial_stromal_cell_origin = if DIM == 2
    (50, 51)
elseif DIM == 3
    (50, 51, 5)
else
    error("Dimension non supportée: $(DIM). Utilisez 2 ou 3.")
end



# Définir la taille de la grille en fonction de la dimension
grid_size = if DIM == 2
    (100, 100)
elseif DIM == 3
    (100, 100, 10)
else
    error("Dimension non supportée: $(DIM). Utilisez 2 ou 3.")
end

const DEFAULT_STROMAL_CELL_TYPE = 99 

my_initial_cells_dict = ShapeGrowthModels.create_default_initial_cells_dict(
    Val(DIM), 
    initial_cell_origin, 
    cell_type_sequence[1])





model = ShapeGrowthModels.CellModel{DIM}(
    initial_cells_dict = my_initial_cells_dict, # This should still be a CellSetByCoordinates
    xml_file = xml_file,
    cell_type_sequence = cell_type_sequence,
    grid_size = grid_size,
    initial_stromal_cells_dict = my_initial_stromal_dict, # <--- THIS IS THE CRITICAL LINE
)


println("Démarrage de la simulation...")
# Exécution de la simulation
ShapeGrowthModels.run!(model, num_steps=50) # Nombre d'étapes augmenté pour une meilleure visibilité
println("Simulation terminée.")

# Visualisation des résultats
script_name = if Base.source_path() !== nothing
    splitext(basename(Base.source_path()))[1]
else
    "simulation_script" # Nom par défaut si exécuté dans la REPL
end
output_directory = "../expl/"
filename = joinpath(output_directory, "$(script_name)_Dim$(DIM).gif") # Ajout de la dimension au nom du fichier

ShapeGrowthModels.visualize(model, filename)

println("Exécution du script terminée.")