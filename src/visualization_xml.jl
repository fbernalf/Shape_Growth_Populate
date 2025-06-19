using Plots
using PlotlyJS
#import PlotlyBase: Frame, Layout, attr # <-- ADD THIS LINE

"""
    visualize(model::CellModel{2}, filename::String)

Visualise le modèle cellulaire 2D, typiquement les positions des cellules ou le bassin de capture.
Sauvegarde le graphique dans le fichier spécifié.
"""
function visualize(model::CellModel{2}, filename::String)
    cells_to_plot = model.history.cells

    grid_width, grid_height = model.grid_size
    plot_matrix = zeros(Int, grid_width, grid_height)

    for (coords, cell) in cells_to_plot
        x, y = coords
        plot_matrix[y, x] = cell.cell_type
    end

    p = Plots.heatmap( # <--- ADD Plots. here
        plot_matrix,
        aspect_ratio = :equal,
        title = "2D Cell Model State",
        xlabel = "X", ylabel = "Y",
        colorbar_title = "Cell Type",
        xticks = :none, yticks = :none
    )
    Plots.savefig(p, filename) # <--- ADD Plots. here too
#    println("DEBUG: 2D visualization saved to ", filename)
    return p
end


"""
    visualize_3D_plotly(model::CellModel{3}, filename::String)

Visualise le modèle cellulaire 3D en utilisant PlotlyJS.scatter3d pour une vue interactive.
Sauvegarde le graphique HTML dans le fichier spécifié.
"""
function visualize_3D_plotly(model::CellModel{3}, filename::String)
    cells_to_visualize = model.history[end].cells

    cell_x = Float64[]
    cell_y = Float64[]
    cell_z = Float64[]
    cell_types = Int64[]

    for (coords, cell) in cells_to_visualize
        push!(cell_x, coords[1])
        push!(cell_y, coords[2])
        push!(cell_z, coords[3])
        push!(cell_types, cell.cell_type)
    end

    # 1. CORRECTLY define 'trace' as a PlotlyBase.AbstractTrace using PlotlyJS.scatter3d
    trace = PlotlyJS.scatter3d( # <--- USE PlotlyJS.scatter3d directly for 3D
        x=cell_x,
        y=cell_y,
        z=cell_z,
        mode="markers",
        marker=PlotlyJS.attr( # Make sure 'attr' is qualified
            size=5,
            color=cell_types,
            colorscale="Viridis",
            cmin=minimum(cell_types),
            cmax=maximum(cell_types),
            colorbar_title="Cell Type",
            opacity=0.8
        ),
        # type="scatter3d" is not needed when using PlotlyJS.scatter3d
        name="Cellules"
    )

    # 2. Define 'layout' as a PlotlyBase.Layout
    layout = PlotlyJS.Layout( # Make sure 'Layout' is qualified
        title="Répartition 3D des Cellules (Dernier état)",
        scene=PlotlyJS.attr( # Make sure 'attr' is qualified here too
            xaxis_title="X Coordinate",
            yaxis_title="Y Coordinate",
            zaxis_title="Z Coordinate",
            aspectmode="data"
        ),
        hovermode="closest"
    )

    # 3. Create the final plot object using PlotlyJS.plot with the trace and layout
    plot_obj = PlotlyJS.plot(trace, layout) # <--- This is the ONLY call to PlotlyJS.plot

    # Ensure filename has the correct extension for PlotlyJS (e.g., .html or .png)
    if !endswith(filename, ".html") && !endswith(filename, ".png") && !endswith(filename, ".jpeg") && !endswith(filename, ".webp") && !endswith(filename, ".svg") && !endswith(filename, ".pdf") && !endswith(filename, ".eps") && !endswith(filename, ".json")
        filename = filename * ".html" # Default to HTML for interactivity
    end
    
    # 4. Save the plot object using PlotlyJS.savefig
    PlotlyJS.savefig(plot_obj, filename)

#    println("DEBUG: Visualisation PlotlyJS Scatter3D sauvegardée dans ", filename)
    return plot_obj
end

# Dans ShapeGrowthModels/src/visualization.jl (ou visualization_xml.jl)

using Plots # Assurez-vous que Plots est bien chargé

