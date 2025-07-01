using Shape_Growth_Populate
using Plots

const Dim = 2
const XML_PATH = "xml/cellTypes130.xml"

cell_type_sequence = [130]
num_steps = 50
dist_cellule_fibroblast = 25.0
max_divisions = dist_cellule_fibroblast + 10

STROMAL_RING_RADIUS = dist_cellule_fibroblast
STROMAL_WIDTH = 1
NUM_STROMAL_CELLS = 100

initial_cell_origin = (50, 50)
grid_size = (100, 100)

fracton_types = Dict(1 => 90, 2 => 91, 3 => 92, 4 => 93)
differentiated_types = Dict(90 => 9, 91 => 8, 92 => 7, 93 => 10)

differentiated_list = collect(values(differentiated_types))
cell_types_all = vcat(cell_type_sequence, differentiated_list)
max_divisions_dict = Dict(t => max_divisions for t in cell_types_all)

initial_cell = Shape_Growth_Populate.create_default_initial_cells_dict(
    Val(Dim), initial_cell_origin, 130)

stromal_dict = Dict{NTuple{2, Int}, Shape_Growth_Populate.StromalCell{2}}()
for r in STROMAL_RING_RADIUS:(STROMAL_RING_RADIUS + STROMAL_WIDTH)
    for θ in range(0, 2π, length=NUM_STROMAL_CELLS+1)[1:end-1]
        x = round(Int, initial_cell_origin[1] + r * cos(θ))
        y = round(Int, initial_cell_origin[2] + r * sin(θ))
        coord = (x, y)

        angle = mod(θ, 2π)
        quadrant = angle < π/2 ? 1 : angle < π ? 2 : angle < 3π/2 ? 3 : 4
        stromal_type = fracton_types[quadrant]
        θ_local = mod(θ, π/2)
        prop = 1.0 - θ_local / (π/2)
        diff_type = differentiated_types[stromal_type]
        max_div = round(Int, max_divisions * (0.5 + 0.5 * prop))
        stromal_dict[coord] = Shape_Growth_Populate.StromalCell{2}(coordinates=coord, cell_type=stromal_type)
        max_divisions_dict[diff_type] = max(max_divisions_dict[diff_type], max_div)
    end
end

get_max_divisions(cell::Shape_Growth_Populate.Cell) = get(max_divisions_dict, cell.cell_type, 0)

function blocked_by_stromal(cell)
    x, y = cell.coordinates
    for dx in -1:1, dy in -1:1
        neighbor = (x + dx, y + dy)
        if haskey(model.stromal_cells, neighbor)
            stromal = model.stromal_cells[neighbor]
            if haskey(differentiated_types, stromal.cell_type) && cell.cell_type == 130
                cell.cell_type = differentiated_types[stromal.cell_type]
                return max_divisions
            end
            return 0
        end
    end
    return get_max_divisions(cell)
end

model = Shape_Growth_Populate.CellModel{Dim}(
    initial_cells_dict = initial_cell,
    initial_stromal_cells_dict = stromal_dict,
    xml_file = XML_PATH,
    cell_type_sequence = cell_types_all,
    grid_size = grid_size,
    dist_cellule_fibroblast = dist_cellule_fibroblast
)

allow_division(cell::Shape_Growth_Populate.Cell) = get_max_divisions(cell)

for t in cell_types_all
    f = t == 130 ? blocked_by_stromal : allow_division
    Shape_Growth_Populate.set_max_function!(model, t, f)
end

println("Starting simulation...")
Shape_Growth_Populate.run!(model, num_steps = num_steps)
println("Simulation completed.")

output_dir = "expl"
animation_filename = joinpath(output_dir, "TEST.gif")
Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
println("Animation saved to: $animation_filename")
