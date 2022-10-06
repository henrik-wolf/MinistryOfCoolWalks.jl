@testset "circles" begin
    # just running these commands to check if they throw errors...
    circles([0.0, 12, 70], [0.0, 4.9, 30])
    circles([0.0, 12, 70], [0.0, 4.9, 30]; radius=40000)

    circles([0.0, 12, 70], [0.0, 4.9, 30]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40000)

    circles([(0.0, 0.0), (4.9, 12), (30, 70)])
    circles([(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40000)

    circles([(0.0, 0.0), (4.9, 12), (30, 70)]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40000)
    
    flmmap = FoliumMap()
    circles!(flmmap, [0.0, 12, 70], [0.0, 4.9, 30])
    circles!(flmmap, [0.0, 12, 70], [0.0, 4.9, 30]; radius=40000)

    circles!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)])
    circles!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40000)
end

@testset "circleMarkers" begin
    circleMarkers([0.0, 12, 70], [0.0, 4.9, 30])
    circleMarkers([0.0, 12, 70], [0.0, 4.9, 30]; radius=40)

    circleMarkers([0.0, 12, 70], [0.0, 4.9, 30]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40)

    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)])
    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40)

    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40)
    
    flmmap = FoliumMap()
    circleMarkers!(flmmap, [0.0, 12, 70], [0.0, 4.9, 30])
    circleMarkers!(flmmap, [0.0, 12, 70], [0.0, 4.9, 30]; radius=40)

    circleMarkers!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)])
    circleMarkers!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40)
end

@testset "polygons" begin
    path = "Desktop/Masterarbeit/data/Nottingham/Nottingham.shp"
    using CompositeBuildings
    using MinistryOfCoolWalks
    buildings = load_british_shapefiles(joinpath([homedir(), path]); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
    shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.6])
    m = polygons(shadows.geometry; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14))
    polygons!(m, buildings.geometry)
end

@testset "graph nodes" begin
    using ShadowGraphs
    path = "Desktop/Masterarbeit/data/Nottingham/test_nottingham.json"
    _, g = shadow_graph_from_file(joinpath([homedir(), path]))
    m = graph_node_circles(g; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14))
    graph_node_circles!(m, g; radius=4, color="#FF0000")
end

@testset "graph node markers" begin
    using ShadowGraphs
    path = "Desktop/Masterarbeit/data/Nottingham/test_nottingham.json"
    _, g = shadow_graph_from_file(joinpath([homedir(), path]))
    m = graph_node_circleMarkers(g; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14))
    graph_node_circleMarkers!(m, g; radius=4, color="#FF0000")
end

@testset "graph edges" begin
    using ShadowGraphs
    path = "Desktop/Masterarbeit/data/Nottingham/test_nottingham.json"
    _, g = shadow_graph_from_file(joinpath([homedir(), path]))
    m = graph_edges(g; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14), weight=10)
    graph_edges!(m, g; color="#FF0000")
end

@testset "graph edge geometries" begin
    using ShadowGraphs
    path = "Desktop/Masterarbeit/data/Nottingham/test_nottingham.json"
    _, g = shadow_graph_from_file(joinpath([homedir(), path]))
    m = graph_edge_geometries(g; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14), weight=10)
    graph_edge_geometries!(m, g; color="#FF0000")
end