"""
    visualize_history_animation(model::CellModel{2}, output_filename::String)

Crée une animation GIF de l'historique de la simulation pour un modèle 2D.
"""
function visualize_history_animation(model::CellModel{2}, output_filename::String)
    # Assurez-vous que le nom de fichier se termine par .gif
    if !endswith(output_filename, ".gif")
        output_filename *= ".gif"
    end

    grid_width, grid_height = model.grid_size
    
    # Préparez la fonction qui dessine une seule image
    # Cette fonction sera appelée pour chaque entrée dans model.history
    animation_plot_function = function(history_entry)
        cells_to_plot = history_entry.cells # Accéder au dictionnaire des cellules
        
        plot_matrix = zeros(Int, grid_width, grid_height)

        for (coords, cell) in cells_to_plot
            x, y = coords
            plot_matrix[y, x] = cell.cell_type # Assurez-vous que le cell_type est un Int
        end

        # Vous pouvez ajouter ici la logique de visualisation du bassin de capture
        # Si vous avez un `compute_capture_basin` qui prend le `model` et les `cells_to_plot`
        # et retourne un ensemble de coordonnées pour le bassin.
        # Exemple (non testé, dépend de votre implémentation de capture_basin) :
        # current_K_cells_dict = ShapeGrowthModels.construct_K_cells_dict(model.grid_size) # Si nécessaire
        # basin_coords = ShapeGrowthModels.compute_capture_basin(model, cells_to_plot, current_K_cells_dict, model.cell_type_sequence)
        # for (bx, by) in basin_coords
        #     plot_matrix[by, bx] = some_basin_value # Ex: 99 pour le bassin
        # end

        p = Plots.heatmap(
            plot_matrix,
            aspect_ratio = :equal,
            title = "Simulation Time: $(model.current_time)", # Ajoutez le temps si disponible
            xlabel = "X", ylabel = "Y",
            colorbar_title = "Cell Type",
            xticks = :none, yticks = :none,
            # Définissez une palette de couleurs si vous avez des valeurs spécifiques (types de cellules, bassin)
            # colors = cgrad([:white, :red, :blue, :green, :orange], [0, 1, 2, 3, 99]) # Exemple
        )
        return p
    end

    # Utilisez la macro @animate pour créer l'animation
    # Il itère sur model.history et appelle la fonction pour chaque entrée
    anim = @animate for history_entry in model.history
        animation_plot_function(history_entry)
    end

    # Sauvegardez l'animation au format GIF
    Plots.gif(anim, output_filename, fps = 5) # fps = frames per second
#    println("DEBUG: Animation 2D de l'historique sauvegardée dans ", output_filename)
end



"""
    visualize_history_3D_frames(model::CellModel{3}, output_dir::String)

Crée une série de fichiers HTML PlotlyJS, un pour chaque pas de temps de l'historique du modèle 3D.
Chaque fichier HTML contient une visualisation 3D interactive de l'état des cellules à ce pas de temps.
"""
function visualize_history_3D_frames(model::CellModel{3}, output_dir::String)
    # Assurez-vous que le répertoire de sortie existe
    if !isdir(output_dir)
        mkpath(output_dir)
    end

#    println("DEBUG: Démarrage de la génération des frames 3D de l'historique dans ", output_dir)

    for (i, history_entry) in enumerate(model.history)
        # history_entry est un NamedTuple{(:cells, :stromal_cells), ...}
        cells_to_visualize = history_entry.cells # Accéder au dictionnaire des cellules pour ce pas de temps

        # Initialisation des tableaux pour les coordonnées et types de cellules
        cell_x = Float64[]
        cell_y = Float64[]
        cell_z = Float64[]
        cell_types = Int64[]

        # Remplir les tableaux avec les données des cellules
        for (coords, cell) in cells_to_visualize
            push!(cell_x, coords[1])
            push!(cell_y, coords[2])
            push!(cell_z, coords[3])
            push!(cell_types, cell.cell_type)
        end

        # Créer la trace scatter3d
        trace = PlotlyJS.scatter3d(
            x=cell_x,
            y=cell_y,
            z=cell_z,
            mode="markers",
            marker=PlotlyJS.attr(
                size=5,
                color=cell_types,
                colorscale="Viridis", # Ou toute autre palette de couleurs Plotly
                cmin=minimum(model.cell_type_sequence), # Utiliser les min/max des types de cellules globaux pour une échelle cohérente
                cmax=maximum(model.cell_type_sequence),
                colorbar_title="Cell Type",
                opacity=0.8
            ),
            name="Cellules"
        )

        # Définir le layout de la scène 3D. Utilisez l'index 'i-1' comme temps de simulation.
        layout = PlotlyJS.Layout(
            title="Temps de simulation: $(i-1) / $(length(model.history)-1)", # Affiche le temps actuel / temps total
            scene=PlotlyJS.attr(
                xaxis_title="X Coordinate",
                yaxis_title="Y Coordinate",
                zaxis_title="Z Coordinate",
                aspectmode="data", # Important pour que les échelles soient égales
                # Définir les limites des axes pour qu'elles soient cohérentes sur toutes les frames
                # Utiliser grid_size de votre model pour définir les limites
                xaxis=attr(range=[0, model.grid_size[1]]),
                yaxis=attr(range=[0, model.grid_size[2]]),
                zaxis=attr(range=[0, model.grid_size[3]])
            ),
            hovermode="closest"
        )

        # Créer l'objet plot final
        plot_obj = PlotlyJS.plot(trace, layout)

        # Construire le nom de fichier pour cette frame (ex: frame_000.html, frame_001.html)
        # lpad(i-1, 3, '0') formate l'index avec des zéros en tête (000, 001, ...)
        frame_filename = joinpath(output_dir, "frame_$(lpad(i-1, 3, '0')).html")
        #frame_filename = joinpath(output_dir, "frame_$(lpad(i-1, 3, '0')).png")
        PlotlyJS.savefig(plot_obj, frame_filename) # Sauvegardera un PNG statique
