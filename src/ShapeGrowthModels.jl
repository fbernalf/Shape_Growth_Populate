module ShapeGrowthModels
# This module contains the implementation of various shape growth models
# and their associated functions.
# It includes the following files:
# - functions.jl: Contains utility functions for the models.
# - data_xml.jl: Contains functions for reading and writing XML data files.
# - visualization_xml.jl: Contains functions for visualizing the models.
# - struct_cell_env.jl: Contains the structure for cells and their properties.

# It's good practice to include files that define types and core functionalities first.
# If initialization.jl depends on functions from data_xml.jl or types from struct_cell_env.jl,
# those files must be included before initialization.jl.

using EzXML
using ColorSchemes
using ColorTypes
using Plots
using Parameters
using PlotlyJS
#using PlotlyBase#

#import PlotlyBase: Frame, attr
dirname(@__FILE__)
# Define the path to the XML file
#xml_file = "cellTypes.xml"

const DEFAULT_STROMAL_CELL_TYPE = 99 # <--- AJOUTEZ CETTE LIGNE (utilisez la valeur appropriée pour votre type de cellule stromale par défaut)
const STROMAL_PROXIMITY_DISTANCE = 3

include("struct_cell_env.jl") # Include cell structures first if initialization depends on them
include("data_xml.jl")  
include("functions_max.jl")      # Include data loading functions (like load_cell_data) before they are used
include("functions.jl")       # General utility functions
include("visualization_xml.jl") # Visualization functions
include("visualization_3D.jl") # 3D visualization functions
include("capture_basin.jl")

#include("initialization.jl") # Initialization functions that depend on the above files
# If you want to make specific functions or variables accessible directly
# when someone uses `using ShapeGrowthModels`, you should export them here.
# For example, if `initial_cells` or `load_cell_data` are meant to be public:
# export initial_cells, load_cell_data


    export Cell, CellSetByCoordinates, CellModel
    export create_default_initial_cells_dict, initial_cells_dict_default
    export run_simulation, cellular_dynamics
    export reconfigure_model_with_sequence!, set_subdivision!
    export visualize_cells_dict # Si vous avez une fonction visualize_cells exportable
    export load_cell_data
    export get_generated_form
    export visualize_history
    export create_directions, create_directions_dict
    export create_max_cell_divisions_dict
    export set_type_sequence!
    export visualize_3D_plotly
    export visualize_history_animation
    export visualize_history_3D_frames
    export visualize_history_3D_plotly_with_slider

    







end # module ShapeGrowthModels




