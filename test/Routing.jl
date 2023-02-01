import MinistryOfCoolWalks: ShadowWeight

@testset "Routing.jl" begin
    @testset "creating ShadowWeight" begin
        @test ShadowWeight(0.0, 1.3, 0) isa ShadowWeight
        @test ShadowWeight(0.9, 1.3, 5.9) isa ShadowWeight
        @test ShadowWeight(-0.64, 0.0, 5.9) isa ShadowWeight
        @test ShadowWeight(0.0, Inf, Inf) isa ShadowWeight
        @test ShadowWeight(0.3, Inf, Inf) isa ShadowWeight
        @test ShadowWeight(-0.6, Inf, Inf) isa ShadowWeight


        @test_throws ErrorException ShadowWeight(4.5, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(4.5, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(4.5, Inf, Inf)
        @test_throws ErrorException ShadowWeight(-1, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(1, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(0.3, 0.0, -5.9)
        @test_throws ErrorException ShadowWeight(-0.4, -1.3, 5.9)
        @test_throws ErrorException ShadowWeight(0.3, Inf, 5.9)
        @test_throws ErrorException ShadowWeight(-0.4, 4, Inf)
    end

    @testset "zero and inf of ShadowWeight" begin
        @test zero(ShadowWeight) == ShadowWeight(0.0, 0.0, 0.0)
        @test zero(ShadowWeight(0.4, 100.3, 120)) == ShadowWeight(0.0, 0.0, 0.0)

        @test typemax(ShadowWeight) == ShadowWeight(0.0, Inf, Inf)
        @test typemax(ShadowWeight(-0.5, 19.04, 13.8)) == ShadowWeight(0.0, Inf, Inf)
    end

    @testset "real_length" begin
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, Inf)
        i2 = ShadowWeight(-0.6, Inf, Inf)

        infs = [i1, i2, infinity]
        for i in infs
            @test real_length(i) == Inf
        end

        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(-0.6, 0.0, 0.0)
        @test real_length(typezero) == 0.0
        @test real_length(z1) == 0.0
        @test real_length(z2) == 0.0

        s1 = ShadowWeight(0.5, 4.6, 10.0)
        s2 = ShadowWeight(-0.5, 2.4, 1.6)

        @test real_length(s1) == 14.6
        @test real_length(s2) == 4.0

    end

    @testset "felt_lengths" begin
        # things that should be infinity
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, Inf)
        i2 = ShadowWeight(-0.6, Inf, Inf)


        for i in [i1, i2, infinity]
            @test felt_length(i) == Inf
        end

        #things that should be zero
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(-0.6, 0.0, 0.0)
        for z in [z1, z2, typezero]
            @test felt_length(z) == 0.0
        end

        # things that should be inbetween
        s1 = ShadowWeight(0.5, 4.6, 10.0)
        s2 = ShadowWeight(-0.5, 3.0, 2.6)

        @test felt_length(s1) == 17.3
        @test felt_length(s2) == 5.8
    end

    @testset "comparison" begin
        # things that should be infinity
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, Inf)
        i2 = ShadowWeight(-0.6, Inf, Inf)

        infs = [i1, i2, infinity]
        for i in infs
            @test !(i < infinity)
            @test !(i > infinity)
            @test i <= infinity
            @test i >= infinity
            @test i == infinity
        end

        #things that should be zero
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(-0.6, 0.0, 0.0)

        typezeros = [z1, z2, typezero]
        for z in typezeros
            @test !(z < typezero)
            @test !(z > typezero)
            @test z <= typezero
            @test z >= typezero
            @test z == typezero
        end


        # things that should be larger than zero (and equivalents) and less than infinity (and their equivalents)
        s1 = ShadowWeight(0.0, 3.5, 12.0)
        s2 = ShadowWeight(0.5, 4.6, 10.0)
        s3 = ShadowWeight(-0.5, 2.4, 1.6)

        smalls = [s1, s2, s3]
        for i in infs
            for s in smalls
                @test s < i
                @test s <= i
            end
        end
        for z in typezeros
            for s in smalls
                @test z < s
                @test z <= s
            end
        end
    end

    @testset "addition" begin
        # things that should be infinity
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, Inf)
        i2 = ShadowWeight(-0.6, Inf, Inf)
        infs = [i1, i2, infinity]

        #things that should be zero
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(-0.6, 0.0, 0.0)
        typezeros = [z1, z2, typezero]

        # things that should be larger than zero (and equivalents) and less than infinity (and their equivalents)
        s1 = ShadowWeight(0.0, 3.5, 12.0)
        s2 = ShadowWeight(0.0, 1.3, 2.9)

        s3 = ShadowWeight(0.5, 0.5, 1.3)
        s4 = ShadowWeight(0.5, 4.6, 10.0)

        s5 = ShadowWeight(-0.5, 2.4, 1.6)
        s6 = ShadowWeight(-0.5, 2.1, 0.3)

        smalls = [s1, s2, s3, s4, s5, s6]

        # adding zeros
        for s in smalls, z in typezeros
            @test s + z == s
            @test real_length(s + z) == real_length(s)
        end
        for s in smalls, i in infs
            @test s + i == i
            @test s + i == infinity
            @test real_length(s + i) == real_length(i)
        end

        # adding finite
        @test s1 + s2 == ShadowWeight(0.0, 4.8, 14.9)
        @test s3 + s4 == ShadowWeight(0.5, 5.1, 11.3)
        @test s5 + s6 == ShadowWeight(-0.5, 4.5, 1.9)
        @test_throws AssertionError s1 + s3
    end

    @testset "ShadowWeights" begin
        g = MetaDiGraph(random_regular_digraph(100, 4))
        @test ShadowWeights(0.4, weights(g), weights(g)) isa ShadowWeights
        @test ShadowWeights(g, -0.6) isa ShadowWeights
        @test_throws ErrorException ShadowWeights(1.0, weights(g), weights(g))
        @test_throws ErrorException ShadowWeights(g, -1.0)
        @test_throws ErrorException ShadowWeights(2.0, weights(g), weights(g))
        @test_throws ErrorException ShadowWeights(g, -3)

        @test size(ShadowWeights(g, 0.4)) == (100, 100)

        a = weights(g)
        defaultweight!(g, 0.3)
        b = weights(g)
        w1 = ShadowWeights(0.5, a, b)
        @test w1[4, 6] == ShadowWeight(0.5, 0.3, 0.7)
    end

    @testset "ShadowWeightsLight" begin
        g = MetaDiGraph(random_regular_digraph(100, 4))
        @test ShadowWeightsLight(0.4, weights(g), weights(g)) isa ShadowWeightsLight
        @test ShadowWeightsLight(g, -0.6) isa ShadowWeightsLight
        @test_throws ErrorException ShadowWeightsLight(1.0, weights(g), weights(g))
        @test_throws ErrorException ShadowWeightsLight(g, -1.0)
        @test_throws ErrorException ShadowWeightsLight(2.0, weights(g), weights(g))
        @test_throws ErrorException ShadowWeightsLight(g, -3)

        @test size(ShadowWeightsLight(g, 0.4)) == (100, 100)

        a = weights(g)
        defaultweight!(g, 0.3)
        b = weights(g)
        w1 = ShadowWeightsLight(0.5, a, b)
        w2 = ShadowWeights(0.5, a, b)
        @test w1[4, 6] ≈ 1.2
        @test all(w1 .≈ felt_length.(w2))
    end

    function run_reeval_test_on(g)
        g_baseline = floyd_warshall_shortest_paths(g, weights(g))
        g_baseline_reeval = reevaluate_distances(g_baseline, weights(g))
        g_baseline_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_baseline, weights(g))

        @test all(g_baseline.dists .≈ g_baseline_reeval.dists)
        @test all(g_baseline.dists .≈ g_baseline_reeval_slow.dists)

        g_light_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.0))
        g_light_shadow_baseline_reeval = reevaluate_distances(g_light_shadow_baseline, weights(g))
        g_light_shadow_baseline_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_light_shadow_baseline, weights(g))

        @test all(g_light_shadow_baseline.dists .≈ g_light_shadow_baseline_reeval.dists)
        @test all(g_light_shadow_baseline.dists .≈ g_light_shadow_baseline_reeval_slow.dists)


        g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.9))
        g_light_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.9))
        g_light_shadow_skewed_reeval = reevaluate_distances(g_light_shadow_skewed, weights(g))
        g_light_shadow_skewed_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_light_shadow_skewed, weights(g))
        @test all(real_length.(g_shadow_skewed.dists) .≈ g_light_shadow_skewed_reeval.dists)
        @test all(real_length.(g_shadow_skewed.dists) .≈ g_light_shadow_skewed_reeval_slow.dists)
        @test all(g_light_shadow_skewed_reeval.dists .≈ g_light_shadow_skewed_reeval_slow.dists)

        g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7))
        g_light_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, -0.7))
        g_light_sun_skewed_reeval = reevaluate_distances(g_light_sun_skewed, weights(g))
        g_light_sun_skewed_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_light_sun_skewed, weights(g))
        @test all(real_length.(g_sun_skewed.dists) .≈ g_light_sun_skewed_reeval.dists)
        @test all(real_length.(g_sun_skewed.dists) .≈ g_light_sun_skewed_reeval_slow.dists)
        @test all(g_light_sun_skewed_reeval.dists .≈ g_light_sun_skewed_reeval_slow.dists)
    end

    @testset "reevaluate_distances" begin
        ##### TRIANGLE GRAPH #####
        g2 = MetaGraph(3, :full_length, 0.0)
        add_edge!(g2, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g2, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g2, 3, 1, Dict(:full_length => 1.0, :shadowed_length => 0.1))
        run_reeval_test_on(g2)

        ### KARATE GRAPH WITH SOME UNREACHABLES ###
        g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
        add_vertices!(g, 3)
        for e in edges(g)
            set_prop!(g, e, :geom_length, src(e) + dst(e))
            set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
        end
        run_reeval_test_on(g)

        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)
        run_reeval_test_on(g_clifton)
    end

    function run_floyd_warshall_test_on(g)
        g_baseline = floyd_warshall_shortest_paths(g, weights(g))
        g_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.0))
        g_light_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.0))

        @test all(g_baseline.parents == g_shadow_baseline.parents)
        @test all(g_baseline.parents == g_light_shadow_baseline.parents)
        @test all(g_baseline.dists .≈ felt_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ real_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ g_light_shadow_baseline.dists)

        g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.8))
        g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.8))

        g_light_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.8))
        g_light_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, -0.8))

        # check if this results in different routes
        @test !all(g_baseline.parents .== g_shadow_skewed.parents)
        @test !all(g_baseline.parents .== g_sun_skewed.parents)
        @test !all(g_baseline.parents .== g_light_shadow_skewed.parents)
        @test !all(g_baseline.parents .== g_light_sun_skewed.parents)

        @test all(g_shadow_skewed.parents .== g_light_shadow_skewed.parents)
        @test all(g_sun_skewed.parents .== g_light_sun_skewed.parents)


        g_shadow_skewed_reeval = reevaluate_distances(g_shadow_skewed, weights(g))
        g_sun_skewed_reeval = reevaluate_distances(g_sun_skewed, weights(g))
        g_light_shadow_skewed_reeval = reevaluate_distances(g_light_shadow_skewed, weights(g))
        g_light_sun_skewed_reeval = reevaluate_distances(g_light_sun_skewed, weights(g))

        # check if the reevaluated routes are as long as the real length
        @test all(g_shadow_skewed_reeval.dists .≈ real_length.(g_shadow_skewed.dists))
        @test all(g_sun_skewed_reeval.dists .≈ real_length.(g_sun_skewed.dists))

        @test all(g_light_shadow_skewed_reeval.dists .≈ real_length.(g_shadow_skewed.dists))
        @test all(g_light_sun_skewed_reeval.dists .≈ real_length.(g_sun_skewed.dists))
    end

    @testset "Floyd Warshall" begin
        ##### TRIANGLE GRAPH #####
        g2 = MetaGraph(3, :full_length, 0.0)
        add_edge!(g2, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g2, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g2, 3, 1, Dict(:full_length => 1.0, :shadowed_length => 0.1))
        run_floyd_warshall_test_on(g2)

        ### KARATE GRAPH WITH SOME UNREACHABLES ###
        g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
        add_vertices!(g, 3)
        for e in edges(g)
            set_prop!(g, e, :geom_length, src(e) + dst(e))
            set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
        end
        run_floyd_warshall_test_on(g)

        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)
        run_floyd_warshall_test_on(g_clifton)
    end
