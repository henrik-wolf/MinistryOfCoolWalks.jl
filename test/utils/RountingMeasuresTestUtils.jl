using MinistryOfCoolWalks: ShadowWeight

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