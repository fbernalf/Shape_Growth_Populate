using Shape_Growth_Populate
using Plots

const Dim = 2
const XML_PATH = "xml/cellTypes130.xml"

cell_type_sequence = [130, 7, 8, 9, 10]
num_steps = 80
dist_cellule_fibroblast = 25.0
max_divisions = 60

initial_cell_origin = (50, 50)
grid_size = (100, 100)

const STROMAL_TYPE_Q1 = 91
const STROMAL_TYPE_Q2 = 92
const STROMAL_TYPE_Q3 = 93
const STROMAL_TYPE_Q4 = 94

STROMAL_RING_RADIUS = dist_cellule_fibroblast
STROMAL_WIDTH = 1
NUM_STROMAL_CELLS = 200 

initial_cell = Shape_Growth_Populate.create_default_initial_cells_dict(
    Val(Dim), initial_cell_origin, 130)

stromal_dict = Dict{NTuple{2, Int}, Shape_Growth_Populate.StromalCell{2}}()
for r in STROMAL_RING_RADIUS:(STROMAL_RING_RADIUS + STROMAL_WIDTH)
    for theta in range(0, 2π, length=NUM_STROMAL_CELLS+1)[1:end-1]
        stromal_type = if theta == π/4
            STROMAL_TYPE_Q1
        elseif theta == 3π/4
            STROMAL_TYPE_Q2
        elseif theta == 5π/4
            STROMAL_TYPE_Q3
        else
            STROMAL_TYPE_Q4
        end
        coord = (
            round(Int, initial_cell_origin[1] + r * cos(theta)),
            round(Int, initial_cell_origin[2] + r * sin(theta))
        )
        # Avoid overwriting to preserve heterogeneity of the ring
        if !haskey(stromal_dict, coord)
            stromal_dict[coord] = Shape_Growth_Populate.StromalCell{2}(coordinates=coord, cell_type=stromal_type)
        end
    end
end

max_divisions_dict = Dict(t => max_divisions for t in cell_type_sequence)
get_max_divisions(cell::Shape_Growth_Populate.Cell) = get(max_divisions_dict, cell.cell_type, 0)

# Interaction logic for cell type 130: triggers differentiation based on stromal neighbors
function interact_with_stromal_ring(cell::Shape_Growth_Populate.Cell, model::Shape_Growth_Populate.CellModel)
    x, y = cell.coordinates
    for dx in -1:1, dy in -1:1
        if dx == 0 && dy == 0 continue end
        neighbor = (x + dx, y + dy)
        if haskey(model.stromal_cells, neighbor)
            stromal_type = model.stromal_cells[neighbor].cell_type
            cell.cell_type = stromal_type == STROMAL_TYPE_Q1 ? 9 :
                             stromal_type == STROMAL_TYPE_Q2 ? 8 :
                             stromal_type == STROMAL_TYPE_Q3 ? 7 :
                             stromal_type == STROMAL_TYPE_Q4 ? 10 : cell.cell_type
            return get_max_divisions(cell)
        end
    end
    return get_max_divisions(cell)
end

model = Shape_Growth_Populate.CellModel{Dim}(
    initial_cells_dict = initial_cell,
    initial_stromal_cells_dict = stromal_dict,
    xml_file = XML_PATH,
    cell_type_sequence = cell_type_sequence,
    grid_size = grid_size,
    dist_cellule_fibroblast = dist_cellule_fibroblast)

# Assign division rules: initial cell interacts with the ring, differentiated ones don't
Shape_Growth_Populate.set_max_function!(model, 130, cell -> interact_with_stromal_ring(cell, model))
for t in [7, 8, 9, 10]
    Shape_Growth_Populate.set_max_function!(model, t, get_max_divisions)
end

println("Starting simulation...")
Shape_Growth_Populate.run!(model, num_steps = num_steps)
println("Simulation completed.")

output_dir = "expl"
mkpath(output_dir)
animation_filename = joinpath(output_dir, "fractones_ring_2.gif")
Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
println("Animation saved to: $animation_filename")
