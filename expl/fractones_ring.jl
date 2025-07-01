using Shape_Growth_Populate
using Plots

# --- GENERAL PARAMETERS ---
const Dim = 2
const XML_PATH = "xml/cellTypes130.xml"
const NUM_STEPS = 50
const DIST_CELLULE_FIBROBLAST = 25.0
const MAX_DIVISIONS = 50

# --- STROMAL RING CONFIGURATION ---
const STROMAL_TYPES_BY_QUADRANT = Dict(
    1 => 91,
    2 => 92,
    3 => 93,
    4 => 94
)
const STROMAL_RING_RADIUS = DIST_CELLULE_FIBROBLAST
const STROMAL_WIDTH = 1
const NUM_STROMAL_CELLS = 100

# --- INITIAL GRID AND CELL POSITION ---
const INITIAL_POS = (50, 50)
const GRID_SIZE = (100, 100)
const INITIAL_TYPE = 130

# --- INITIAL CELL ---
initial_cell = Shape_Growth_Populate.create_default_initial_cells_dict(
    Val(Dim), INITIAL_POS, INITIAL_TYPE
)

# --- STROMAL RING CREATION ---
stromal_dict = Dict{NTuple{2, Int}, Shape_Growth_Populate.StromalCell{2}}()
for r in STROMAL_RING_RADIUS:(STROMAL_RING_RADIUS + STROMAL_WIDTH)
    for θ in range(0, 2π, length=NUM_STROMAL_CELLS+1)[1:end-1]
        x = round(Int, INITIAL_POS[1] + r * cos(θ))
        y = round(Int, INITIAL_POS[2] + r * sin(θ))
        coord = (x, y)

        quadrant = if 0 ≤ θ < π/2
            1
        elseif π/2 ≤ θ < π
            2
        elseif π ≤ θ < 3π/2
            3
        else
            4
        end

        stromal_type = STROMAL_TYPES_BY_QUADRANT[quadrant]
        stromal_dict[coord] = Shape_Growth_Populate.StromalCell{2}(coordinates=coord, cell_type=stromal_type)
    end
end

# --- DIVISION LIMITS ---
cell_type_sequence = [INITIAL_TYPE]
max_divisions_dict = Dict(t => MAX_DIVISIONS for t in [130, 7, 8, 9, 10])

get_max_divisions(cell::Shape_Growth_Populate.Cell) = get(max_divisions_dict, cell.cell_type, 0)

# --- DIVISION FUNCTION WITH DIFFERENTIATION ---
function blocked_by_stromal(cell)
    x, y = cell.coordinates
    for dx in -1:1, dy in -1:1
        neighbor = (x + dx, y + dy)
        if haskey(model.stromal_cells, neighbor)
            stromal_type = model.stromal_cells[neighbor].cell_type
            new_type = stromal_type == 91 ? 9 :
                       stromal_type == 92 ? 8 :
                       stromal_type == 93 ? 7 :
                       stromal_type == 94 ? 10 : nothing
            if new_type !== nothing && cell.cell_type != new_type
                cell.cell_type = new_type
                return MAX_DIVISIONS
            end
            return 0
        end
    end
    return get_max_divisions(cell)
end

# --- MODEL ---
model = Shape_Growth_Populate.CellModel{Dim}(
    initial_cells_dict = initial_cell,
    initial_stromal_cells_dict = stromal_dict,
    xml_file = XML_PATH,
    cell_type_sequence = cell_type_sequence,
    grid_size = GRID_SIZE,
    dist_cellule_fibroblast = DIST_CELLULE_FIBROBLAST
)

# --- ASSIGN DIVISION RULE ---
Shape_Growth_Populate.set_max_function!(model, INITIAL_TYPE, blocked_by_stromal)

# --- RUN SIMULATION ---
println("Starting simulation...")
Shape_Growth_Populate.run!(model, num_steps = NUM_STEPS)
println("Simulation completed.")

# --- VISUALIZATION ---
output_dir = "expl"
animation_filename = joinpath(output_dir, "fractones_ring.gif")
Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
println("Animation saved to: $animation_filename")
