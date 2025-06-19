using PlotlyJS # Assurez-vous que PlotlyJS est chargé

# --- Votre code de simulation va ici ---
# (Assurez-vous que 'model' est déjà défini et que la simulation a tourné)

# Vérifier si DIM est bien 3
if DIM != 3
    println("ATTENTION: DIM n'est pas égal à 3. La visualisation Scatter3D pourrait ne pas être pertinente.")
    println("Actuellement DIM = ", DIM, ". Définissez DIM = 3 pour une vraie visualisation 3D.")
    # On peut quand même continuer pour montrer la syntaxe, mais les points seront sur un plan.
end

# Obtenir le dernier état des cellules (le dernier élément de history)
# Si vous voulez vraiment le premier état (history[1]), changez simplement 'end' en '1'.
cells_to_visualize = model.history[end].cells

# Extraire les coordonnées X, Y, Z des cellules
# On va aussi extraire le type de cellule pour pouvoir les colorer différemment
cell_x = Float64[]
cell_y = Float64[]
cell_z = Float64[]
cell_types = Int64[] # Pour stocker les types de cellules pour la couleur

for (coords, cell) in cells_to_visualize
    # Les coordonnées sont des NTuple{DIM, Int64}.
    # Pour DIM=3, ce sera (x, y, z)
    push!(cell_x, coords[1])
    push!(cell_y, coords[2])
    push!(cell_z, coords[3])
    push!(cell_types, cell.cell_type) # Supposons que 'cell.cell_type' existe
end

# Créer un trace scatter3d
trace = scatter3d(
    x=cell_x,
    y=cell_y,
    z=cell_z,
    mode="markers", # Pour afficher des points
    marker=attr(
        size=5,             # Taille des marqueurs
        color=cell_types,   # La couleur sera basée sur le type de cellule
        colorscale="Viridis", # Ou toute autre palette de couleurs de Plotly
        cmin=minimum(model.cell_type_sequence), # Min pour la colorbar
        cmax=maximum(model.cell_type_sequence), # Max pour la colorbar
        colorbar_title="Cell Type",
        opacity=0.8
    ),
    name="Cellules" # Nom de la trace dans la légende
)

# Définir le layout de la scène 3D
layout = Layout(
    title="Répartition 3D des Cellules (Dernier état)",
    scene=attr(
        xaxis_title="X Coordinate",
        yaxis_title="Y Coordinate",
        zaxis_title="Z Coordinate",
        aspectmode="data" # Pour que les échelles soient égales dans les 3 dimensions
    ),
    hovermode="closest" # Pour une meilleure interactivité au survol
)

# Créer le PlotlyJS plot
plot_obj = plot(trace, layout)

# Afficher le plot (s'ouvrira dans votre navigateur web ou dans VS Code si configuré)
display(plot_obj)

println("DEBUG: Visualisation PlotlyJS Scatter3D générée pour les cellules.")
