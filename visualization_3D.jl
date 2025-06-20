using GLMakie
using Colors
using GeometryBasics # Pour Rect3f

# ... (Votre fonction get_3d_cell_data_for_plot définie comme précédemment) ...

function visualize_history_makie_3d_voxels_simplified( # Nouvelle version recommandée
    history::Vector{Dict{NTuple{Dim, Int64}, Cell{Dim}}},
    grid_size::NTuple{Dim, Int64},
    cell_data::Dict{Int64, Dict{String, Any}},
    filename::String
) where Dim
    if Dim != 3
        error("Cette fonction de visualisation Makie 3D (voxels) ne supporte que Dim=3.")
    end

    x_max = grid_size[1]
    y_max = grid_size[2]
    z_max = grid_size[3]

    f = Figure(size=(1000, 1000))
    ax = LScene(f[1, 1], show_axis=true)
    
    # Observables pour les positions et les couleurs
    positions_obs = Observable(Point3f[]) 
    colors_obs = Observable(RGBf[])

    # Utilisez `meshscatter!` pour tracer les cubes
    # marker=Rect3f(0,0,0,1,1,1) indique que le marqueur est un cube de taille 1x1x1
    # markersize=1 indique que chaque marqueur a sa taille d'unité (le cube)
    # Les coordonnées passées sont le centre du cube.
    # Si vos coordonnées de cellule sont (1,1,1), le cube sera de (0.5,0.5,0.5) à (1.5,1.5,1.5)
    main_plot = meshscatter!(ax, positions_obs, color=colors_obs, 
                             marker=Rect3f(0,0,0,1,1,1), markersize=1, shading=true)
    
    xlims!(ax, 0.5, x_max + 0.5)
    ylims!(ax, 0.5, y_max + 0.5)
    zlims!(ax, 0.5, z_max + 0.5)

    cam3d!(ax.scene)
    
    record(f, filename, enumerate(history); framerate=2) do (step_idx, current_cells_dict)
        cell_coords_float, cell_colors_rgb = get_3d_cell_data_for_plot(current_cells_dict, cell_data)

        if !isempty(cell_coords_float)
            positions_obs[] = [Point3f(p...) for p in cell_coords_float]
            colors_obs[] = [RGBf(c.r, c.g, c.b) for c in cell_colors_rgb]
        else
            positions_obs[] = Point3f[]
            colors_obs[] = RGBf[]
        end
        
        ax.scene.title = "Étape $(step_idx-1)"
        sleep(0.01)
    end
end