using MinistryOfCoolWalks

using ShadowGraphs
using CompositeBuildings
using TreeLoaders
using Graphs
using MetaGraphs

datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.6])
trees = load_nottingham_trees(joinpath(datapath, "trees/trees_full_rest.csv"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))


begin
    m = polygons(shadows.geometry; 
    figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14, :tiles=>"CartoDB PositronNoLabels"),
    color="black", fill=true, stroke=false, fill_opacity=0.4)
    circles!(m, trees.lon, trees.lat; radius=5, color="#68bd61", stroke=false, fill=true, fill_opacity=0.3)
    polygons!(m, buildings.geometry; fill=true, stroke=false, fill_opacity=1)
end

_, g = shadow_graph_from_file(joinpath(datapath, "test_nottingham.json"))
begin
    m = polygons(shadows.geometry; 
        figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14, :tiles=>"CartoDB PositronNoLabels"),
        color="black", fill=true, stroke=false, fill_opacity=0.4)
    circles!(m, trees.lon, trees.lat; radius=5, color="#68bd61", stroke=false, fill=true, fill_opacity=0.3)
    polygons!(m, buildings.geometry; fill=true, stroke=false, fill_opacity=1)
    polygons!(m, filter(:id=>id->id in shadowing.shadow, buildings).geometry; fill=true, color="red", stroke=false, fill_opacity=1)
    polylines!(m, shadowing.shadow; weight=5, color="black")
    graph_node_circles!(m, g; radius=1, color="#e2b846")
    graph_edges!(m, g; weight=2, color="#e56c6c", opacity=0.5)
end

shadowing = add_shadow_intervals!(g, shadows)

using Plots
scatter(shadowing.parts_length, shadowing.union_length)

overlap = filter([:parts_length, :union_length]=>(p, u)->abs(p-u) > 1e-8, shadowing)
overlap.parts_length - overlap.union_length

edge_lengths = [get_prop(g, edge, :shadowed_length) for edge in edges(g) if has_prop(g, edge, :shadowed_length)]

way(38072263)

