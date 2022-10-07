module MinistryOfCoolWalks
    using Dates
    using ArchGDAL
    using GeoInterface
    using GeoDataFrames
    using DataFrames
    using PyCall
    using ShadowGraphs
    using CompositeBuildings
    using Graphs
    using MetaGraphs
    using ProgressMeter

    const flm = PyNULL()
    const OSM_ref = Ref{ArchGDAL.ISpatialRef}()
    function __init__()
        # weird stuff with importing at runtime. Might switch to pyimport_conda("folium", "folium")
        # for ease of setup.
        copy!(flm, pyimport("folium"))
        OSM_ref[] = ArchGDAL.importEPSG(4326; order=:trad)
        nothing
    end

    include("utils.jl")

    export sunposition
    include("SunPosition.jl")

    export cast_shadow
    include("ShadowCasting.jl")

    export FoliumMap,
        circles, circles!,
        circleMarkers, circleMarkers!,
        polygons, polygons!,
        polylines, polylines!,
        fit_bounds!,
        graph_node_circles, graph_node_circles!,
        graph_node_circleMarkers, graph_node_circleMarkers!,
        graph_edges, graph_edges!,
        graph_edge_geometries, graph_edge_geometries!
    include("plotting.jl")

end