end

#=
g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
correct_centerlines!(g_clifton, b_clifton)
s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
add_shadow_intervals!(g_clifton, s_clifton)
g_clifton_baseline = floyd_warshall_shortest_paths(g_clifton)
g_clifton_shadow_full = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 1.0))
g_clifton_sun_full = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, -1.0))
# check if this results in different routes
@test !all(g_clifton_baseline.parents .== g_clifton_shadow_full.parents)
@test !all(g_clifton_baseline.parents .== g_clifton_sun_full.parents)
g_clifton_shadow_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_shadow_full, weights(g_clifton))
g_clifton_sun_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_sun_full, weights(g_clifton))
# check if the reevaluated routes are as long as the real length
@test all(g_clifton_shadow_full_reeval.dists .≈ real_length.(g_clifton_shadow_full.dists))
@test all(g_clifton_sun_full_reeval.dists .≈ real_length.(g_clifton_sun_full.dists))


diffs = findall(!, g_clifton_sun_full_reeval.dists .≈ real_length.(g_clifton_sun_full.dists))

g_clifton_sun_full_reeval.dists[276, 1]
g_clifton_sun_full.dists[276,1] |> real_length

ws = ShadowWeights(g_clifton, -1.0)
ws[length_zero_edges]

g_clifton_sun_full.dists[276, 1]

