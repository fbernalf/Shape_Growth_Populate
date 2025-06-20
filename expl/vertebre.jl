using ShapeGrowthModels
using Plots # S'assurer que Plots est chargé

# --- CONFIGURATION DE LA DIMENSION ---
const DIM = 2 # Changez ceci à 2 pour 2D, à 3 pour 3D
# ------------------------------------

# Ces fonctions doivent être définies AVANT d'être passées à set_max_function!
fct7(cell::ShapeGrowthModels.Cell) = round(5*sin(cell.coordinates[1])) + 5
fct8(cell::ShapeGrowthModels.Cell) = 30
fct9(cell::ShapeGrowthModels.Cell) = round(5 * sin(cell.coordinates[1])) + 5

xml_file="../xml/cellTypes130.xml"
cell_type_sequence=[7, 8, 9, 7]
num_steps = 55
#dist_cellule_fibroblast = 1000.0

# --- GÉNÉRALISATION DE LA CRÉATION DES CELLULES ET DE LA TAILLE DE LA GRILLE ---

# Définir la position d'origine des cellules initiales en fonction de la dimension
initial_cell_origin = if DIM == 2
    (50, 50)
elseif DIM == 3
    (50, 50, 5)
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

my_initial_stromal_dict = nothing      

my_initial_cells_dict = ShapeGrowthModels.create_default_initial_cells_dict(
    Val(DIM), 
    initial_cell_origin, 
    cell_type_sequence[1])


model = ShapeGrowthModels.CellModel{DIM}(
    initial_cells_dict = my_initial_cells_dict, # This should still be a CellSetByCoordinates
    xml_file = xml_file,
    cell_type_sequence = cell_type_sequence,
    grid_size = grid_size,
    initial_stromal_cells_dict = nothing
)


# Définition des fonctions de calcul de max_divisions pour chaque type de cellule
ShapeGrowthModels.set_max_function!(model, 7, fct7)
ShapeGrowthModels.set_max_function!(model, 8, fct8)
ShapeGrowthModels.set_max_function!(model, 9, fct9)





println("Démarrage de la simulation...")
# Exécution de la simulation
ShapeGrowthModels.run!(model, num_steps=num_steps) # Nombre d'étapes augmenté pour une meilleure visibilité
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





