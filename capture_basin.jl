# src/capture_basin.jl

# ... (imports) ...

"""
    F_growth(current_coords, cell_type_id, model_context)

Calculates the set of coordinates that can be occupied or influenced by a cell 
at `current_coords` with `cell_type_id` in a single time step, considering
proliferation, differentiation, and migration. Apoptosis removes a cell, 
so it does not contribute to the 'growth' or 'maintenance' of the shape 
in the context of the capture basin.

Returns a Set{NTuple{Dim, Int64}} of coordinates.
"""
function F_growth(
    current_coords::NTuple{Dim, Int64},
    cell_type_id::Int64, 
    model_context # Pass the full model to access all rules and data
    ) where Dim

    successor_coords = Set{NTuple{Dim, Int64}}()

    # Always consider the current cell's position to be maintained,
    # unless it explicitly dies or moves away without being replaced.
    push!(successor_coords, current_coords) 

    # --- 1. Proliferation ---
    # A cell at current_coords generates new cells at proliferation_directions.
    if haskey(model_context.processed_proliferation_directions, cell_type_id)
        directions = model_context.processed_proliferation_directions[cell_type_id]
        for dir in directions
            new_coord = current_coords .+ dir
            if all(1 .<= new_coord .<= model_context.grid_size)
                push!(successor_coords, new_coord)
            end
        end
    end
    
    # --- 2. Migration ---
    # A cell moves from current_coords to a new_coord.
    # The current_coords is no longer occupied by *this* cell, but new_coord is.
    # For shape growth, we assume the shape effectively "moves" with the cell.
    # To model this, we add the migrated position to `successor_coords`.
    # Important: The capture basin is about *reaching* a shape. If a cell migrates,
    # its original position `current_coords` might become empty unless another cell
    # moves into it or proliferates there. For the capture basin, we want `F(x)`
    # to represent all locations that *could be occupied by the shape if there was a cell at x*.
    # So, we include potential migration destinations.
    if haskey(model_context.processed_migration_directions, cell_type_id)
        migration_directions = model_context.processed_migration_directions[cell_type_id]
        for dir in migration_directions
            new_coord = current_coords .+ dir
            if all(1 .<= new_coord .<= model_context.grid_size)
                push!(successor_coords, new_coord)
            end
        end
    end

    # --- 3. Differentiation ---
    # If a cell at `current_coords` can differentiate, its future growth potential
    # might change. The capture basin should consider the most "effective" growth path.
    # This is tricky: we need to ensure that if differentiation allows for *more* growth,
    # that potential is considered.
    # Option A (Simplified): Assume differentiation happens *before* current step's proliferation/migration.
    #   The `cell_type_sequence` in the capture basin algorithm already iterates over relevant types.
    #   So, if cell `x` can differentiate from Type A to Type B, then `x` (as Type A) and `x` (as Type B)
    #   are both considered potential starting points for `F_growth` in the basin calculation.
    # Option B (More Complex): If differentiation happens *within* this step, then `F_growth`
    #   for the *current* `cell_type_id` might also include potential positions that arise
    #   from *its differentiated forms*. This leads to a recursive `F_growth` or a broader search.
    # For now, let's stick to Option A, where the `cell_type_sequence` in the main basin loop handles
    # considering differentiation paths implicitly. The `F_growth` itself focuses on the immediate output
    # of a specific cell type.

    # --- 4. Apoptosis ---
    # Apoptosis removes a cell. A coordinate where apoptosis occurs is *not* maintained by the shape.
    # How to integrate this into `F_growth`?
    # `F_growth` is about what *can* be occupied. Apoptosis is about *what is lost*.
    # For the capture basin `Capt_F(C,K)`, the "target" `C` must be reached, and the path `K` maintained.
    # If a cell undergoes apoptosis, it means that `x` is no longer part of the shape.
    # So, if a cell at `current_coords` would undergo apoptosis, then `current_coords` should NOT be in `successor_coords`.
    # This requires `F_growth` to know about the apoptosis rules and apply them.

    # Example apoptosis rule: If timer > apoptosis_threshold for cell_type_id
    # This requires more context about the cell's internal state (like its timer).
    # Since F_growth only gets `current_coords` and `cell_type_id`, it can't check `timer`.
    # This is a fundamental challenge when trying to capture *all* `cellular_dynamics` in `F_growth`.
    #
    # Alternative for Apoptosis in Capture Basin:
    # Instead of making `F_growth` remove points, consider apoptosis as a *constraint violation*
    # for the path in `K`. If a path goes through an apoptotic state, it's not a valid path.
    # However, the definition of the capture basin `y(s) \in C \text{ and } \forall \theta \in [0,s[, y(\theta) \in K`
    # means *all intermediate points must be in K*. If K represents 'cells alive', then apoptosis violates K.
    # This is better handled by carefully defining the set `K`.

    # For the purpose of `F_growth` as "what *can* be generated/maintained":
    # If apoptosis is *deterministic* for a type at a location, `current_coords` might not be added.
    # If it's probabilistic or depends on context (e.g., GF levels), it's harder to model in a simple `F_growth`.
    #
    # **Simplification for now:** We'll assume `F_growth` defines the *potential* for a cell to contribute
    # to the shape's presence. Apoptosis is then a filter applied by `K` or by the overall simulation
    # (i.e., if a cell would die, it wouldn't be part of the viable shape).
    #
    # So, `F_growth` will *only* add coordinates, not remove them.
    # Apoptosis will primarily affect the `K` set (the constraint set of viable states/locations).
    # If a cell at `x` dies, then `x` is effectively no longer in `K`.

    return successor_coords
