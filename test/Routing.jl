import MinistryOfCoolWalks: ShadowWeight

b(a) = (1 + a) / (1 - a)

@testset "Routing.jl" begin
    @testset "creating ShadowWeight" begin
        @test ShadowWeight(b(0.0), 1.3, 0) isa ShadowWeight
        @test ShadowWeight(b(0.9), 1.3, 5.9) isa ShadowWeight
        @test ShadowWeight(b(-0.64), 0.0, 5.9) isa ShadowWeight
        @test ShadowWeight(b(0.0), Inf, Inf) isa ShadowWeight
        @test ShadowWeight(b(0.3), Inf, Inf) isa ShadowWeight
        @test ShadowWeight(b(-0.6), Inf, Inf) isa ShadowWeight


        @test_throws ErrorException ShadowWeight(4.5 |> b, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(4.5 |> b, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(4.5 |> b, Inf, Inf)
        @test_throws ErrorException ShadowWeight(-1 |> b, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(1 |> b, 1.3, 5.9)
        @test_throws ErrorException ShadowWeight(0.3 |> b, 0.0, -5.9)
        @test_throws ErrorException ShadowWeight(-0.4 |> b, -1.3, 5.9)
        @test_throws ErrorException ShadowWeight(0.3 |> b, Inf, 5.9)
        @test_throws ErrorException ShadowWeight(-0.4 |> b, 4, Inf)
    end

    @testset "zero and inf of ShadowWeight" begin
        @test zero(ShadowWeight) == ShadowWeight(1.0, 0.0, 0.0)
        @test zero(ShadowWeight(0.4 |> b, 100.3, 120)) == ShadowWeight(1.0, 0.0, 0.0)

        @test typemax(ShadowWeight) == ShadowWeight(1.0, Inf, Inf)
        @test typemax(ShadowWeight(-0.5 |> b, 19.04, 13.8)) == ShadowWeight(1.0, Inf, Inf)
    end

    @testset "real_length" begin
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5 |> b, Inf, Inf)
        i2 = ShadowWeight(-0.6 |> b, Inf, Inf)

        infs = [i1, i2, infinity]
        for i in infs
            @test real_length(i) == Inf
        end

        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5 |> b, 0.0, 0.0)
        z2 = ShadowWeight(-0.6 |> b, 0.0, 0.0)
        @test real_length(typezero) == 0.0
        @test real_length(z1) == 0.0
        @test real_length(z2) == 0.0

        s1 = ShadowWeight(0.5 |> b, 4.6, 10.0)
        s2 = ShadowWeight(-0.5 |> b, 2.4, 1.6)

        @test real_length(s1) == 14.6
        @test real_length(s2) == 4.0

    end

    @testset "felt_lengths" begin
        # things that should be infinity
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5 |> b, Inf, Inf)
        i2 = ShadowWeight(-0.6 |> b, Inf, Inf)


        for i in [i1, i2, infinity]
            @test felt_length(i) == Inf
        end

        #things that should be zero
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5 |> b, 0.0, 0.0)
        z2 = ShadowWeight(-0.6 |> b, 0.0, 0.0)
        for z in [z1, z2, typezero]
            @test felt_length(z) == 0.0
        end

        # things that should be inbetween
        s1 = ShadowWeight(0.5 |> b, 4.6, 10.0)
        s2 = ShadowWeight(-0.5 |> b, 3.0, 2.6)

        @test felt_length(s1) ≈ 34.6
        @test felt_length(s2) ≈ 2.6 / 3 + 3.0
    end

    @testset "comparison" begin
        # things that should be infinity
        infinity = typemax(ShadowWeight)
        i1 = ShadowWeight(0.5 |> b, Inf, Inf)
        i2 = ShadowWeight(-0.6 |> b, Inf, Inf)

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
        z1 = ShadowWeight(0.5 |> b, 0.0, 0.0)
        z2 = ShadowWeight(-0.6 |> b, 0.0, 0.0)

        typezeros = [z1, z2, typezero]
        for z in typezeros
            @test !(z < typezero)
            @test !(z > typezero)
            @test z <= typezero
            @test z >= typezero
            @test z == typezero
        end


        # things that should be larger than zero (and equivalents) and less than infinity (and their equivalents)
        s1 = ShadowWeight(0.0 |> b, 3.5, 12.0)
        s2 = ShadowWeight(0.5 |> b, 4.6, 10.0)
        s3 = ShadowWeight(-0.5 |> b, 2.4, 1.6)

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
        i1 = ShadowWeight(0.5 |> b, Inf, Inf)
        i2 = ShadowWeight(-0.6 |> b, Inf, Inf)
        infs = [i1, i2, infinity]

        #things that should be zero
        typezero = zero(ShadowWeight)
        z1 = ShadowWeight(0.5 |> b, 0.0, 0.0)
        z2 = ShadowWeight(-0.6 |> b, 0.0, 0.0)
        typezeros = [z1, z2, typezero]

        # things that should be larger than zero (and equivalents) and less than infinity (and their equivalents)
        s1 = ShadowWeight(0.0 |> b, 3.5, 12.0)
        s2 = ShadowWeight(0.0 |> b, 1.3, 2.9)

        s3 = ShadowWeight(0.5 |> b, 0.5, 1.3)
        s4 = ShadowWeight(0.5 |> b, 4.6, 10.0)

        s5 = ShadowWeight(-0.5 |> b, 2.4, 1.6)
        s6 = ShadowWeight(-0.5 |> b, 2.1, 0.3)

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
        @test s1 + s2 == ShadowWeight(0.0 |> b, 4.8, 14.9)
        @test s3 + s4 == ShadowWeight(0.5 |> b, 5.1, 11.3)
        @test s5 + s6 == ShadowWeight(-0.5 |> b, 4.5, 1.9)
        @test_throws AssertionError s1 + s3
    end

    @testset "ShadowWeights" begin
        g = MetaDiGraph(random_regular_digraph(100, 4))
        @test ShadowWeights(0.4 |> b, weights(g), weights(g)) isa ShadowWeights
        @test ShadowWeights(g, -0.6 |> b) isa ShadowWeights
        @test_throws ErrorException ShadowWeights(1.0 |> b, weights(g), weights(g))
        @test_throws ErrorException ShadowWeights(g, -1.0 |> b)
        @test_throws ErrorException ShadowWeights(2.0 |> b, weights(g), weights(g))
        @test_throws ErrorException ShadowWeights(g, -3 |> b)

        @test size(ShadowWeights(g, 0.4 |> b)) == (100, 100)

        base_full = weights(g)
        defaultweight!(g, 0.3)
        base_shade = weights(g)
        w1 = ShadowWeights(0.5 |> b, base_full, base_shade)
        @test w1[4, 6] == ShadowWeight(0.5 |> b, 0.3, 0.7)
    end

    @testset "ShadowWeightsLight" begin
        g = MetaDiGraph(random_regular_digraph(100, 4))
        @test ShadowWeightsLight(0.4 |> b, weights(g), weights(g)) isa ShadowWeightsLight
        @test ShadowWeightsLight(g, -0.6 |> b) isa ShadowWeightsLight
        @test_throws ErrorException ShadowWeightsLight(1.0 |> b, weights(g), weights(g))
        @test_throws ErrorException ShadowWeightsLight(g, -1.0 |> b)
        @test_throws ErrorException ShadowWeightsLight(2.0 |> b, weights(g), weights(g))
        @test_throws ErrorException ShadowWeightsLight(g, -3 |> b)

        @test size(ShadowWeightsLight(g, 0.4 |> b)) == (100, 100)

        base_full = weights(g)
        defaultweight!(g, 0.3)
        base_shade = weights(g)
        w1 = ShadowWeightsLight(0.5 |> b, base_full, base_shade)
        w2 = ShadowWeights(0.5 |> b, base_full, base_shade)
        @test w1[4, 6] ≈ 2.4
        @test all(w1 .≈ felt_length.(w2))
    end

    function run_reeval_test_on(g)
        g_baseline = floyd_warshall_shortest_paths(g, weights(g))
        g_baseline_reeval = reevaluate_distances(g_baseline, weights(g))
        g_baseline_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_baseline, weights(g))

        @test all(g_baseline.dists .≈ g_baseline_reeval.dists)
        @test all(g_baseline.dists .≈ g_baseline_reeval_slow.dists)

        g_light_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.0 |> b))
        g_light_shadow_baseline_reeval = reevaluate_distances(g_light_shadow_baseline, weights(g))
        g_light_shadow_baseline_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_light_shadow_baseline, weights(g))

        @test all(g_light_shadow_baseline.dists .≈ g_light_shadow_baseline_reeval.dists)
        @test all(g_light_shadow_baseline.dists .≈ g_light_shadow_baseline_reeval_slow.dists)


        g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.9 |> b))
        g_light_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.9 |> b))
        g_light_shadow_skewed_reeval = reevaluate_distances(g_light_shadow_skewed, weights(g))
        g_light_shadow_skewed_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_light_shadow_skewed, weights(g))
        @test all(real_length.(g_shadow_skewed.dists) .≈ g_light_shadow_skewed_reeval.dists)
        @test all(real_length.(g_shadow_skewed.dists) .≈ g_light_shadow_skewed_reeval_slow.dists)
        @test all(g_light_shadow_skewed_reeval.dists .≈ g_light_shadow_skewed_reeval_slow.dists)

        g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7 |> b))
        g_light_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, -0.7 |> b))
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
        g_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.0 |> b))
        g_light_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.0 |> b))

        @test all(g_baseline.parents == g_shadow_baseline.parents)
        @test all(g_baseline.parents == g_light_shadow_baseline.parents)
        @test all(g_baseline.dists .≈ felt_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ real_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ g_light_shadow_baseline.dists)

        g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.8 |> b))
        g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7 |> b))  # -0.7 gives same results on this graph for all implementations

        g_light_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, 0.8 |> b))
        g_light_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, -0.7 |> b))

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
            set_prop!(g, e, :geom_length, 1 + src(e) + dst(e))
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
    function run_johnson_test_on(g)
        g_floyd_warshall_baseline = floyd_warshall_shortest_paths(g, weights(g))
        g_baseline = johnson_shortest_paths(g, weights(g))
        g_shadow_baseline = johnson_shortest_paths(g, ShadowWeights(g, 0.0 |> b))

        @test all(g_baseline.parents .== g_floyd_warshall_baseline.parents)
        @test all(g_baseline.dists .≈ g_floyd_warshall_baseline.dists)

        @test all(g_baseline.parents .== g_shadow_baseline.parents)
        @test all(g_baseline.dists .≈ felt_length.(g_shadow_baseline.dists))
        @test all(g_baseline.dists .≈ real_length.(g_shadow_baseline.dists))

        gf_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.8 |> b))
        gf_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7 |> b))  # -0.7 gives same results on this graph for all implementations

        g_shadow_skewed = johnson_shortest_paths(g, ShadowWeights(g, 0.8 |> b))
        g_sun_skewed = johnson_shortest_paths(g, ShadowWeights(g, -0.7 |> b))  # -0.7 gives same results on this graph for all implementations

        # check if this results in different routes
        @test !all(g_baseline.parents .== g_shadow_skewed.parents)
        @test !all(g_baseline.parents .== g_sun_skewed.parents)

        # check if results are same as floyd warshall
        @test all(g_shadow_skewed.parents .== gf_shadow_skewed.parents)
        @test all(g_sun_skewed.parents .== gf_sun_skewed.parents)

        @test all(felt_length.(g_shadow_skewed.dists) .≈ felt_length.(gf_shadow_skewed.dists))
        @test all(felt_length.(g_sun_skewed.dists) .≈ felt_length.(gf_sun_skewed.dists))

        @test all(real_length.(g_shadow_skewed.dists) .≈ real_length.(gf_shadow_skewed.dists))
        @test all(real_length.(g_sun_skewed.dists) .≈ real_length.(gf_sun_skewed.dists))
    end

    @testset "johnson_shortest_paths" begin
        ##### TRIANGLE GRAPH #####
        g = MetaGraph(3, :full_length, 0.0)
        add_edge!(g, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g, 3, 1, Dict(:full_length => 1.0, :shadowed_length => 0.1))
        run_johnson_test_on(g)

        ### KARATE GRAPH ###
        g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
        # unreachables are dropped when transforming to simpleweightedgraph add_vertices!(g, 3)
        for e in edges(g)
            set_prop!(g, e, :geom_length, 1 + src(e) + dst(e))
            set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
        end
        run_johnson_test_on(g)

        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)
        run_johnson_test_on(g_clifton)
    end
