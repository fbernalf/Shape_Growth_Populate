"""Attempts to make a cell proliferate in a given direction."""
function try_proliferate!(model::CellModel{Dim}, next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, parent_cell::Cell{Dim}, dir::NTuple{Dim, Int64}, max_div::Int64) where Dim
    if parent_cell.is_alive && parent_cell.nbdiv < max_div && !parent_cell.has_proliferated_this_step
        new_coords = parent_cell.coordinates .+ dir
        
        # Vérification des bornes dimension-agnostique
        is_in_bounds = true
        for i in 1:Dim
            if !(1 <= new_coords[i] <= model.grid_size[i])
                is_in_bounds = false
                break
            end
        end

        if is_in_bounds && !haskey(next_cells, new_coords)
            parent_cell.last_division_type = parent_cell.cell_type
            parent_cell.nbdiv += 1
            parent_cell.has_proliferated_this_step = true
            next_index_in_sequence = parent_cell.current_type_index_in_sequence
            new_cell = Cell{Dim}(new_coords, 0, parent_cell.cell_type, parent_cell.cell_type, parent_cell.last_division_type, parent_cell.nbdiv, parent_cell.nbdiv, true, false, next_index_in_sequence)
            next_cells[parent_cell.coordinates] = parent_cell
            next_cells[new_coords] = new_cell
            return true
        end
    end
    return false
end

function _update_on_successful_proliferation!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, temp_next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, parent_coords::NTuple{Dim, Int64}) where Dim
    next_cells[parent_coords] = temp_next_cells[parent_coords]
    for (coord, new_c) in temp_next_cells
        if coord != parent_coords && !haskey(next_cells, coord)
            next_cells[coord] = new_c
        end
    end
end

function attempt_proliferation!(
    model::CellModel{Dim} ,
    next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, 
    current_cell::Dict{NTuple{Dim, Int64}, Cell{Dim}}, 
    cell::Cell{Dim}, 
    cell_directions_int::Vector{Int64}, 
    directions::Vector{NTuple{Dim, Int64}}, 
    max_cell_division::Real) where Dim
    max_div = convert(Int64, max_cell_division)
    
    # Return (action_occurred, proliferated_count, differenciation_count, apoptosis_count, converted_to_stromal_count)  
    if !cell.is_alive || cell.nbdiv >= max_div || cell.has_proliferated_this_step
        return (false, 0, 0, 0, 0)
    end

    found_close_stromal_cell = false
    # --- Start of checks for stromal cells ---
    # IMPORTANT: Check if model.stromal_cells is not nothing AND not empty
    if !isnothing(model.stromal_cells) #&& !isempty(model.stromal_cells)
        for (stromal_coord, _) in model.stromal_cells
            if euclidean_distance(cell.coordinates, stromal_coord) <= model.dist_cellule_fibroblast
                found_close_stromal_cell = true
                break
            end
        end
    end
    # --- End of checks for stromal cells ---
    
    if !found_close_stromal_cell && !isnothing(model.stromal_cells) && !isempty(model.stromal_cells)

        if isnothing(model.stromal_cells)
            model.stromal_cells = Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.StromalCell{Dim}}()
        end
        new_stromal_cell = Shape_Growth_Populate.StromalCell{Dim}(
                cell.coordinates,
                cell.timer,
                cell.cell_type, # Consider using a fixed DEFAULT_STROMAL_CELL_TYPE here
                cell.cell_type, # Same here
                cell.cell_type, # Same here
                0,
                0, # max_divisions_allowed
                true, # is_alive
                false # proliferated_this_step
            )
        model.stromal_cells[cell.coordinates] = new_stromal_cell
        
        # Mark the original cell as dead if it's being replaced by the stromal cell
        # This contributes to apoptosis_count, as the original cell "dies" to become stromal.
        if haskey(next_cells, cell.coordinates)
            apoptosis!(next_cells, cell) # Remove original cell from next_cells if it's there
        else
        end
        
        return (true, 0, 0, 1, 1) # Action occurred, 0 proliferated, 0 differentiated, 1 apoptosis, 1 converted to stromal
    end
    
    # --- Original proliferation/apoptosis logic (when a close stromal cell IS found) ---
    original_cell = deepcopy(cell)
    initial_type_this_step = cell.cell_type
    
    parent_coords = cell.coordinates

    for (i, dir) in enumerate(directions)
        if cell_directions_int[i] == 0
            if haskey(next_cells, parent_coords)
                apoptosis!(next_cells, original_cell) 
                return (true, 0, 0, 1, 0) # One apoptosis
            end
        elseif cell_directions_int[i] != 1
            temp_next_cells = deepcopy(next_cells)
            # Make sure try_proliferate! correctly accesses grid_size from model if needed
            if try_proliferate!(model, temp_next_cells, cell, dir, max_div)
                _update_on_successful_proliferation!(next_cells, temp_next_cells, parent_coords)
                return (true, 1, 0, 0, 0) # One proliferation
            end
        end
    end

    if !haskey(next_cells, parent_coords)
        next_cells[parent_coords] = original_cell
        next_cells[parent_coords].cell_type = initial_type_this_step
    end

    return (false, 0, 0, 0, 0) # No action
