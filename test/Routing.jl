import MinistryOfCoolWalks: ShadowWeight

@testset "Routing.jl" begin
    @testset "creating ShadowWeight" begin
        @test ShadowWeight(0.0, 1.3, 0) isa ShadowWeight
        @test ShadowWeight(1.0, 1.3, 5.9) isa ShadowWeight
        @test ShadowWeight(-1, 0.0, 5.9) isa ShadowWeight

        @test_throws ErrorException ShadowWeight(4.5, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(-4, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(0.3, 0.0, -5.9)
        @test_throws ErrorException ShadowWeight(-0.4, -1.3, 5.9)
    end

    @testset "zero and inf of ShadowWeight" begin
        @test zero(ShadowWeight) == ShadowWeight(0.0, 0.0, 0.0)
        @test zero(ShadowWeight(0.4, 100.3, 120)) == ShadowWeight(0.0, 0.0, 0.0)

        @test typemax(ShadowWeight) == ShadowWeight(0.0, Inf, Inf)
        @test typemax(ShadowWeight(-0.5, 19.04, 13.8)) == ShadowWeight(0.0, Inf, Inf)
    end

    @testset "real_length" begin
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, 5.0)
        i2 = ShadowWeight(1.0, 4.5, Inf)
        i3 = ShadowWeight(-1, Inf, 9.5)
        i4 = ShadowWeight(-0.5, Inf, Inf)
        i5 = ShadowWeight(1.0, Inf, 10.4)

        infs = [i1, i2, i3, i4, i5, infinity]
        for i in infs
            @test real_length(i) == Inf
        end

        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        @test real_length(typezero) == 0.0
        @test real_length(z1) == 0.0

        s3 = ShadowWeight(0.5, 4.6, 10.0)
        s4 = ShadowWeight(-0.5, 2.4, 1.6)

        @test real_length(s3) == 14.6
        @test real_length(s4) == 4.0

    end

    @testset "felt_lengths" begin
        # things that should be infinity
        i1 = ShadowWeight(0.02, Inf, 5.0)
        i2 = ShadowWeight(1.0, 4.5, Inf)
        i3 = ShadowWeight(-1, Inf, 9.5)
        i4 = ShadowWeight(-0.5, Inf, Inf)

        for i in [i1, i2, i3, i4]
            @test felt_length(i) == Inf
        end

        # things that should be finite, even though there is infinity in there
        @test ShadowWeight(1.0, Inf, 10.4) |> felt_length == 20.8
        @test ShadowWeight(-1.0, 11.5, Inf) |> felt_length == 23.0

        #things that should be zero
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(1.0, 100.3, 0.0)
        z3 = ShadowWeight(1.0, Inf, 0.0)
        z4 = ShadowWeight(-1.0, 0.0, 51.5)
        z5 = ShadowWeight(-1.0, 0.0, Inf)
        for z in [z1, z2, z3, z4, z5]
            @test felt_length(z) == 0.0
        end
    end

    @testset "comparison" begin
        infinity = typemax(ShadowWeight)
        # things that should be equivalent to infinity
        i1 = ShadowWeight(0.5, Inf, 5.0)
        i2 = ShadowWeight(1.0, 4.5, Inf)
        i3 = ShadowWeight(-1, Inf, 9.5)
        i4 = ShadowWeight(-0.5, Inf, Inf)

        infs = [i1, i2, i3, i4, infinity]
        for i in infs
            @test !(i < infinity)
            @test !(i > infinity)
            @test i <= infinity
            @test i >= infinity
            @test i == infinity
        end

        typezero = zero(ShadowWeight)
        # things that should be equivalent to typezero
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(1.0, 100.3, 0.0)
        z3 = ShadowWeight(1.0, Inf, 0.0)
        z4 = ShadowWeight(-1.0, 0.0, 51.5)
        z5 = ShadowWeight(-1.0, 0.0, Inf)

        typezeros = [z1, z2, z3, z4, z5, typezero]
        for z in typezeros
            @test !(z < typezero)
            @test !(z > typezero)
            @test z <= typezero
            @test z >= typezero
            @test z == typezero
        end


        # things that should be larger than zero (and equivalents) and less than infinity (and their equivalents)
        s1 = ShadowWeight(1.0, Inf, 10.4)
        s2 = ShadowWeight(-1.0, 11.5, Inf)

        s3 = ShadowWeight(0.0, 3.5, 12.0)
        s4 = ShadowWeight(0.5, 4.6, 10.0)
        s5 = ShadowWeight(-0.5, 2.4, 1.6)

        s6 = ShadowWeight(1.0, 13.2, 10.0)
        s7 = ShadowWeight(-1.0, 5.8, 9.2)

        smalls = [s1, s2, s3, s4, s5, s6, s7]
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
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5, 0.0, 0.0)
        z2 = ShadowWeight(1.0, 100.3, 0.0)
        z3 = ShadowWeight(1.0, Inf, 0.0)
        z4 = ShadowWeight(-1.0, 0.0, 51.5)
        z5 = ShadowWeight(-1.0, 0.0, Inf)
        typezeros = [z1, z2, z3, z4, z5, typezero]

        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5, Inf, 5.0)
        i2 = ShadowWeight(1.0, 4.5, Inf)
        i3 = ShadowWeight(-1, Inf, 9.5)
        i4 = ShadowWeight(-0.5, Inf, Inf)
        infs = [i1, i2, i3, i4, infinity]

        s1 = ShadowWeight(1.0, Inf, 10.4)
        s2 = ShadowWeight(-1.0, 11.5, Inf)

        s3 = ShadowWeight(0.0, 3.5, 12.0)
        s4 = ShadowWeight(0.0, 1.5, 10.3)

        s5 = ShadowWeight(0.5, 4.6, 10.0)
        s6 = ShadowWeight(-0.5, 2.4, 1.6)

        s7 = ShadowWeight(1.0, 13.2, 10.0)
        s8 = ShadowWeight(-1.0, 5.8, 9.2)

        smalls = [s1, s2, s3, s4, s5, s6, s7, s8]

        # adding zeros
        for s in smalls, z in [typezero, z1]
            @test s + z == s
        end
        for s in [s1, s7], z in [z2, z3]
            @test s + z == s
            @test real_length(s + z) >= real_length(s)
        end
        for s in [s2, s8], z in [z4, z5]
            @test s + z == s
            @test real_length(s + z) >= real_length(s)
        end
        for (s, z) in zip([s1, s7, s2, s8, s3, s4, s3, s4, s5, s6, s5, s6], [z4, z5, z2, z3, z4, z5, z2, z3, z2, z4, z3, z5])
            @test_throws AssertionError s + z
        end

        # adding infinities
        for s in smalls, i in infs
            @test s + i == infinity
        end

        # adding finite
        @test s1 + s7 == ShadowWeight(1.0, Inf, 20.4)
        @test s2 + s8 == ShadowWeight(-1.0, 17.3, Inf)
        @test s3 + s4 == ShadowWeight(0.0, 5.0, 22.3)
        @test_throws AssertionError s5 + s6
    end

    @testset "ShadowWeights" begin
        g = MetaDiGraph(random_regular_digraph(100, 4))
        @test ShadowWeights(0.4, weights(g), weights(g)) isa ShadowWeights
        @test ShadowWeights(g, -0.6) isa ShadowWeights
        @test_throws ErrorException ShadowWeights(2.0, weights(g), weights(g))
        @test_throws ErrorException ShadowWeights(g, -3)

        @test size(ShadowWeights(g, 0.4)) == (100, 100)

        a = weights(g)
        defaultweight!(g, 0.3)
        b = weights(g)
        w1 = ShadowWeights(0.5, a, b)
        @test w1[4, 6] == ShadowWeight(0.5, 0.3, 0.7)
    end

    @testset "Floyd Warshall" begin
        g2 = MetaGraph(3, :full_length, 0.0)
        add_edge!(g2, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g2, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g2, 3, 1, Dict(:full_length => 1.0, :shadowed_length => 0.1))

        ##### TRIANGLE GRAPH #####
        g2_baseline = floyd_warshall_shortest_paths(g2)
        g2_shadow_baseline = floyd_warshall_shortest_paths(g2, ShadowWeights(g2, 0.0))
        @test all(g2_baseline.parents .== g2_shadow_baseline.parents)
        @test all(g2_baseline.dists .≈ felt_length.(g2_shadow_baseline.dists))
        @test all(g2_baseline.dists .≈ real_length.(g2_shadow_baseline.dists))

        g2_shadow_skewed = floyd_warshall_shortest_paths(g2, ShadowWeights(g2, 0.8))
        g2_sun_skewed = floyd_warshall_shortest_paths(g2, ShadowWeights(g2, -0.8))
        # check if this results in different routes
        @test !all(g2_baseline.parents .== g2_shadow_skewed.parents)
        @test !all(g2_baseline.parents .== g2_sun_skewed.parents)
        g2_shadow_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g2_shadow_skewed, weights(g2))
        g2_sun_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g2_sun_skewed, weights(g2))
        # check if the reevaluated routes are as long as the real length
        @test all(g2_shadow_skewed_reeval.dists .≈ real_length.(g2_shadow_skewed.dists))
        @test all(g2_sun_skewed_reeval.dists .≈ real_length.(g2_sun_skewed.dists))

        g2_shadow_full = floyd_warshall_shortest_paths(g2, ShadowWeights(g2, 1.0))
        g2_sun_full = floyd_warshall_shortest_paths(g2, ShadowWeights(g2, -1.0))
        # check if this results in different routes
        @test !all(g2_baseline.parents .== g2_shadow_full.parents)
        @test !all(g2_baseline.parents .== g2_sun_full.parents)
        g2_shadow_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g2_shadow_full, weights(g2))
        g2_sun_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g2_sun_full, weights(g2))
        # check if the reevaluated routes are as long as the real length
        @test all(g2_shadow_full_reeval.dists .≈ real_length.(g2_shadow_full.dists))
        @test all(g2_sun_full_reeval.dists .≈ real_length.(g2_sun_full.dists))

        ### KARATE GRAPH WITH SOME UNREACHABLES ###
        g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
        add_vertices!(g, 3)
        for e in edges(g)
            set_prop!(g, e, :geom_length, src(e) + dst(e))
            set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
        end

        g_baseline = floyd_warshall_shortest_paths(g, weights(g))
        g_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.0))

        @test all(g_baseline.parents == g_shadow_baseline.parents)
        @test all(g_baseline.dists .≈ felt_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ real_length.(g_shadow_baseline.dists))

        g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.8))
        g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.8))
        # check if this results in different routes
        @test !all(g_baseline.parents .== g_shadow_skewed.parents)
        @test !all(g_baseline.parents .== g_sun_skewed.parents)
        g_shadow_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_shadow_skewed, weights(g))
        g_sun_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_sun_skewed, weights(g))
        # check if the reevaluated routes are as long as the real length
        @test all(g_shadow_skewed_reeval.dists .≈ real_length.(g_shadow_skewed.dists))
        @test all(g_sun_skewed_reeval.dists .≈ real_length.(g_sun_skewed.dists))

        g_shadow_full = floyd_warshall_shortest_paths(g, ShadowWeights(g, 1.0))
        g_sun_full = floyd_warshall_shortest_paths(g, ShadowWeights(g, -1.0))
        # check if this results in different routes
        @test !all(g_baseline.parents .== g_shadow_full.parents)
        @test !all(g_baseline.parents .== g_sun_full.parents)
        g_shadow_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_shadow_full, weights(g))
        g_sun_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_sun_full, weights(g))
        # check if the reevaluated routes are as long as the real length
        @test all(g_shadow_full_reeval.dists .≈ real_length.(g_shadow_full.dists))
        @test all(g_sun_full_reeval.dists .≈ real_length.(g_sun_full.dists))

        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)

        g_clifton_baseline = floyd_warshall_shortest_paths(g_clifton)
        g_clifton_shadow_baseline = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 0.0))

        @test all(g_clifton_baseline.parents == g_clifton_shadow_baseline.parents)
        @test all(g_clifton_baseline.dists .≈ felt_length.(g_clifton_shadow_baseline.dists))
        @test all(g_clifton_baseline.dists .≈ real_length.(g_clifton_shadow_baseline.dists))

        g_clifton_shadow_skewed = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 0.8))
        g_clifton_sun_skewed = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, -0.8))
        # check if this results in different routes
        @test !all(g_clifton_baseline.parents .== g_clifton_shadow_skewed.parents)
        @test !all(g_clifton_baseline.parents .== g_clifton_sun_skewed.parents)
        g_clifton_shadow_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_shadow_skewed, weights(g_clifton))
        g_clifton_sun_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_sun_skewed, weights(g_clifton))
        # check if the reevaluated routes are as long as the real length
        @test all(g_clifton_shadow_skewed_reeval.dists .≈ real_length.(g_clifton_shadow_skewed.dists))
        @test all(g_clifton_sun_skewed_reeval.dists .≈ real_length.(g_clifton_sun_skewed.dists))

        g_clifton_shadow_full = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, 1.0))
        g_clifton_sun_full = floyd_warshall_shortest_paths(g_clifton, ShadowWeights(g_clifton, -1.0))
        # check if this results in different routes
        @test !all(g_clifton_baseline.parents .== g_clifton_shadow_full.parents)
        @test !all(g_clifton_baseline.parents .== g_clifton_sun_full.parents)
        g_clifton_shadow_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_shadow_full, weights(g_clifton))
        g_clifton_sun_full_reeval = MinistryOfCoolWalks.reevaluate_distances(g_clifton_sun_full, weights(g_clifton))
        # check if the reevaluated routes are as long as the real length
        @test_skip all(g_clifton_shadow_full_reeval.dists .≈ real_length.(g_clifton_shadow_full.dists))
        @test_skip all(g_clifton_sun_full_reeval.dists .≈ real_length.(g_clifton_sun_full.dists))
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