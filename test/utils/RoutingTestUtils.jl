using MinistryOfCoolWalks: ShadowWeight

b(a) = (1 + a) / (1 - a)


function run_reeval_test_on(g)
    g_baseline = floyd_warshall_shortest_paths(g, weights(g))
    g_baseline_reeval = MinistryOfCoolWalks.reevaluate_distances(g_baseline, weights(g))
    g_baseline_reeval_slow = MinistryOfCoolWalks.reevaluate_distances_slow(g_baseline, weights(g))

    @test all(g_baseline.dists .≈ g_baseline_reeval.dists)
    @test all(g_baseline.dists .≈ g_baseline_reeval_slow.dists)
end


function run_floyd_warshall_test_on(g)
    g_baseline = floyd_warshall_shortest_paths(g, weights(g))
    g_shadow_baseline = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.0 |> b))

    @test all(g_baseline.parents == g_shadow_baseline.parents)
    @test all(g_baseline.dists .≈ felt_length.(g_shadow_baseline.dists))
    @test all(g_baseline.dists .≈ real_length.(g_shadow_baseline.dists))

    g_shadow_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, 0.8 |> b))
    g_sun_skewed = floyd_warshall_shortest_paths(g, ShadowWeights(g, -0.7 |> b))  # -0.7 gives same results on this graph for all implementations


    # check if this results in different routes
    @test !all(g_baseline.parents .== g_shadow_skewed.parents)
    @test !all(g_baseline.parents .== g_sun_skewed.parents)

    g_shadow_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_shadow_skewed, weights(g))
    g_sun_skewed_reeval = MinistryOfCoolWalks.reevaluate_distances(g_sun_skewed, weights(g))

    # check if the reevaluated routes are as long as the real length
    @test all(g_shadow_skewed_reeval.dists .≈ real_length.(g_shadow_skewed.dists))
    @test all(g_sun_skewed_reeval.dists .≈ real_length.(g_sun_skewed.dists))
end