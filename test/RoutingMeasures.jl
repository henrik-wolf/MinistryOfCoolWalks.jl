@testset "RoutingMeasures" begin
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
        g = MetaDiGraph(3, :full_length, 0.0)
        add_edge!(g, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g, 2, 1, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g, 3, 2, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g, 3, 1, Dict(:full_length => 1.0, :shadowed_length => 0.1))
        add_edge!(g, 1, 3, Dict(:full_length => 1.0, :shadowed_length => 0.1))
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