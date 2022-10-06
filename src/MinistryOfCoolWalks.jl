module MinistryOfCoolWalks
    using Dates
    using ArchGDAL
    using GeoInterface
    using GeoDataFrames
    using DataFrames
    using PyCall
    using ShadowGraphs
    using CompositeBuildings

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
        polylines, polylines!
    include("plotting.jl")

end