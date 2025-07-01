using Shape_Growth_Populate
using Plots

# General parameters
const Dim = 2
const XML_PATH = "xml/cellTypes130.xml"
NUM_STEPS = 50
DIST_CELLULE_FIBROBLAST = 25.0
MAX_DIVISIONS = 50
STROMAL_TYPE = 99
STROMAL_WIDTH = 1
NUM_STROMAL_CELLS = 100
INITIAL_CELL_ORIGIN = (50, 50)
GRID_SIZE = (100, 100)

# Run simulation for a single cell type
function run_simulation_for_type(cell_type::Int)
    cell_type_sequence = [cell_type]
    stromal_ring_radius = DIST_CELLULE_FIBROBLAST

    initial_cell = Shape_Growth_Populate.create_default_initial_cells_dict(
        Val(Dim), INITIAL_CELL_ORIGIN, cell_type)

    stromal_dict = Dict{NTuple{2, Int}, Shape_Growth_Populate.StromalCell{2}}()
    for r in stromal_ring_radius:(stromal_ring_radius + STROMAL_WIDTH)
        for θ in range(0, 2π, length=NUM_STROMAL_CELLS+1)[1:end-1]
            coord = (
                round(Int, INITIAL_CELL_ORIGIN[1] + r * cos(θ)),
                round(Int, INITIAL_CELL_ORIGIN[2] + r * sin(θ))
            )
            stromal_dict[coord] = Shape_Growth_Populate.StromalCell{2}(coordinates=coord, cell_type=STROMAL_TYPE)
        end
    end

    max_divisions_dict = Dict(t => MAX_DIVISIONS for t in cell_type_sequence)

    get_max_divisions(cell::Shape_Growth_Populate.Cell) = get(max_divisions_dict, cell.cell_type, 0)

    function blocked_by_stromal(cell)
        x, y = cell.coordinates
        for dx in -1:1, dy in -1:1
            if haskey(model.stromal_cells, (x + dx, y + dy))
                return 0
            end
        end
        return get_max_divisions(cell)
    end

    model = Shape_Growth_Populate.CellModel{Dim}(
        initial_cells_dict = initial_cell,
        initial_stromal_cells_dict = stromal_dict,
        xml_file = XML_PATH,
        cell_type_sequence = cell_type_sequence,
        grid_size = GRID_SIZE,
        dist_cellule_fibroblast = DIST_CELLULE_FIBROBLAST
    )

    for t in cell_type_sequence
        Shape_Growth_Populate.set_max_function!(model, t, blocked_by_stromal)
    end

    println("Simulating cell type $cell_type...")
    Shape_Growth_Populate.run!(model, num_steps = NUM_STEPS)

    output_dir = "expl/gifs_individuales"
    animation_filename = joinpath(output_dir, "type_$cell_type.gif")
    Shape_Growth_Populate.visualize_history_animation(model, animation_filename)
    println("Animation saved to: $animation_filename")
end

for cell_type in 1:130
    run_simulation_for_type(cell_type)
end
