using PlotlyJS

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

), Layout(margin=attr(l=0, r=0, b=0, t=0)))