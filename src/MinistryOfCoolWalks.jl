module MinistryOfCoolWalks
    using CoolWalksUtils
    import CoolWalksUtils: project_local!, project_back!
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

    const EdgeGeomType = Union{ArchGDAL.IGeometry{ArchGDAL.wkbLineString}, ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}}
    const DEFAULT_LANE_WIDTH = 3.5

    const DEFAULT_LANES_ONEWAY = Dict(
        "tertiary" => 1,
        "residential" => 1,
        "trunk" => 3,
        "trunk_link" => 3,
        "service" => 1,
        "living_street" => 1,
        "primary" => 2,
        "secondary" => 2,
        "tertiary_link" => 1,
        "primary_link" => 2,
        "secondary_link" => 2,
        "road" => 1
    )
    #=DEFAULT_LANES = Dict(
        "motorway" => 3,
        "trunk" => 3,
        "primary" => 2,
        "secondary" => 2,
        "tertiary" => 1,
        "unclassified" => 1,
        "residential" => 1,
        "other" => 1
    )=#

    const HIGHWAYS_OFFSET = [
        "tertiary",
        "residential",
        "trunk",
        "trunk_link",
        "service",
        "living_street",
        "primary",
        "secondary",
        "tertiary_link",
        "primary_link",
        "secondary_link",
        "road"]
        
    const HIGHWAYS_NOT_OFFSET = [
        "unclassified",
        "path",
        "bridleway",
        "track",
        "pedestrian",
        "cycleway"

    ]

    include("utils.jl")

    export sunposition  # imported from CoolWalksUtils

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