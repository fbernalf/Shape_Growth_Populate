function fibonacci(n)
    if n <= 1
        return n
    else
        a, b = 0, 1
        for _ in 2:n
            a, b = b, a + b
        end
        return b
    end
end
"""
    euclidean_distance(pos1::NTuple{3, Float64}, pos2::NTuple{3, Float64})::Float64

Calcule la distance euclidienne entre deux points 3D.
"""
function euclidean_distance(coords1::NTuple{Dim, Int64}, coords2::NTuple{Dim, Int64}) where Dim
    sum_sq_diff = 0.0
    for i in 1:Dim
        sum_sq_diff += (coords1[i] - coords2[i])^2
    end
    return sqrt(sum_sq_diff)
end

function angle(coords::NTuple{3, Int64}; center::NTuple{3, Int64} = (50, 50))
    dx = coords[1] - center[1]
    dy = coords[2] - center[2]
    #dz = coords[3] - center[3]
    return atan(dy, dx)
end

function distance_from_center(coords::NTuple{3, Int64}; center::NTuple{3, Int64} = (50, 50))
    dx = coords[1] - center[1]
    dy = coords[2] - center[2]
    dz = coords[3] - center[3]
    return sqrt(dx^2 + dy^2+ dz^2)
end

function generate_cell_type_sequence()
    cell_type_sequence = [7, 8, 9, 7]
    append!(cell_type_sequence, rand(1:max_type, num_elements))
    println("Vecteur aléatoire généré pour cell_type_sequence : ", cell_type_sequence)
    return cell_type_sequence
end

# Fonction pour générer automatiquement une fonction fct_i
function generate_fct_fibonacci(i::Int)
    return function(cell::Shape_Growth_Populate.Cell)
        return Shape_Growth_Populate.fibonacci(i + 1) + 2
    end
end

function generate_cell_type_sequence(num_elements::Int, max_type::Int)
    cell_type_sequence = [7, 8, 9, 7]
    append!(cell_type_sequence, rand(1:max_type, num_elements))
    println("Vecteur aléatoire généré pour cell_type_sequence : ", cell_type_sequence)
    return cell_type_sequence
end

function calculate_max_divisions(model::CellModel, cell::Cell) # Pas besoin de Dim ici
    if haskey(model.max_cell_divisions_dict, cell.cell_type)
        return model.max_cell_divisions_dict[cell.cell_type](cell)
    else
        return 1
    end
end

function set_max_function!(model::CellModel, cell_type::Int, fct::Function)
    if !haskey(model.max_cell_divisions_dict, cell_type)
        model.max_cell_divisions_dict[cell_type] = fct
    else
        error("La fonction de division maximale pour le type de cellule $cell_type est déjà définie.")
    end
end
function set_max_function(model::CellModel, cell_type::Int)
    if haskey(model.max_cell_divisions_dict, cell_type)
        return model.max_cell_divisions_dict[cell_type]
    else
        error("Aucune fonction de division maximale définie pour le type de cellule $cell_type.")
    end
end


function set_type_sequence!(model::CellModel, type_sequence::Vector{Int64}) # Pas besoin de Dim ici
    if hasfield(typeof(model), :cell_type_sequence) # Le champ est maintenant cell_type_sequence
        model.cell_type_sequence = type_sequence
        println("Type sequence defined: $(model.cell_type_sequence)")
    else
        error("Le modèle ne contient pas un champ :cell_type_sequence pour stocker la séquence de types.")
    end
end