end

"""Performs the differentiation of a cell to a new type."""
function differentiation!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, cell::Cell{Dim}, new_type::Int64) where Dim
    if cell.is_alive
        cell.cell_type = new_type
        cell.nbdiv = 0
        next_cells[cell.coordinates] = cell
    end
end

"""Attempts to differentiate cells and then make them proliferate."""
function _restore_cell_state!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, cell::Cell{Dim}, original_cell_type::Int64, original_nbdiv::Int64) where Dim
    coords = cell.coordinates
    next_cells[coords].cell_type = original_cell_type
    next_cells[coords].nbdiv = original_nbdiv
    cell.cell_type = original_cell_type
    cell.nbdiv = original_nbdiv
end

function _attempt_differentiation_and_proliferation!(
    model::CellModel{Dim},
    next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}},
    cell::Cell{Dim},
    next_type_index::Int64,
    next_type::Int64,
    proliferation_directions::Dict{Int64, Vector{NTuple{Dim, Int64}}},
    max_cell_division::Int64,
    processed_coords::Set{NTuple{Dim, Int64}}
)::Bool where Dim
    differentiation!(next_cells, cell, next_type)
    coords = cell.coordinates

    if haskey(proliferation_directions, next_type)
        cell_to_proliferate = deepcopy(next_cells[coords])
        for dir in proliferation_directions[next_type]
            cell_to_proliferate.current_type_index_in_sequence = next_type_index
            if try_proliferate!(model, next_cells, cell_to_proliferate, dir, max_cell_division)
                push!(processed_coords, coords)
                cell.cell_type = cell_to_proliferate.cell_type
                cell.nbdiv = cell_to_proliferate.nbdiv
                cell.has_proliferated_this_step = true
                cell.current_type_index_in_sequence = cell_to_proliferate.current_type_index_in_sequence
                return true
            end
        end
    end
    return false
end