p1 = enumerate_paths(g_clifton_sun_full, 276, 1)
MinistryOfCoolWalks.get_path_length(p1, weights(g_clifton))
MinistryOfCoolWalks.get_path_length(p1, ws)# |> real_length

for i in zip(p1[1:end-1], p1[2:end])
    if CartesianIndex(i...) in length_zero_edges
        println(i)
    end
end

length_zero_edges = findall(e -> felt_length(e) ≈ 0 && e.sun != 0, ws)
(g_clifton_sun_full_reeval.dists.-real_length.(g_clifton_sun_full.dists))[length_zero_edges]



g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
correct_centerlines!(g_clifton, b_clifton)
s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
add_shadow_intervals!(g_clifton, s_clifton)

g_clifton_shadow_full = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 1.0))
g_clifton_shadow_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_shadow_full, weights(g_clifton))

diffs = findall(!, real_length.(g_clifton_shadow_full.dists) .≈ g_clifton_shadow_full_reeval.dists)

(real_length.(g_clifton_shadow_full.dists).-g_clifton_shadow_full_reeval.dists)[diffs]

g_clifton_shadow_full.dists[diffs[1]] |> real_length
g_clifton_shadow_full_reeval.dists[diffs[1]]

p1 = enumerate_paths(g_clifton_shadow_full, diffs[1][1], diffs[1][2])
p2 = enumerate_paths(g_clifton_shadow_full_reeval, diffs[1][1], diffs[1][2])
ShadowWeights(g_clifton, 1.0)[1016, 758] |> real_length


MinistryOfCoolWalks.get_path_length(p1, weights(g_clifton))
MinistryOfCoolWalks.get_path_length(p1, ShadowWeights(g_clifton, 1.0)) |> real_length

ws = ShadowWeights(g_clifton, 1.0)

length_zero_edges = findall(e -> felt_length(e) ≈ 0 && e.shade != 0, ws)

problem_paths = [enumerate_paths(g_clifton_shadow_full, i[1], i[2]) for i in diffs]

map(problem_paths) do path
    ind = findfirst(==(1016), path)
    return path[ind+1] == 758
end |> all


[[1016, 758] in i for i in problem_paths]
=#
#=
g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
correct_centerlines!(g_clifton, b_clifton)
s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
add_shadow_intervals!(g_clifton, s_clifton)

using BenchmarkTools
using SparseArrays
@benchmark floyd_warshall_shortest_paths(g_clifton, weights(g_clifton))
@profview floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 0.0))

sw = ShadowWeights(g_clifton, 0.0) |> sparse

@benchmark floyd_warshall_shortest_paths(g_clifton, sw)
=#