#        println("DEBUG: Frame 3D $(i-1) sauvegardée: ", frame_filename)
    end
#    println("DEBUG: Génération des frames 3D terminée.")
end

function visualize_history_3D_plotly_with_slider(model::CellModel{3}, filename::String)
    if !endswith(filename, ".html")
        filename *= ".html"
    end

#    println("DEBUG: Démarrage de la génération de la visualisation 3D avec slider pour l'historique.")

    initial_cells = model.history[1].cells

    initial_cell_x = Float64[]
    initial_cell_y = Float64[]
    initial_cell_z = Float64[]
    initial_cell_types = Int64[]

    for (coords, cell) in initial_cells
        push!(initial_cell_x, coords[1])
        push!(initial_cell_y, coords[2])
        push!(initial_cell_z, coords[3])
        push!(initial_cell_types, cell.cell_type)
    end

    initial_trace = PlotlyJS.scatter3d(
        x=initial_cell_x,
        y=initial_cell_y,
        z=initial_cell_z,
        mode="markers",
        marker=attr( # Now just `attr`
            size=5,
            color=initial_cell_types,
            colorscale="Viridis",
            cmin=minimum(model.cell_type_sequence),
            cmax=maximum(model.cell_type_sequence),
            colorbar_title="Cell Type",
            opacity=0.8
        ),
        name="Cellules",
    )

    frames = []
    for i in 1:length(model.history)
        history_entry = model.history[i]
        cells_at_time_i = history_entry.cells

        current_cell_x = Float64[]
        current_cell_y = Float64[]
        current_cell_z = Float64[]
        current_cell_types = Int64[]

        for (coords, cell) in cells_at_time_i
            push!(current_cell_x, coords[1])
            push!(current_cell_y, coords[2])
            push!(current_cell_z, coords[3])
            push!(current_cell_types, cell.cell_type)
        end

        push!(frames, Frame( # Now just `Frame`
            data=[PlotlyJS.scatter3d(
                x=current_cell_x,
                y=current_cell_y,
                z=current_cell_z,
                mode="markers",
                marker=attr( # Now just `attr`
                    size=5,
                    color=current_cell_types,
                    colorscale="Viridis",
                    cmin=minimum(model.cell_type_sequence),
                    cmax=maximum(model.cell_type_sequence),
                    colorbar_title="Cell Type",
                    opacity=0.8
                ),
                name="Cellules"
            )],
            name=string(i-1),
            layout=Layout(title="Temps de simulation: $(i-1)") # Now just `Layout`
        ))
    end 

    sliders = [attr( # Now just `attr`
        steps=[attr( # Now just `attr`
            method="animate",
            args=[[f.name], attr( # Now just `attr`
                mode="immediate",
                transition=attr(duration=0), # Now just `attr`
                frame=attr(duration=0, redraw=true) # Now just `attr`
            )],
            label=f.name
        ) for f in frames],
        active=0,
        pad=attr(t=50), # Now just `attr`
        currentvalue=attr( # Now just `attr`
            visible=true,
            prefix="Temps: ",
            xanchor="right"
        ),
        transition=attr(duration=0), # Now just `attr`
        len=0.9
    )]

    updatemenus = [attr( # Now just `attr`
        type="buttons",
        buttons=[attr( # Now just `attr`
            label="Play",
            method="animate",
            args=[nothing, attr( # Now just `attr`
                fromcurrent=true,
                transition=attr(duration=200, easing="linear"), # Now just `attr`
                frame=attr(duration=200, redraw=true) # Now just `attr`
            )]
        ),
        attr( # Now just `attr`
            label="Pause",
            method="animate",
            args=[[nothing], attr( # Now just `attr`
                mode="immediate",
                transition=attr(duration=0) # Now just `attr`
            )]
        )],
        direction="left",
        pad=attr(r=10, t=80), # Now just `attr`
        showactive=false,
        x=0.1,
        xanchor="right",
        y=0,
        yanchor="top"
    )]

    layout = Layout( # Now just `Layout`
        title="Animation 3D des Cellules avec Curseur Temporel",
        scene=attr( # Now just `attr`
            xaxis_title="X Coordinate",
            yaxis_title="Y Coordinate",
            zaxis_title="Z Coordinate",
            aspectmode="data",
            xaxis=attr(range=[0, model.grid_size[1]]), # Now just `attr`
            yaxis=attr(range=[0, model.grid_size[2]]), # Now just `attr`
            zaxis=attr(range=[0, model.grid_size[3]])  # Now just `attr`
        ),
        sliders=sliders,
        updatemenus=updatemenus,
        hovermode="closest",
        showlegend=true
    )

    plot_obj = PlotlyJS.plot(initial_trace, layout, frames)
    PlotlyJS.savefig(plot_obj, filename)

#    println("DEBUG: Visualisation 3D avec slider sauvegardée dans ", filename)
    return plot_obj
end