function try_differentiate!(model::CellModel{Dim} ,next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, current_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, cell_type_sequence::Vector{Int64}, proliferation_directions::Dict{Int64, Vector{NTuple{Dim, Int64}}}, max_cell_division::Real, grid_size::NTuple{Dim, Int64}, cell_type_to_process::Int64) where Dim
    max_div_int = convert(Int64, max_cell_division)
    cells_to_differentiate = [cell for cell in values(current_cells) if cell.is_alive && cell.cell_type == cell_type_to_process && !cell.has_proliferated_this_step]
    processed_coords = Set{NTuple{Dim, Int64}}()

    differentiated_and_proliferated = false

    for cell in cells_to_differentiate
        coords = cell.coordinates
        if coords in processed_coords
            continue
        end

        original_cell_type = cell.cell_type
        original_nbdiv = cell.nbdiv

        start_index = isnothing(cell.current_type_index_in_sequence) ? 1 : cell.current_type_index_in_sequence

        for i in start_index+1:length(cell_type_sequence)
            next_type_index = i
            next_type = cell_type_sequence[i]

            if _attempt_differentiation_and_proliferation!(
                model,
                next_cells,
                cell,
                next_type_index,
                next_type,
                proliferation_directions,
                max_div_int,
                processed_coords
            )
                differentiated_and_proliferated = true
                break
            else
                _restore_cell_state!(next_cells, cell, original_cell_type, original_nbdiv)
            end
        end
    end
    return differentiated_and_proliferated
end


"""Attempts to make a cell migrate in a given direction."""
function try_migrate!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, current_cell::Cell{Dim}, dir::NTuple{Dim, Int64}, max_migration_count::Int64, grid_size::NTuple{Dim, Int64}) where Dim
    if current_cell.is_alive && current_cell.nbmig < max_migration_count && !current_cell.has_migrated_this_step
        new_coords = current_cell.coordinates .+ dir
        
        is_in_bounds = true
        for i in 1:Dim
            if !(1 <= new_coords[i] <= grid_size[i])
                is_in_bounds = false
                break
            end
        end

        if is_in_bounds && !haskey(next_cells, new_coords) # Vérifier si la nouvelle coordonnée est vide
            # Sauvegarder la référence de la cellule avant de la déplacer
            cell_to_move = next_cells[current_cell.coordinates]
            
            # Supprimer la cellule de son ancienne position
            delete!(next_cells, current_cell.coordinates) 
            
            # Mettre à jour les propriétés de la cellule
            cell_to_move.nbmig += 1
            cell_to_move.has_migrated_this_step = true
            cell_to_move.coordinates = new_coords # Mettre à jour les coordonnées de l'objet cellule
            
            # Ajouter la cellule à sa nouvelle position
            next_cells[new_coords] = cell_to_move 
            return true
        end
    end
    return false
end

"""Attempts to make a cell migrate in all possible directions for its type."""
function attempt_migration!(
    next_cells_dict::Dict{NTuple{Dim, Int64}, Cell{Dim}},
    cell::Cell{Dim},
    directions::Vector{NTuple{Dim, Int64}}, # Directions spécifiques pour la migration
    max_cell_migration_count::Int64, # Nombre maximum de migrations que la cellule peut effectuer
    grid_size::NTuple{Dim, Int64}
) where Dim
    if cell.is_alive && !cell.has_migrated_this_step
        # Itérer sur les directions possibles pour la migration
        for dir in directions
            # Tenter de faire migrer cette cellule
            if try_migrate!(next_cells_dict, cell, dir, max_cell_migration_count, grid_size)
                # Si la migration réussit, marquer la cellule et retourner vrai
                cell.has_migrated_this_step = true
                return true
            end
        end
    end
    return false # La migration n'a pas eu lieu
end


# Fonctions d'apoptose : consolidées pour marquer la cellule comme non-vivante
"""Marks a cell for apoptosis (sets is_alive to false)."""
function apoptosis!(next_cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}, cell::Cell{Dim}) where Dim
    if cell.is_alive && haskey(next_cells, cell.coordinates)
        next_cells[cell.coordinates].is_alive = false
        return true
    end
    return false
end

function _handle_apoptosis!(next_cells_dict::Dict{NTuple{Dim, Int64}, Cell{Dim}}, cell::Cell{Dim})::Int64 where Dim
    apoptosis_count = 0
    if cell.is_alive # Seulement si la cellule est encore vivante, tenter l'apoptose
        if apoptosis!(next_cells_dict, cell)
            apoptosis_count += 1
        end
    end
    return apoptosis_count
end