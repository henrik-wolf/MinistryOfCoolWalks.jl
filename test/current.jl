using MinistryOfCoolWalks
using ArchGDAL
using ShadowGraphs
using CompositeBuildings
using TreeLoaders
using Graphs
using MetaGraphs
using Folium
using GeoInterface
using DataFrames

datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])
trees = load_nottingham_trees(joinpath(datapath, "trees/trees_full_rest.csv"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
_, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
#lines_linear = add_shadow_intervals_linear!(g, shadows)  # takes about 1:48 minutes
_, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
lines_normal = add_shadow_intervals!(g, shadows)  # takes about 0:11 minutes


describe(lines_normal)
describe(old_lines)
begin
    p = plot()
    plot!(ArchGDAL.buffer(lines_normal, 1e-8, 1))
    for i in getgeom(lines_normal)
        plot!(p, i, lw=6, alpha=0.4, xlims=(-0.1, 0.))
    end
    plot!()
end

begin
    fig = draw(shadows.geometry;
        figure_params=Dict(:location=>(52.904, -1.18), :zoom_start=>14),
        fill_opacity=0.5,
        color=:black)
    draw!(fig, buildings.geometry)
    draw!(fig, g, :vertices)
    draw!(fig, g, :edges)
    draw!(fig, g, :shadowgeom)
    draw!(fig, get_prop(g, 8,717, :shadowgeom))
end


ngeom(get_prop(g, 8,717, :shadowgeom))

plot()
for i in getgeom(get_prop(g, 8,717, :shadowgeom))
    display(plot!(i, lw=6, alpha=0.4))
end