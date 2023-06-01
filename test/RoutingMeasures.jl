@testset "RoutingMeasures" begin
    function early_stopping_dijkstra_typemax(g, i)
        s1 = early_stopping_dijkstra(g, i, ShadowWeights(g, 1.0))
        s2 = early_stopping_dijkstra(g, i)
        s3 = dijkstra_shortest_paths(g, i)
        @test all(s1.parents .== s2.parents)
        @test all(s2.parents .== s3.parents)
    end
    function esd_limited(g, i, limit)
        s1 = early_stopping_dijkstra(g, i, ShadowWeights(g, 1.6))
        s2 = early_stopping_dijkstra(g, i, ShadowWeights(g, 1.6), max_length=limit)
        r1 = s1.dists .<= typemax(ShadowWeight)
        r2 = s1.dists .<= limit
        @test count(r2) < count(r1)
    end

    @testset "early_stopping_dijkstra" begin
        ##### TRIANGLE GRAPH #####
        g = MetaDiGraph(3, :full_length, 0.0)
        add_edge!(g, 1, 2, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g, 2, 1, Dict(:full_length => 1.0, :shadowed_length => 0.9))
        add_edge!(g, 2, 3, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g, 3, 2, Dict(:full_length => 1.0, :shadowed_length => 0.5))
        add_edge!(g, 3, 1, Dict(:full_length => 1.5, :shadowed_length => 0.1))
        add_edge!(g, 1, 3, Dict(:full_length => 1.5, :shadowed_length => 0.1))
        foreach(i -> early_stopping_dijkstra_typemax(g, i), vertices(g))
        esd_limited(g, 1, ShadowWeight(1.6, 0.0, 1.0))

        ### KARATE GRAPH ###
        g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
        # unreachables are dropped when transforming to simpleweightedgraph add_vertices!(g, 3)
        for e in edges(g)
            set_prop!(g, e, :geom_length, 1 + src(e) + dst(e))
            set_prop!(g, e, :shadowed_length, abs(src(e) - dst(e)))
        end
        foreach(i -> early_stopping_dijkstra_typemax(g, i), [1, 9, 24, 33])
        esd_limited(g, 1, ShadowWeight(1.6, 0.0, 20.0))

        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)
        foreach(i -> early_stopping_dijkstra_typemax(g_clifton, i), [137, 753, 802, 734, 277])
        esd_limited(g_clifton, 1, ShadowWeight(1.6, 0.0, 1000.0))
    end

    @testset "to_SimpleWeightedDiGraph" begin
        # TODO: add tests for to_SimpleWeightedDiGraph
        @test_skip "add tests for to_SimpleWeightedDiGraph"

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

    @testset "betweenness_centralities" begin
        # TODO: add tests for betweenness_centralities
        @test_skip "add test for betweenness_centralities"
    end

    @testset "edges_visited" begin
        function edges_visited_correct(state, reachables)
            all_paths = enumerate_paths(state, findall(reachables))
            all_edges = map(all_paths) do path
                map((s, d) -> Edge(s, d), path[1:end-1], path[2:end])
            end
            return union(all_edges...)
        end
        #### CLIFTON WITH SHADOWS ####
        g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
        correct_centerlines!(g_clifton, b_clifton)
        s_clifton = CompositeBuildings.cast_shadow(b_clifton, :height_mean, [1.0, -0.4, 0.2])
        add_shadow_intervals!(g_clifton, s_clifton)

        lw_1 = ShadowWeights(g_clifton, 1.0)
        i = 5
        a = 1.6
        lw_a = ShadowWeights(g_clifton, a) |> collect
        ld_1 = early_stopping_dijkstra(g_clifton, i, lw_1, max_length=ShadowWeight(1.0, 0.0, 4000.0))
        large_reachables = ld_1.dists .<= ShadowWeight(1.0, 0.0, 4000.0)

        ld_a = early_stopping_dijkstra(g_clifton, i, lw_a, max_length=ShadowWeight(a, 0.0, 4000.0))
        count(ld_a.dists .<= ShadowWeight(a, 0.0, 4000))

        correct_edges = edges_visited_correct(ld_a, large_reachables)
        test_edges = edges_visited(ld_a, large_reachables)
        @test length(correct_edges) == length(test_edges)
        @test length(setdiff(correct_edges, test_edges)) == 0


        correct_edges = edges_visited_correct(ld_a, ld_a.dists .<= ShadowWeight(a, 0.0, 4000))
        test_edges = edges_visited(ld_a, ld_a.dists .<= ShadowWeight(a, 0.0, 4000))
        @test length(correct_edges) == length(test_edges)
        @test length(setdiff(correct_edges, test_edges)) == 0

        correct_edges = edges_visited_correct(ld_a, large_reachables)
        test_edges = edges_visited(ld_a, ld_a.dists .<= ShadowWeight(a, 0.0, 4000))
        @test length(correct_edges) < length(test_edges)
        @test length(setdiff(test_edges, correct_edges)) > 0
    end
end