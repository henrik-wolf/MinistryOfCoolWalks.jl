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
using ProgressBars

using SpatialIndexing
using Setfield
using Hexagons
using Chain
using DataStructures
using SparseArrays
using LinearAlgebra


# TODO: Rework CenterlineCorrection
# TODO: Rework HexagonalBins
# TODO: Rework Routing
# TODO: Rework RoutingMeasures

const EdgeGeomType = Union{ArchGDAL.IGeometry{ArchGDAL.wkbLineString},ArchGDAL.IGeometry{ArchGDAL.wkbMultiLineString}}

# fix ambiguities coming from Hexagons
import Graphs: vertices, neighbors





export add_shadow_intervals!, check_shadow_angle_integrity
include("ShadowIntersection.jl")

export correct_centerlines!
include("CenterlineCorrection.jl")

export felt_length, real_length, ShadowWeights, ShadowWeight, ShadowWeightsLight, reevaluate_distances
include("Routing.jl")

export hexagonify, hexes2polys, hexagon_histogram, hexagon_area
include("HexagonalBins.jl")

export early_stopping_dijkstra, betweenness_centralities, edges_visited
include("RoutingMeasures.jl")
end