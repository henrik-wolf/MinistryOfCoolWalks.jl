module MinistryOfCoolWalks
using CoolWalksUtils
using ArchGDAL
using GeoInterface
using DataFrames
using ShadowGraphs
using CompositeBuildings
using Graphs
using MetaGraphs
using SimpleWeightedGraphs
using ProgressMeter
using SpatialIndexing
using Setfield
using Hexagons
using Chain
using DataStructures
using SparseArrays

import ShadowGraphs: EdgeGeomType

# fix ambiguities coming from Hexagons
import Graphs: vertices, neighbors


"""

    DEFAULT_LANES_ONEWAY 

default number of lanes in one direction of the street, by `highway` type. Used when there is no data available in the `tags`.
"""
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


"""

    HIGHWAYS_OFFSET

list of `highway`s, which should be offset to the edge of the street.
"""
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

"""

    HIGHWAYS_NOT_OFFSET

list of `highway`s, which should not be offset, usually because they can allready considered the center of a bikepath/sidewalk/footpath...
"""
const HIGHWAYS_NOT_OFFSET = [
    "unclassified",
    "path",
    "bridleway",
    "track",
    "pedestrian",
    "cycleway"]

export sunposition  # imported from CoolWalksUtils

export add_shadow_intervals!, check_shadow_angle_integrity, npoints
include("ShadowIntersection.jl")

export correct_centerlines!
include("CenterlineCorrection.jl")

export felt_length, real_length, ShadowWeights, ShadowWeightsLight, reevaluate_distances
include("Routing.jl")

export hexagonify, hexes2polys, hexagon_histogram
include("HexagonalBins.jl")

export early_stopping_dijkstra
include("RoutingMeasures.jl")
end