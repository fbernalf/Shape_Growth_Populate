include("pdma.jl")

# Cette fonction crée une liste de coordonnées possibles pour la prolifération
function get_possible_proliferation_coords(coords::NTuple{Dim, Int64}, directions::Vector{NTuple{Dim, Int64}}, grid_size::NTuple{Dim, Int64}) where Dim
    possible_coords = NTuple{Dim, Int64}[]
    
    # Vérification des bornes dimension-agnostique
    for dir in directions
        new_coords = coords .+ dir
        is_in_bounds = true
        for i in 1:Dim
            if !(1 <= new_coords[i] <= grid_size[i])
                is_in_bounds = false
                break
            end
        end
        if is_in_bounds
            push!(possible_coords, new_coords)
        end
    end
    return possible_coords
end


# create_directions_dict doit maintenant prendre Dim en argument pour créer les tuples de la bonne dimension
function create_directions_dict(cell_directions::Dict{Int64, Vector{Int64}}, ::Val{Dim}) where Dim
    # Cas de direction pour 2D
    cases_2d = Dict(
        1 => [(0, 0)],   # Neutre
        2 => [(0, -1)],  # Ouest
        3 => [(-1, 0)],  # Nord
        4 => [(0, 1)],   # Est
        5 => [(1, 0)],   # Sud
    )
    # Cas de direction pour 3D
    cases_3d = Dict(
        1 => [(0, 0, 0)],   # Neutre
        2 => [(0, -1, 0)],  # Ouest
        3 => [(-1, 0, 0)],  # Nord
        4 => [(0, 1, 0)],   # Est
        5 => [(1, 0, 0)],   # Sud
        6 => [(0, 0, 1)],   # Devant
        7 => [(0, 0, -1)],  # Derrière
    )

    cases_to_use = Dim == 2 ? cases_2d : cases_3d

    result_dict = Dict{Int64, Vector{NTuple{Dim, Int64}}}()
    for (cell_type, directions) in cell_directions
        new_dirs = Vector{NTuple{Dim, Int64}}()
        for direction_int in directions
            if haskey(cases_to_use, direction_int) && direction_int != 0
                
                append!(new_dirs, cases_to_use[direction_int])
            else
                # Retourne un tuple de zéros de la bonne dimension
                push!(new_dirs, NTuple{Dim, Int64}(zeros(Int64, Dim)))
            end
        end
        result_dict[cell_type] = new_dirs
    end
    return result_dict
end


# The run! function encapsulates the call to cellular_dynamics
function run!(model::CellModel{Dim}; num_steps::Int64 = 50) where Dim
    
    
    history_result, final_step = ShapeGrowthModels.cellular_dynamics(
        model,num_steps)
    model.history = history_result
    model.current_time = final_step
    return final_step
end


function cellular_dynamics(
    model::CellModel{Dim},
    num_steps::Int64,
) where Dim
    
    grid_size= model.grid_size
    cell_type_sequence = model.cell_type_sequence
    cell_data = model.cell_data
    #model.stromal_cells = deepcopy(initial_stromal_cells)

   
    
    # Add the initial state to history as a single NamedTuple
    #push!(history, (cells = deepcopy(model.cells), stromal_cells = deepcopy(model.stromal_cells)))
     
    cell_directions = create_directions(cell_data)
    proliferation_directions = create_directions_dict(cell_directions, Val(Dim))

#    println("--- Démarrage de la simulation de dynamique cellulaire ---")
#    println("Nombre initial de cellules : ", length(model.cells))
#    println("Nombre maximum d'étapes : ", num_steps)
#    println("Dimension de la grille : ", Dim, "D")

    # new_cells will be populated within the loop
    current_cells = deepcopy(model.cells) # current_cells tracks only the regular cells for stabilization check
    for step in 1:num_steps
        # simulate_step! modifies model.stromal_cells in place.
        # It also returns the new_cells (regular cells).
        new_cells = ShapeGrowthModels.simulate_step!(
            model,
            current_cells
        )
        
        # --- CRUCIAL CHANGE: Push the state of *both* cell types for the current step as a NamedTuple ---
        # Deepcopy new_cells and model.stromal_cells before pushing to history
        #push!(model.history, (cells = deepcopy(new_cells), stromal_cells = deepcopy(model.stromal_cells)))
        stromal_for_history = isnothing(model.stromal_cells) ? 
                          Dict{NTuple{Dim, Int64}, ShapeGrowthModels.StromalCell{Dim}}() : 
                          deepcopy(model.stromal_cells)

        push!(model.history, (
            cells = deepcopy(new_cells), 
            stromal_cells = stromal_for_history
        ))

        # Compare keys of regular cells for stabilization
        if Set(keys(current_cells)) == Set(keys(new_cells)) 
