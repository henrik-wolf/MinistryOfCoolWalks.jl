using MinistryOfCoolWalks

using ShadowGraphs
using CompositeBuildings
using TreeLoaders


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
    graph_node_circles!(m, g; radius=1, color="#e2b846")
    graph_edges!(m, g; weight=2, color="#e56c6c", opacity=0.5)
end

add_shadow_intervals!(g, shadows)