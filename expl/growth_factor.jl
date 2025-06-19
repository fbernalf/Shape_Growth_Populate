using ShapeGrowthModels
using Plots # S'assurer que Plots est chargé

# --- CONFIGURATION DE LA DIMENSION ---
const DIM = 2 # Changez ceci à 2 pour 2D, à 3 pour 3D
# ------------------------------------

# Ces fonctions doivent être définies AVANT d'être passées à set_max_function!
fct7(cell::ShapeGrowthModels.Cell{DIM}) = 5
fct8(cell::ShapeGrowthModels.Cell{DIM}) = 15
fct9(cell::ShapeGrowthModels.Cell{DIM}) = 5

xml_file="../xml/cellTypes130.xml"
cell_type_sequence=[7, 8, 9, 7]#128,
num_steps = 10
dist_cellule_fibroblast = 1000.0

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




println("\n--- Computing Capture Basin ---")

# --- MODIFICATION ICI : Récupérer le dernier état de model.history ---
# Vérifier que l'historique n'est pas vide
if isempty(model.history)
    error("L'historique du modèle est vide. Veuillez exécuter la simulation avant de calculer le bassin de capture.")
end

# Le dernier élément de history est un NamedTuple (cells = ..., stromal_cells = ...)
# Nous voulons le dictionnaire `cells` de ce dernier élément.
final_cell_dict = model.history[end].cells 
# --- FIN DE LA MODIFICATION ---

# Définir votre ensemble de contraintes K_cells.
full_grid_coords_K = ShapeGrowthModels.create_full_grid_set(model.grid_size)

dummy_cell_type_for_K = 1 # Utilisez un type de cellule par défaut ou un type approprié de votre simulation
K_cells_dict = Dict{NTuple{DIM, Int64}, ShapeGrowthModels.Cell{DIM}}()
for coord in full_grid_coords_K
    K_cells_dict[coord] = ShapeGrowthModels.Cell{DIM}(
        coordinates = coord,
        cell_type = dummy_cell_type_for_K,
        initial_cell_type = dummy_cell_type_for_K,
        max_divisions_allowed = 0
    )
end

# Récupérer la cell_type_sequence depuis le modèle pour la passer
relevant_cell_types = model.cell_type_sequence

# Exécuter le calcul du bassin de capture
capture_basin_set_coords = ShapeGrowthModels.compute_capture_basin(
    model,
    final_cell_dict, # C_cells est maintenant le dernier état simulé
    K_cells_dict,
    relevant_cell_types
)

println("Computed capture basin size (coordinates): ", length(capture_basin_set_coords))







ShapeGrowthModels.visualize(model, filename)

println("Exécution du script terminée.")