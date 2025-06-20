# Définir la distance maximale autorisée pour la contrainte de proximité des cellules stromales
const STROMAL_PROXIMITY_MAX_DISTANCE = 2

"""
Calcule la distance de Manhattan entre deux ensembles de coordonnées.
"""
function calculate_manhattan_distance(coords1::NTuple{Dim, Int64}, coords2::NTuple{Dim, Int64}) where Dim
    dist = 0
    for i in 1:Dim
        dist += abs(coords1[i] - coords2[i])
    end
    return dist
end

"""
Vérifie la contrainte de proximité stromale : toute Cellule éloignée de plus de
max_distance de toutes les StromalCells subira une apoptose.
Retourne le nombre de cellules éliminées en raison de cette contrainte.
"""



# Dans Shape_Growth_Populate/src/ShapeGrowthViable.jl (ou functions.jl si c'est là que vous le mettez)

function is_near_stromal_cell(
    cell_to_check::Shape_Growth_Populate.Cell{Dim},
    stromal_cells_dict::Dict{NTuple{Dim, Int64}, Shape_Growth_Populate.Cell{Dim}}
) where Dim
    
    # Si il n'y a pas de cellules stromales, aucune cellule ne peut être proche d'une stromale.
    if isempty(stromal_cells_dict)
        return false 
    end

    cell_coord = cell_to_check.coordinates
    
    # Parcourir les cellules stromales existantes pour vérifier la proximité
    for (stromal_coord, _) in stromal_cells_dict
        # Calculer la distance euclidienne au carré pour des raisons de performance.
        dist_sq = sum(abs2.(cell_coord .- stromal_coord))
        
        # Si une cellule stromale est à l'intérieur de la distance définie, retourner true immédiatement.
        if dist_sq <= Shape_Growth_Populate.STROMAL_PROXIMITY_DISTANCE^2
            return true # <--- RETOURNEZ TRUE DÈS QU'UNE CELLULE PROCHE EST TROUVÉE
            break
        end
    end

    # Si la boucle se termine sans avoir retourné true, cela signifie qu'aucune cellule stromale proche n'a été trouvée.
    #return false # <--- RETOURNEZ FALSE SEULEMENT APRÈS AVOIR TOUT VÉRIFIÉ
end