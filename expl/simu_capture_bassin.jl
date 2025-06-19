using ShapeGrowthModels
using Plots # S'assurer que Plots est chargé
using Parameters
# --- CONFIGURATION DE LA DIMENSION ---
const DIM = 2 # Changez ceci à 2 pour 2D, à 3 pour 3D
# ------------------------------------
counter = 0
# Ces fonctions doivent être définies AVANT d'être passées à set_max_function!
fct7(cell::ShapeGrowthModels.Cell{DIM}) = 10
fct8(cell::ShapeGrowthModels.Cell{DIM}) = 126
fct9(cell::ShapeGrowthModels.Cell{DIM}) = 10

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
    initial_stromal_cells_dict = nothing,
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

println("DEBUG: Script started.")
println("DEBUG: DIM is defined as ", DIM)
println("DEBUG: Model type: ", typeof(model))
println("DEBUG: Model grid_size: ", model.grid_size)


println("DEBUG: About to create full_grid_coords_K.")
full_grid_coords_K = ShapeGrowthModels.create_full_grid_set(model.grid_size)
println("DEBUG: full_grid_coords_K created. Size: ", length(full_grid_coords_K))
println("DEBUG: Type of full_grid_coords_K: ", typeof(full_grid_coords_K))


println("DEBUG: About to initialize dummy_cell_type_for_K and K_cells_dict.")
dummy_cell_type_for_K = 1
println("DEBUG: dummy_cell_type_for_K = ", dummy_cell_type_for_K)

# THIS IS THE CRUCIAL INITIALIZATION LINE FOR K_CELLS_DICT
K_cells_dict = Dict{NTuple{DIM, Int64}, ShapeGrowthModels.Cell{DIM}}()
println("DEBUG: K_cells_dict initialized as empty Dict. Type: ", typeof(K_cells_dict))
println("DEBUG: K_cells_dict is empty: ", isempty(K_cells_dict))
println("DEBUG: Starting loop to populate K_cells_dict.")


# The try/catch block is fine, but the 'counter += 1' inside was the issue.
# The current error means that line 136 is probably trying to PRINT counter
# or use it AFTER the loop, and the loop failed on its first iteration.


println("DEBUG: Starting loop to populate K_cells_dict.")
for coord in full_grid_coords_K
    try
        K_cells_dict[coord] = ShapeGrowthModels.Cell{DIM}(
            coordinates = coord,
            timer = 0,
            cell_type = dummy_cell_type_for_K,
            initial_cell_type = dummy_cell_type_for_K,
            last_division_type = 0,
            nbdiv = 0,
            max_divisions = 0,
            is_alive = true,
            has_proliferated_this_step = false,
            current_type_index_in_sequence = 1
        )
        # THIS IS THE LINE THAT NEEDS THE 'global' KEYWORD:
        global counter += 1 # <--- MAKE ABSOLUTELY SURE THIS IS 'global counter'
                             # It's likely on or near line 125 based on the error.
    catch e
        println("ERROR DEBUG: Failed to create Cell for coord ", coord, ". Error: ", e)
        # Re-throw the error so you still see the full stacktrace
        rethrow(e)
    end
end
println("DEBUG: K_cells_dict population loop finished. Added ", counter, " cells. Final size: ", length(K_cells_dict))



# Line 121 (or near it, where K_cells_dict is used)
println("DEBUG: About to use K_cells_dict at line 121. K_cells_dict is defined: ", isdefined(Main, :K_cells_dict))
println("DEBUG: K_cells_dict has ", length(K_cells_dict), " entries.")

capture_basin_set_coords = ShapeGrowthModels.compute_capture_basin(
    model,
    model.history[end].cells, # This is your final_cell_dict
    K_cells_dict,
    model.cell_type_sequence # This is your relevant_cell_types
)
println("DEBUG: compute_capture_basin successful.")








grid_width, grid_height = model.grid_size # Assuming DIM=2, so (width, height)
# Create an empty matrix to represent the grid for plotting
# Initialize with a background value (e.g., 0)
plot_matrix = zeros(grid_width, grid_height)

# Assign a value (e.g., 1) to coordinates that are in the capture basin
for coord in capture_basin_set_coords
    x, y = coord # Unpack the tuple for 2D
    # Plots.jl typically expects (x,y) for matrix indexing in image plots.
    # Be aware of potential (row, col) vs (x,y) indexing conventions.
    # Julia matrices are col-major, so matrix[y,x] might be what you need
    # if your (x,y) refers to (col,row). Often, for image, it's (row, col)
    # where row is Y and col is X. Let's assume (row, col) = (y, x) for now.
    plot_matrix[y, x] = 1 # Value for capture basin
end

# You might also want to overlay your actual cells from the simulation.
# Let's say you want to represent actual cells with a value of 2.
final_cells = model.history[end].cells
for (coord, cell) in final_cells
    x, y = coord
    plot_matrix[y, x] = 2 # Value for actual cells
end


# Define a custom color scheme if you want.
# For example: background (0) = white, capture basin (1) = light blue, actual cells (2) = dark blue
colors = cgrad([:white, :lightblue, :darkblue], [0, 0.5, 1.0]) # Adjust positions based on your values

p = heatmap(
    plot_matrix,
    aspect_ratio = :equal,   # Keep cells square
    xlims = (0.5, grid_width + 0.5), # Adjust limits to center pixels
    ylims = (0.5, grid_height + 0.5),
    colorbar = false,        # No need for a colorbar if values are symbolic
    title = "Capture Basin",
    xlabel = "X-coordinate",
    ylabel = "Y-coordinate",
    # Set the custom color map
    color = colors,
    # You might want to remove ticks if the grid is very dense
    xticks = :none,
    yticks = :none
)

# Display the plot
display(p)

# To save the plot to a file:
savefig(p, joinpath(output_directory, "capture_basin_Dim$(DIM).png"))
println("DEBUG: Capture basin plot saved to ", joinpath(output_directory, "capture_basin_Dim$(DIM).png"))



ShapeGrowthModels.visualize(model, filename)











println("Exécution du script terminée.")