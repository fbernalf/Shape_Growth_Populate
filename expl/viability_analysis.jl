
"""
Évalue la viabilité d'une simulation basée sur des critères définis.
Renvoie un dictionnaire de booléens indiquant si chaque critère est respecté,
ainsi qu'un booléen global pour la viabilité.
"""
function evaluate_viability(
    history::Vector{ShapeGrowthModels.CellSetByCoordinates},
    model_params::ShapeGrowthModels.CellModel; # Pour accéder aux paramètres comme grid_size
    min_final_cells::Int = 5, # Minimum de cellules à la fin pour ne pas être considéré éteint
    max_final_density_ratio::Float64 = 0.95, # Ne doit pas dépasser 95% de la grille
    min_unique_cell_types::Int = 1, # Au moins un type de cellule doit survivre
    stability_window::Int = 10, # Nombre d'étapes pour vérifier la stabilisation
    max_steps_for_stability::Int = 200 # Nombre maximum d'étapes avant de considérer la simulation instable
)::Dict{String, Any}

    is_viable = true
    reasons_not_viable = String[]

    if isempty(history) || length(history) == 1
        push!(reasons_not_viable, "Simulation trop courte ou vide.")
        is_viable = false
        return Dict("is_viable" => is_viable, "reasons" => reasons_not_viable)
    end

    final_cells_set = history[end]
    total_cells_final = length(final_cells_set.cells)

    grid_area = model_params.grid_size[1] * model_params.grid_size[2]

    # Critère 1: Population finale
    if total_cells_final < min_final_cells
        push!(reasons_not_viable, "Population finale trop faible ($(total_cells_final) < $(min_final_cells)).")
        is_viable = false
    end
    
    # Critère 2: Densité finale (ne doit pas être trop élevée)
    final_density = total_cells_final / grid_area
    if final_density > max_final_density_ratio
        push!(reasons_not_viable, "Densité finale trop élevée ($(round(final_density*100, digits=1))% > $(round(max_final_density_ratio*100, digits=1))%).")
        is_viable = false
    end

    # Critère 3: Diversité des types cellulaires
    unique_types_final = Set{Int64}()
    for cell in values(final_cells_set.cells)
        if cell.is_alive
            push!(unique_types_final, cell.cell_type)
        end
    end
    num_unique_types_final = length(unique_types_final)
    if num_unique_types_final < min_unique_cell_types
        push!(reasons_not_viable, "Diversité de types cellulaires trop faible ($(num_unique_types_final) < $(min_unique_cell_types)).")
        is_viable = false
    end

    # Critère 4: Stabilité de la population (pas d'extinction précoce, ni de croissance/déclin rapide)
    # On regarde si la simulation a atteint une période de stabilité à la fin.
    # On compare la taille de la population sur les 'stability_window' dernières étapes.
    if length(history) > stability_window
        # Récupérer les tailles de population des dernières étapes
        last_n_populations = [length(h.cells) for h in history[end-stability_window+1:end]]
        # Vérifier si la variation est faible (par exemple, moins de 5% de la taille moyenne)
        avg_pop = sum(last_n_populations) / length(last_n_populations)
        max_deviation = maximum(abs.(last_n_populations .- avg_pop))
        if avg_pop > 0 && max_deviation / avg_pop > 0.05 # Si la population moyenne n'est pas zéro
             push!(reasons_not_viable, "Population instable sur les dernières $(stability_window) étapes.")
             is_viable = false
        end
    else
        # Si la simulation est trop courte pour évaluer la stabilité,
        # on peut considérer qu'elle n'a pas prouvé sa stabilité.
        push!(reasons_not_viable, "Historique trop court pour évaluer la stabilité.")
        is_viable = false
    end
    
    # Critère 5: Durée de survie (si la simulation s'est arrêtée trop tôt)
    if model_params.current_time < model_params.num_steps && total_cells_final <= min_final_cells && !("Population finale trop faible ($(total_cells_final) < $(min_final_cells))." in reasons_not_viable)
        push!(reasons_not_viable, "Simulation arrêtée prématurément sans atteindre le nombre d'étapes cible ou sans critère d'arrêt stable.")
        is_viable = false
    end


    # Retourner les résultats détaillés
    return Dict(
        "is_viable" => is_viable,
        "reasons" => reasons_not_viable,
        "total_cells_final" => total_cells_final,
        "final_density" => final_density,
        "num_unique_cell_types_final" => num_unique_types_final,
        "sim_duration_steps" => model_params.current_time # Durée réelle de la simulation
    )
end