end



#=
g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
add_vertices!(g, 3)
for e in edges(g)
    set_prop!(g, e, :geom_length, src(e) + dst(e))
    set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
end

sw = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7))
slw = floyd_warshall_shortest_paths(g, ShadowWeightsLight(g, -0.7))

slw_re = reevaluate_distances(slw, weights(g))
slw_re_s = MinistryOfCoolWalks.reevaluate_distances_slow(slw, weights(g))

all(real_length.(sw.dists) .≈ slw_re.dists)
real_length.(sw.dists)[diffs]
slw_re.dists[diffs]
slw.dists[diffs]
diffs = findall(!, real_length.(sw.dists) .≈ slw_re.dists)

p = enumerate_paths(slw_re, 26, 1)
l = 0
for i in zip(p[1:end-1], p[2:end])
    pr = props(g, i...)
    println(pr)
    l += pr[:geom_length]
    @show l
end
MinistryOfCoolWalks.get_path_length(p, weights(g))

all(real_length.(sw.dists) .≈ slw_re_s.dists)

dp = dijkstra_shortest_paths(g, 26, ShadowWeights(g, -0.8), allpaths=true)
dp.dists[1] |> felt_length
sw.dists[26, 1] |> felt_length
fieldnames(typeof(dp))
enumerate_paths(dp, 1)
dp.pathcounts

enumerate_paths(dp, 1, all_paths=true)
=#