#            println("\nRaison de l'arrêt : Les coordonnées des cellules se sont stabilisées.")
            break
        end
        
        current_cells = new_cells # Update current_cells for the next iteration
        model.current_time += 1
    end

    if length(model.history) - 1 == num_steps
#        println("Raison de l'arrêt : Nombre maximum d'étapes atteint (", num_steps, ").")
    end

    # history contains the full record of both cell types at each step
    return model.history, length(model.history) - 1
end




function simulate_step!(
    model::CellModel{Dim},
    current_cells::Dict{NTuple{Dim, Int64}, ShapeGrowthModels.Cell{Dim}}
) where Dim
#    println("\n--- Démarrage de l'étape ---")
    #println("initial_stromal_cells", model.stromal_cells)
    reset_proliferation_status!(current_cells)
    cell_type_sequence = model.cell_type_sequence
    grid_size = model.grid_size

    next_cells_dict = deepcopy(current_cells)

    cells_proliferated_this_step = 0
    cells_differentiated_this_step = 0
    cells_died_this_step = 0
    cells_converted_to_stromal = 0

    # Define raw and processed directions ONCE at the start of simulate_step!
    # These will be accessible throughout this function.
    raw_int_directions = create_directions(model.cell_data) # This creates Dict{Int64, Vector{Int64}}
    #println("Raw integer directions: Dict(7 => [2, 1, 1, 1, 1, 1], 9 => [4, 1, 1, 1, 1, 1], 8 => [3, 1, 1, 1, 1, 1], 128 => [2, 4, 3, 5, 1, 1])")
    processed_tuple_directions = create_directions_dict(raw_int_directions, Val(Dim)) # This creates Dict{Int64, Vector{NTuple{Dim, Int64}}}
    #println("Processed tuple directions: Dict(7 => [(0, -1), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)], 9 => [(0, 1), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)], 8 => [(-1, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)], 128 => [(0, -1), (0, 1), (-1, 0), (1, 0), (0, 0), (0, 0)])")
    
    # 1. Phase de Prolifération
    for cell_type in cell_type_sequence
        cells_of_type_dict = Dict{NTuple{Dim, Int64}, ShapeGrowthModels.Cell{Dim}}(
            coord => cell
            for (coord, cell) in current_cells
            if cell.is_alive && cell.cell_type == cell_type
        )

        # Get the specific raw integer directions for the current cell_type
        cell_directions_int = raw_int_directions[cell_type]
        # Get the specific processed tuple directions for the current cell_type
        directions = processed_tuple_directions[cell_type]

        
        for (coord, cell) in cells_of_type_dict
            
            max_cell_division_val = max(calculate_max_divisions(model, cell), model.cell_data[cell_type]["max_cell_division"])

            # Call attempt_proliferation! with all 8 expected arguments and correct types
            action_occurred, proliferated_count, differentiated_count, apoptosis_count, converted_to_stromal_count = attempt_proliferation!(
                model,
                next_cells_dict,
                current_cells, # <--- ADD THIS ARGUMENT (the current_cells dict for this step)
                cell,
                cell_directions_int,       # 5th arg: cell_directions_int (Vector{Int64})
                directions, # 6th arg: directions (Vector{NTuple{Dim, Int64}})
                max_cell_division_val, # 7th arg: max_cell_division (Float64 from Real)
            )
            
            cells_proliferated_this_step += proliferated_count
            cells_differentiated_this_step += differentiated_count
            cells_died_this_step += apoptosis_count
            cells_converted_to_stromal += converted_to_stromal_count
        end
    end

    # 2. Phase de Différenciation
    for cell_type in cell_type_sequence
        cells_for_differentiation = [
            cell for cell in values(current_cells)
            if cell.is_alive && cell.cell_type == cell_type && !cell.has_proliferated_this_step
        ]

        for cell in cells_for_differentiation
            if haskey(next_cells_dict, cell.coordinates)
                current_state_of_cell = next_cells_dict[cell.coordinates]
                if !isnothing(current_state_of_cell) && current_state_of_cell.is_alive && !current_state_of_cell.has_proliferated_this_step
                    max_cell_division_for_diff_val = calculate_max_divisions(model, current_state_of_cell)
                    
                    # Call try_differentiate! with all 7 expected arguments and correct types
                    if try_differentiate!(
                        model,
                        next_cells_dict,
                        current_cells,
                        cell_type_sequence,
                        processed_tuple_directions,          # 4th arg: proliferation_directions (Dict{Int64, Vector{NTuple{Dim, Int64}}})
                        max_cell_division_for_diff_val,      # 5th arg: max_cell_division (Float64 from Real)
                        grid_size,                          # 6th arg: grid_size (NTuple{Dim, Int64})
                        cell_type                            # 7th arg: cell_type_to_process (Int64)
                    )
                        cells_differentiated_this_step += 1
                        cells_proliferated_this_step += 1 # Check this: Differentiation also counts as proliferation? (Keep if intended)
                    end
                end
            end
        end
    end

    # 3. Mettre à jour les timers des cellules vivantes et construire le Dictionnaire final
    final_next_cells_dict = Dict{NTuple{Dim, Int64}, ShapeGrowthModels.Cell{Dim}}()
    for (coord, cell) in next_cells_dict
        if cell.is_alive
            cell.timer += 1
            final_next_cells_dict[coord] = cell
        end
    end

