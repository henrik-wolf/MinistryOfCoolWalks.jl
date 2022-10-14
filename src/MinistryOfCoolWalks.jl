module MinistryOfCoolWalks
    using Dates
    using ArchGDAL
    using GeoInterface
    using GeoDataFrames
    using DataFrames
    using ShadowGraphs
    using CompositeBuildings
    using Graphs
    using MetaGraphs
    using ProgressMeter
    using Folium

    const OSM_ref = Ref{ArchGDAL.ISpatialRef}()
    function __init__()
        # for ease of setup.
        OSM_ref[] = ArchGDAL.importEPSG(4326; order=:trad)
        nothing
    end

    include("utils.jl")

    export sunposition
    include("SunPosition.jl")

    export cast_shadow,
        add_shadow_intervals!,
        add_shadow_intervals_linear!,
        rebuild_lines
    include("ShadowCasting.jl")
end