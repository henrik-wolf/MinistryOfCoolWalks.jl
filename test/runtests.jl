using TestItemRunner

@run_package_tests verbose = true

#=
using MinistryOfCoolWalks
using SpatialIndexing
using CoolWalksUtils
using ShadowGraphs
using CompositeBuildings
using ArchGDAL
using GeoInterface
using Graphs
using MetaGraphs
using DataFrames
using Test

b(a) = (1 + a) / (1 - a)

include("CenterlineCorrection.jl")
include("ShadowIntersection.jl")
include("Routing.jl")
include("HexagonalBins.jl")
include("RoutingMeasures.jl")
=#