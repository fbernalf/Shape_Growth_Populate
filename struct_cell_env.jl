using Parameters 

@with_kw mutable struct Cell{Dim}
    coordinates::NTuple{Dim, Int64} # Paramétré par Dim
    timer::Int64 = 0
    cell_type::Int64
    initial_cell_type::Int64
    last_division_type::Int64 =7
    nbdiv::Int64 =6
    max_divisions::Int64
    is_alive::Bool = true
    has_proliferated_this_step::Bool = false
    current_type_index_in_sequence::Int64 = 1
end


@with_kw mutable struct StromalCell{Dim} # <--- Add @with_kw here!
    coordinates::NTuple{Dim, Int64} # Paramétré par Dim
    timer::Int64 = 0 # Example default
    cell_type::Int64 = 6 # This is now allowed!
    initial_cell_type::Int64 = 6 # Example default
    last_division_type::Int64 = 0 # Example default
    nbdiv::Int64 = 0 # Example default
    max_divisions::Int64 = 0 # Example default
    is_alive::Bool = true # Example default
    has_proliferated_this_step::Bool = false # Example default
end

struct SystemState
    cells::Vector{Cell}
    stromal_cells::Vector{StromalCell}
    time::Float64
end


mutable struct CellSetByCoordinates{Dim}
    cells::Dict{NTuple{Dim, Int64}, Cell{Dim}} # Clés et valeurs paramétrées
end
CellSetByCoordinates{Dim}() where Dim = CellSetByCoordinates(Dict{NTuple{Dim, Int64}, Cell{Dim}}())

# In Shape_Growth_Populate.jl (or your struct_cell_env.jl file)

# Dans struct_cell_env.ƒj

mutable struct CellModel{Dim}
    xml_file::String                                        # 1
    cell_data::Dict{Int64, Dict{String, Any}}              # 2
    grid_size::NTuple{Dim, Int64}                           # 3
    cells::Dict{NTuple{Dim, Int64}, Cell{Dim}}              # 4 (This is what initial_cells_dict becomes)
    stromal_cells::Union{Dict{NTuple{Dim, Int64}, StromalCell{Dim}}, Nothing} # 5 (This is what initial_stromal_cells_dict becomes)
    dist_cellule_fibroblast::Float64                        # 6
    current_time::Int64                                     # 7
    cell_type_sequence::Vector{Int64}                       # 8
    subdivision_rules::Dict{Int64, Function}                # 9
    max_cell_divisions_dict::Dict{Int64, Function}          # 10
    processed_proliferation_directions::Dict{Int64, Vector{NTuple{Dim, Int64}}} # 11
    processed_migration_directions::Dict{Int64, Vector{NTuple{Dim, Int64}}}   # 12
    history::Vector{NamedTuple{
        (:cells, :stromal_cells),
        Tuple{Dict{NTuple{Dim, Int64}, Cell{Dim}}, Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.StromalCell{Dim}}}
    }}   

    function CellModel{Dim}(;
        xml_file::String = "",
        grid_size::NTuple{Dim, Int64} = (Dim == 2 ? (100, 100) : (100, 100, 10)),
        initial_cells_dict::Dict{NTuple{Dim, Int64}, Cell{Dim}}= Dict{NTuple{Dim, Int64}, Cell{Dim}}(),
        initial_stromal_cells_dict::Union{Dict{NTuple{Dim, Int64}, StromalCell{Dim}}, Nothing}=nothing,
        dist_cellule_fibroblast::Float64= 6.00,
        #current_time::Int64,
        cell_type_sequence::Vector{Int64}= Int64[],

    ) where Dim
        cell_data = load_cell_data( xml_file, cell_type_sequence)

        processed_proliferation_directions = Dict{Int64, Vector{NTuple{Dim, Int64}}}()
        for (cell_type, data) in cell_data
            if haskey(data, "directions") && isa(data["directions"], Vector{Int64})
                processed_proliferation_directions[cell_type] = create_directions_dict(Dict(cell_type => data["directions"]), Val(Dim))[cell_type]
            else
                default_dir_tuple = ntuple(_ -> 0, Dim)
                processed_proliferation_directions[cell_type] = [default_dir_tuple]
            end
        end
        
        processed_migration_directions = Dict{Int64, Vector{NTuple{Dim, Int64}}}()
        for (cell_type, data) in cell_data
            if haskey(data, "directions") && isa(data["directions"], Vector{Int64})
                processed_migration_directions[cell_type] = create_directions_dict(Dict(cell_type => data["directions"]), Val(Dim))[cell_type]
            else
                default_dir_tuple = ntuple(_ -> 0, Dim)
                processed_migration_directions[cell_type] = [default_dir_tuple]
            end
        end
        subdivision_rules = Dict{Int64, Function}()
        max_cell_divisions_dict = Dict{Int64, Function}()
        
        # Determine the initial stromal cells for the model's 'stromal_cells' field.
        # This can still be 'nothing' if that's the desired semantic for the model's state.
        final_model_stromal_cells = initial_stromal_cells_dict # This will be Dict or nothing

        # Determine the initial stromal cells for the 'history' entry.
        # History requires a Dict, so convert 'nothing' to an empty Dict for history.
        final_history_stromal_cells = isnothing(initial_stromal_cells_dict) ? 
                                       Dict{NTuple{Dim, Int64}, StromalCell{Dim}}() : 
                                       deepcopy(initial_stromal_cells_dict)

        # Initialize history with the first step
        history_initial = Vector{NamedTuple{(:cells, :stromal_cells), Tuple{Dict{NTuple{Dim, Int64}, Cell{Dim}}, Dict{NTuple{Dim, Int64}, StromalCell{Dim}}}}}()
        push!(history_initial, (cells = deepcopy(initial_cells_dict), stromal_cells = final_history_stromal_cells))


        new(xml_file, 
            cell_data, 
            grid_size, 
            initial_cells_dict, 
            final_model_stromal_cells, 
            dist_cellule_fibroblast,
            0, # current_time
            cell_type_sequence, 
            subdivision_rules, 
            max_cell_divisions_dict, 
            processed_proliferation_directions, # <--- Pass the *calculated* one
            processed_migration_directions,   # <--- Pass the *calculated* one
            history_initial 
        )
    end
end


@with_kw mutable struct ExtraCellularMatrix{Dim}
    # stromal_cells will always be a Dict, even if empty, when part of ECM
    stromal_cells::Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.StromalCell{Dim}} = Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.StromalCell{Dim}}()
    
    # Add other ECM components here as needed
    fractones::Dict{NTuple{Dim, Int64}, Any} = Dict{NTuple{Dim, Int64}, Any}() # Example
    growth_factors::Dict{NTuple{Dim, Int64}, Float64} = Dict{NTuple{Dim, Int64}, Float64}() # Example
end

#growth_factor_example = {(x,y){2, entero}, any}
#fractones are represented by a matrix