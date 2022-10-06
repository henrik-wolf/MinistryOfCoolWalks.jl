@testset "circles" begin
    # just running these commands to check if they throw errors...
    circles([0.0, 4.9, 30], [0.0, 12, 70])
    circles([0.0, 4.9, 30], [0.0, 12, 70]; radius=40000)

    circles([0.0, 4.9, 30], [0.0, 12, 70]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40000)

    circles([(0.0, 0.0), (4.9, 12), (30, 70)])
    circles([(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40000)

    circles([(0.0, 0.0), (4.9, 12), (30, 70)]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40000)
    
    flmmap = FoliumMap()
    circles!(flmmap, [0.0, 4.9, 30], [0.0, 12, 70])
    circles!(flmmap, [0.0, 4.9, 30], [0.0, 12, 70]; radius=40000)

    circles!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)])
    circles!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40000)
end

@testset "circleMarkers" begin
    circleMarkers([0.0, 4.9, 30], [0.0, 12, 70])
    circleMarkers([0.0, 4.9, 30], [0.0, 12, 70]; radius=40)

    circleMarkers([0.0, 4.9, 30], [0.0, 12, 70]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40)

    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)])
    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40)

    circleMarkers([(0.0, 0.0), (4.9, 12), (30, 70)]; 
        figure_params=Dict(:location=>[30,70], :zoom_start=>6),
        radius=40)
    
    flmmap = FoliumMap()
    circleMarkers!(flmmap, [0.0, 4.9, 30], [0.0, 12, 70])
    circleMarkers!(flmmap, [0.0, 4.9, 30], [0.0, 12, 70]; radius=40)

    circleMarkers!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)])
    circleMarkers!(flmmap, [(0.0, 0.0), (4.9, 12), (30, 70)]; radius=40)
end

@testset "polygons" begin
    path = "Desktop/Masterarbeit/data/Nottingham/Nottingham.shp"
    using ShadowGraphs
    using CompositeBuildings
    using MinistryOfCoolWalks
    buildings = load_british_shapefiles(joinpath([homedir(), path]); bbox=(minlat=52.89, minlon=-1.2, maxlat=52.92, maxlon=-1.165))
    shadows = cast_shadow(buildings, :height_mean, [1.0, -0.5, 0.6])
    m = polygons(shadows.geometry; figure_params=Dict(:location=>[52.904, -1.18], :zoom_start=>14))

    
end