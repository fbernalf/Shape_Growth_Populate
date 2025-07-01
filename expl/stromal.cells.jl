using Shape_Growth_Populate
using Plots # S'assurer que Plots est chargé

# --- CONFIGURATION DE LA DIMENSION ---
const DIM = 2 # Changez ceci à 2 pour 2D, à 3 pour 3D
# ------------------------------------

# Ces fonctions doivent être définies AVANT d'être passées à set_max_function!
fct7(cell::Shape_Growth_Populate.Cell) = round(15*sin(cell.coordinates[1])) + 5
fct8(cell::Shape_Growth_Populate.Cell) = 50
fct9(cell::Shape_Growth_Populate.Cell) = round( 15 * sin(cell.coordinates[1])) + 5
fct128(cell::Shape_Growth_Populate.Cell) = 50
fct129(cell::Shape_Growth_Populate.Cell) = 50
fct130(cell::Shape_Growth_Populate.Cell) = 50
fct131(cell::Shape_Growth_Populate.Cell) = 50
xml_file="xml/cellTypes130.xml"
cell_type_sequence=[128, 129]#,122,126]#7, 8, 9, 7]#128,
num_steps = 40
dist_cellule_fibroblast = 6.0

# --- GÉNÉRALISATION DE LA CRÉATION DES CELLULES ET DE LA TAILLE DE LA GRILLE ---

# Définir la position d'origine des cellules initiales en fonction de la dimension
initial_cell_origin = if DIM == 2
    (50, 50)
elseif DIM == 3
    (50, 50, 5)
else
    error("Dimension non supportée: $(DIM). Utilisez 2 ou 3.")
end
initial_stromal_cell_origin = if DIM == 2
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

const DEFAULT_STROMAL_CELL_TYPE = 99 

my_initial_cells_dict = Shape_Growth_Populate.create_default_initial_cells_dict(
    Val(DIM), 
    initial_cell_origin, 
    cell_type_sequence[1])

my_initial_stromal_dict = Shape_Growth_Populate.create_default_initial_stromal_cells(
    Val(DIM),
    initial_stromal_cell_origin,
    DEFAULT_STROMAL_CELL_TYPE
)
model = Shape_Growth_Populate.CellModel{DIM}(
    initial_cells_dict = my_initial_cells_dict, # This should still be a CellSetByCoordinates
    initial_stromal_cells_dict = my_initial_stromal_dict, # <--- THIS IS THE CRITICAL LINE
    xml_file = xml_file,
    cell_type_sequence = cell_type_sequence,
    grid_size = grid_size
)



# Créer les cellules initiales avec la bonne dimension
#initial_stromal_cells = Shape_Growth_Populate.create_default_initial_stromal_cells(Val(DIM),initial_stromal_cell_origin, cell_type_sequence[1])    




# Définition des fonctions de calcul de max_divisions pour chaque type de cellule
Shape_Growth_Populate.set_max_function!(model, 7, fct7)
Shape_Growth_Populate.set_max_function!(model, 8, fct8)
Shape_Growth_Populate.set_max_function!(model, 9, fct9)
Shape_Growth_Populate.set_max_function!(model, 128, fct128)
Shape_Growth_Populate.set_max_function!(model, 129, fct129)
Shape_Growth_Populate.set_max_function!(model, 130, fct130)



println("Démarrage de la simulation...")
# Exécution de la simulation
Shape_Growth_Populate.run!(model, num_steps=num_steps) # Nombre d'étapes augmenté pour une meilleure visibilité
println("Simulation terminée.")

# visualization
output_dir = "expl/"
animation_filename = joinpath(output_dir, "stromal_cells_simulation.gif")
Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
println("Animación guardada en: $animation_filename")
println(model.stromal_cells)