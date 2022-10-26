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
    using SpatialIndexing

    const OSM_ref = Ref{ArchGDAL.ISpatialRef}()
    const EdgeGeomType = Union{ArchGDAL.IGeometry{ArchGDAL.wkbLineString}, ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}}
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
        add_shadow_intervals_rtree!,
        add_shadow_intervals_linear!,
        rebuild_lines
    include("ShadowCasting.jl")

    export build_rtree
    include("rtree_building.jl")

    export correct_centerlines!
    include("centerline_correction.jl")
end