#    println("  -> Proliféré: ", cells_proliferated_this_step,
            ", Mortes: ", cells_died_this_step,
            ", Différenciées: ", cells_differentiated_this_step,
            ", Converties en Stromales: ", cells_converted_to_stromal)

    return final_next_cells_dict
end

"""Updates the timer for living cells."""

function update_cell_state!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}) where Dim
    for cell in values(next_cells)
        cell.is_alive && (cell.timer += 1)
    end
end


"""Resets the proliferation status for all cells at the beginning of a step."""
function reset_proliferation_status!(current_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}) where Dim
    for cell in values(current_cells)
        cell.has_proliferated_this_step = false
    end
end
"""
Returns `Dict{Int64, Vector{Int64}}`: A dictionary where keys are cell types and
values are the vectors of proliferation directions.
"""
function create_directions(cell_data::Dict{Int64, Dict{String, Any}}) # <--- CHANGED HERE
    directions = Dict{Int64, Vector{Int64}}()
    for (cell_type, data) in cell_data
        # Ensure 'data' is indeed a Dict{String, Any} and has "directions" key
        if haskey(data, "directions") && isa(data["directions"], Vector{Int64})
            directions[cell_type] = data["directions"]
        else
            # Handle cases where "directions" might be missing or wrong type
            # For example, assign an empty vector or log a warning
#            println("Warning: 'directions' not found or is of incorrect type for cell_type $cell_type in cell_data. Assigning empty vector.")
            directions[cell_type] = Int64[] # Assign an empty vector
        end
    end
    return directions
end

# Suppression de la version non généralisée de create_directions_dict ici.
# La version généralisée (avec Val{Dim}) est maintenue ci-dessus.


function create_new_cell(model::CellModel{Dim}, coordinates::NTuple{Dim, Int64}, cell_type::Int64) where Dim
    # Placeholder cell for calculate_max_divisions
    temp_cell = Cell{Dim}(coordinates, 0, cell_type, cell_type, 0, 0, 0, true, false, 1)
    max_divisions = calculate_max_divisions(model, temp_cell)
    
    new_cell = Cell{Dim}(
        coordinates,
        0,
        cell_type,
        cell_type,
        0,
        0,
        max_divisions,
        true,
        false,
        1
    )
    return new_cell
end


function create_default_initial_cells_dict(::Val{Dim}, initial_cell_origin::NTuple{Dim, Int64}, initial_type::Int64 ) where Dim
    
    # Correction : Appel au constructeur Cell{Dim} avec les 10 arguments corrects
    # et utilisation de initial_cell_origin au lieu de start_coords.
    initial_cell = ShapeGrowthModels.Cell{Dim}(
        initial_cell_origin, # coordinates: NTuple{Dim, Int64}
        0, # timer: Int64 (ex: 0 au début)
        initial_type, # cell_type: Int64
        initial_type,
        initial_type,
        0,
        0, # max_divisions_allowed: Int64 (sera mis à jour par set_max_function!)
        true, # is_alive: Bool (ex: toujours vivante au début)
        false, # proliferated_this_step: Bool (ex: pas encore divisée)
        1,
        )
    cells_dict = Dict(initial_cell_origin => initial_cell)
    return cells_dict
end


function create_default_initial_stromal_cells(::Val{Dim}, initial_stromal_cell_origin::NTuple{Dim, Int64}, initial_stromal_type::Int64 ) where Dim
    initial_stromal_cell = ShapeGrowthModels.StromalCell{Dim}(
        initial_stromal_cell_origin, # coordinates: NTuple{Dim, Int64}
        0, # timer: Int64 (ex: 0 au début)
        initial_stromal_type, # <-- Attention à ce champ si votre struct Cell n'a pas 10 arguments. Il était l'ID.
        initial_stromal_type, # cell_type
        initial_stromal_type,
        0,
        0, # max_divisions_allowed
        true, # is_alive
        false # proliferated_this_step
        )
    stromal_cells = Dict(initial_stromal_cell_origin => initial_stromal_cell)
#    println("Initial stromal cells created at $(initial_stromal_cell_origin) with type $(initial_stromal_type).")
    # LIGNE CRUCIALE À CHANGER :
    return stromal_cells
end
 