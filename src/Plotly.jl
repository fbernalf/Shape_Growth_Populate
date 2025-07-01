using PlotlyJS, CSV, DataFrames
#df = dataset(DataFrame, "iris")
#plot(
#    df,
#    x=:sepal_length, y=:sepal_width, z=:petal_width, color=:species,
#    type="scatter3d", mode="markers"
#)

#= using PlotlyJS, CSV, DataFrames


df = dataset(DataFrame, "iris")

plot(

    df, Layout(margin=attr(l=0, r=0, b=0, t=0)),

    x=:sepal_length, y=:sepal_width, z=:petal_width, color=:species,

    type="scatter3d", mode="markers",

    marker_size=:petal_length, marker_sizeref=0.3,

) =#
#= 
# Helix equation
t = range(0, stop=20, length=100)

plot(scatter(
    x=cos.(t),
    y=sin.(t),
    z=t,
    mode="markers",
    marker=attr(
        size=12,
        color=t,                # set color to an array/list of desired values
        colorscale="Viridis",   # choose a colorscale
        opacity=0.8
    ),
    type="scatter3d"
), Layout(margin=attr(l=0, r=0, b=0, t=0))) =#