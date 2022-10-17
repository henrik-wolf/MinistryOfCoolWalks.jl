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
@profview lines_reconstructed = add_shadow_intervals!(g, shadows; method=:reconstruct)
_, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
lines_normal = add_shadow_intervals!(g, shadows)  # takes about 0:11 minutes

scatter(2lines_normal.spl .- lines_reconstructed.spl)

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


#POLYGON ((-1.18871433326168 52.9075475452531,-1.18874327518357 52.9074308810968,-1.18885830894734 52.9074415541226,-1.18882863220356 52.9075577642415,-1.18871433326168 52.9075475452531))
#Spatial Reference System: +proj=longlat +datum=WGS84 +no_defs
#he terminal process "/Users/henrikwolf/.julia/juliaup/julia-1.8.0+0.aarch64/bin/julia '-i', '--banner=no', '--project=/Users/henrikwolf/Desktop/Masterarbeit/packages/MinistryOfCoolWalks.jl', '/Users/henrikwolf/.vscode/extensions/julialang.language-julia-1.37.2/scripts/terminalserver/terminalserver.jl', '/var/folders/bt/2m4mg981285dt0_6mz596v000000gn/T/vsc-jl-repl-41d504be-790b-4584-b0a2-560623d9b073', '/var/folders/bt/2m4mg981285dt0_6mz596v000000gn/T/vsc-jl-cr-b25b8e51-7f5b-4990-82dc-e99e23d7ea81', 'USE_REVISE=true', 'USE_PLOTPANE=true', 'USE_PROGRESS=true', 'ENABLE_SHELL_INTEGRATION=true', 'DEBUG_MODE=false'" terminated with exit code: 139.