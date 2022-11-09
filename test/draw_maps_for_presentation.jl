using MinistryOfCoolWalks
using ShadowGraphs
using CompositeBuildings
using TreeLoaders
using Graphs
using MetaGraphs
using Folium
using DataFrames

# load geometry
datapath = joinpath(homedir(), "Desktop/Masterarbeit/data/Nottingham/")
buildings = load_british_shapefiles(joinpath(datapath, "Nottingham.shp"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
trees = load_nottingham_trees(joinpath(datapath, "trees/trees_full_rest.csv"); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))

# calculate shadows
building_shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.4])
tree_shadows = cast_shadow(trees, tree_param_getter_nottingham, [1.0, -0.5, 0.4])

# load network
_, g_bike_clifton = shadow_graph_from_file(joinpath(datapath, "clifton/test_clifton_bike.json"); network_type=:bike)
correct_centerlines!(g_bike_clifton, buildings)

# map only shadows
begin
    fig = draw(tree_shadows.geometry;
    figure_params=Dict(:location=>(52.904, -1.18), :zoom_start=>14),
    fill_opacity=0.5,
    color="#545454")
    draw!(fig, building_shadows.geometry; fill_opacity=0.5, color="#545454")
    for row in eachrow(trees)
        tt = "radius: $(row.CROWN_SPREAD_RADIUS)<br>height: $(row.HEIGHT_N)<br>common name: $(row.COMMONNAME)"
        draw!(fig, row.pointgeom; radius=row.CROWN_SPREAD_RADIUS, color="#71b36b", fill=true, stroke=false, fill_opacity=0.8, tooltip=tt, popup=tt)
    end
    draw!(fig, buildings.geometry) 
    write("0_shadow_map.html", repr("text/html", fig))
end
    
# add shaded lines to graph
add_shadow_intervals_rtree!(g_bike_clifton, building_shadows)
add_shadow_intervals_rtree!(g_bike_clifton, tree_shadows)

# map only graph
begin
    fig = draw(g_bike_clifton, :vertices;
    figure_params=Dict(:location=>(52.904, -1.18), :zoom_start=>14))
    draw!(fig, g_bike_clifton, :edgegeom)
    draw!(fig, g_bike_clifton, :edges)
    write("1_graph_map.html", repr("text/html", fig))
end


# map all
begin
    fig = draw(tree_shadows.geometry;
    figure_params=Dict(:location=>(52.904, -1.18), :zoom_start=>14),
    fill_opacity=0.5,
    color="#545454")
    draw!(fig, building_shadows.geometry; fill_opacity=0.5, color="#545454")

    draw!(fig, g_bike_clifton, :edgegeom)

    for row in eachrow(trees)
        tt = "radius: $(row.CROWN_SPREAD_RADIUS)<br>height: $(row.HEIGHT_N)<br>common name: $(row.COMMONNAME)"
        draw!(fig, row.pointgeom; radius=row.CROWN_SPREAD_RADIUS, color="#71b36b", fill=true, stroke=false, fill_opacity=0.8, tooltip=tt)
    end
    draw!(fig, buildings.geometry)
    
    draw!(fig, g_bike_clifton, :shadowgeom)
    
    draw!(fig, g_bike_clifton, :vertices)
    draw!(fig, g_bike_clifton, :edges)
    write("2_full_map.html", repr("text/html", fig))
end