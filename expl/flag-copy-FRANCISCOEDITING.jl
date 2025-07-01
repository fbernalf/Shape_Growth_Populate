using Shape_Growth_Populate
using Plots

# Parámetros originales
const Dim = 2
const XML_PATH = "xml/cellTypes130.xml"

cell_type_sequence = [7, 8, 9, 10]
num_steps = 20

# Parámetros "nuevos"
STROMAL_TYPE = 6
STROMAL_RING_RADIUS = 5
STROMAL_WIDTH = 0.5
NUM_STROMAL_CELLS = 80

# Grilla y posición inicial según la dimensión
if Dim == 2
    initial_cell_origin = (50, 50)
    grid_size = (100, 100)
elseif Dim == 3
    initial_cell_origin = (50, 50, 5)
    grid_size = (100, 100, 10)
end

# Definir funciones de división
function fct7(cell::Shape_Growth_Populate.Cell{Dim})
    return 20
end

function fct8(cell::Shape_Growth_Populate.Cell{Dim})
    return 20
end

function fct9(cell::Shape_Growth_Populate.Cell{Dim})
    return 20
end

function fct10(cell::Shape_Growth_Populate.Cell{Dim})
    return 20
end

initial_cell = Shape_Growth_Populate.create_default_initial_cells_dict(
    Val(Dim), initial_cell_origin, cell_type_sequence[1])

for r in STROMAL_RING_RADIUS:(STROMAL_RING_RADIUS + STROMAL_WIDTH)
    for θ in range(0, 2π, length=NUM_STROMAL_CELLS+1)[1:end-1]
        x = round(Int, initial_cell_origin[1] + r * cos(θ))
        y = round(Int, initial_cell_origin[2] + r * sin(θ))
        coord = (x, y)
        stromal_dict[coord] = Shape_Growth_Populate.StromalCell{2}(coordinates=coord, cell_type=STROMAL_TYPE)
    end
end


model = Shape_Growth_Populate.CellModel{Dim}(
    initial_cells_dict = initial_cell,
    initial_stromal_cells_dict = stromal_dict,
    xml_file = XML_PATH,
    cell_type_sequence = cell_type_sequence,
    grid_size = grid_size,
    dist_cellule_fibroblast = 6.0)

Shape_Growth_Populate.set_max_function!(model, 7, fct7)
Shape_Growth_Populate.set_max_function!(model, 8, fct8)
Shape_Growth_Populate.set_max_function!(model, 9, fct9)
Shape_Growth_Populate.set_max_function!(model, 10, fct10)

# simulation
println("Iniciando simulación...")
Shape_Growth_Populate.run!(model, num_steps = num_steps)
println("Simulación completada.")

# visualization
output_dir = "expl/"
animation_filename = joinpath(output_dir, "circle_growth_simulation_fixed.gif")
Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
println("Animación guardada en: $animation_filename")
#println(stromal_dict)