end

function create_full_grid_set(grid_size::NTuple{Dim, Int64}) where Dim
    grid_points = Set{NTuple{Dim, Int64}}()
    if Dim == 2
        for x in 1:grid_size[1]
            for y in 1:grid_size[2]
                push!(grid_points, (x, y))
            end
        end
    elseif Dim == 3
        for x in 1:grid_size[1]
            for y in 1:grid_size[2]
                for z in 1:grid_size[3]
                    push!(grid_points, (x, y, z))
                end
            end
        end
    end
    return grid_points
end

# src/capture_basin.jl (inside compute_capture_basin)

function compute_capture_basin(
    model::Shape_Growth_Populate.CellModel{Dim},
    C_cells::Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.Cell{Dim}},
    K_cells::Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.Cell{Dim}},
    cell_type_sequence::Vector{Int64}, # All relevant cell types for the simulation
    max_iterations::Int = 100
    ) where Dim

    C_coords = Set{NTuple{Dim, Int64}}(keys(C_cells))
    K_coords = Set{NTuple{Dim, Int64}}(keys(K_cells)) # K is the set of viable coordinates

    R_final = Set{NTuple{Dim, Int64}}()
    frontier = Set{NTuple{Dim, Int64}}()

    # Initialize R_final and frontier: points from C that are also in K
    for c_coord in C_coords
        if c_coord in K_coords
            push!(R_final, c_coord)
            push!(frontier, c_coord)
        end
    end

    if isempty(R_final)
        println("Initial target set C is empty or entirely outside K. Capture basin is empty.")
        return R_final
    end

    println("BFS-like capture basin computation with comprehensive growth rules...")
    k = 0
    while !isempty(frontier) && k < max_iterations
        k += 1
        next_frontier = Set{NTuple{Dim, Int64}}()

        for y in frontier # `y` is a point in the current frontier of the basin
            # Iterate over all possible predecessors `x_candidate`.
            # A predecessor `x_candidate` is a point that, if occupied by a cell,
            # could contribute to `y` being occupied in the next step via `F_growth`.

            # To find these `x_candidate`s efficiently, we reverse the `growth_displacements`.
            # If `F_growth` adds `d` to `current_coords` to get `y`, then `x = y - d`.
            
            # The set of all possible "growth vectors" (relative displacements) that *any* cell type might produce.
            # This is an efficient way to check local neighborhoods without iterating the whole grid.
            all_possible_growth_displacements = Set{NTuple{Dim, Int64}}()
            for ct_id in cell_type_sequence
                if haskey(model.processed_proliferation_directions, ct_id)
                    union!(all_possible_growth_displacements, model.processed_proliferation_directions[ct_id])
                end
                if haskey(model.processed_migration_directions, ct_id)
                    union!(all_possible_growth_displacements, model.processed_migration_directions[ct_id])
                end
            end
            
            # Add the (0,0) displacement if a cell can simply stay put and contribute to the shape
            push!(all_possible_growth_displacements, ntuple(_ -> 0, Dim))

            for d in all_possible_growth_displacements
                x_candidate = y .- d 

                # Check if x_candidate is within the K constraint set (viable) and not yet in R_final
                if x_candidate in K_coords && !(x_candidate in R_final)
                    # Now, verify if *any* cell type at `x_candidate` could have resulted in `y`
                    # through its `F_growth` dynamics.
                    # This is the "exist s.t." part of the capture basin definition.
                    
                    found_valid_predecessor_type = false
                    for cell_type_id_for_check in cell_type_sequence
                        if y in F_growth(x_candidate, cell_type_id_for_check, model)
                            found_valid_predecessor_type = true
                            break # Found a type that could lead to y
                        end
                    end

                    if found_valid_predecessor_type
                        push!(R_final, x_candidate)
                        push!(next_frontier, x_candidate)
                    end
                end
            end
        end
        frontier = next_frontier
        println("Iteration ", k, ": Frontier size = ", length(frontier), ", R_final size = ", length(R_final))
    end

    if k >= max_iterations && !isempty(frontier)
        println("Warning: Capture basin computation reached max iterations before convergence.")
    end

    return R_final
end