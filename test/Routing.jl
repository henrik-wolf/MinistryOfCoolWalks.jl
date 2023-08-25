@testitem "creating ShadowWeight" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

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

@testitem "zero and inf of ShadowWeight" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

    @test zero(ShadowWeight) == ShadowWeight(1.0, 0.0, 0.0)
    @test zero(ShadowWeight(0.4 |> b, 100.3, 120)) == ShadowWeight(1.0, 0.0, 0.0)

    @test typemax(ShadowWeight) == ShadowWeight(1.0, Inf, Inf)
    @test typemax(ShadowWeight(-0.5 |> b, 19.04, 13.8)) == ShadowWeight(1.0, Inf, Inf)
end

@testitem "real_length" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

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

@testitem "felt_lengths" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

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

@testitem "comparison" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

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

@testitem "addition" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

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

@testitem "multiplication with bool" begin
    using MinistryOfCoolWalks: ShadowWeight

    @test zero(ShadowWeight) == (ShadowWeight(4.5, 104.6, 554.0) * false)
    @test zero(ShadowWeight) == (false * ShadowWeight(4.5, 104.6, 554.0))
    @test ShadowWeight(4.5, 104.6, 554.0) == (ShadowWeight(4.5, 104.6, 554.0) * true)
    @test ShadowWeight(4.5, 104.6, 554.0) == (true * ShadowWeight(4.5, 104.6, 554.0))
end

@testitem "ShadowWeights" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

    using Graphs, MetaGraphs

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


@testitem "reevaluate_distances" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

    using Graphs, MetaGraphs, ShadowGraphs, CompositeBuildings

    ##### TRIANGLE GRAPH #####
    g2 = MetaGraph(3, :full_length, 0.0)
    add_edge!(g2, 1, 2, Dict(:sg_street_length => 1.0, :sg_shadow_length => 0.9))
    add_edge!(g2, 2, 3, Dict(:sg_street_length => 1.0, :sg_shadow_length => 0.5))
    add_edge!(g2, 3, 1, Dict(:sg_street_length => 1.0, :sg_shadow_length => 0.1))
    run_reeval_test_on(g2)

    ### KARATE GRAPH WITH SOME UNREACHABLES ###
    g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
    add_vertices!(g, 3)
    for e in edges(g)
        set_prop!(g, e, :geom_length, src(e) + dst(e))
        set_prop!(g, e, :sg_shadow_length, abs(src(e) - dst(e)))
    end
    run_reeval_test_on(g)

    #### CLIFTON WITH SHADOWS ####
    g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
    correct_centerlines!(g_clifton, b_clifton)
    s_clifton = CompositeBuildings.cast_shadows(b_clifton, [1.0, -0.4, 0.2])
    add_shadow_intervals!(g_clifton, s_clifton)
    run_reeval_test_on(g_clifton)
end

@testitem "Floyd Warshall" begin
    cd(@__DIR__)
    include("./utils/RoutingTestUtils.jl")

    using Graphs, MetaGraphs, ShadowGraphs, CompositeBuildings

    ##### TRIANGLE GRAPH #####
    g2 = MetaGraph(3, :full_length, 0.0)
    add_edge!(g2, 1, 2, Dict(:full_length => 1.0, :sg_shadow_length => 0.9))
    add_edge!(g2, 2, 3, Dict(:full_length => 1.0, :sg_shadow_length => 0.5))
    add_edge!(g2, 3, 1, Dict(:full_length => 1.0, :sg_shadow_length => 0.1))
    run_floyd_warshall_test_on(g2)

    ### KARATE GRAPH WITH SOME UNREACHABLES ###
    g = MetaDiGraph(smallgraph(:karate), :geom_length, 0.0)
    add_vertices!(g, 3)
    for e in edges(g)
        set_prop!(g, e, :geom_length, 1 + src(e) + dst(e))
        set_prop!(g, e, :sg_shadow_length, abs(src(e) - dst(e)))
    end
    run_floyd_warshall_test_on(g)

    #### CLIFTON WITH SHADOWS ####
    g_clifton = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    b_clifton = load_british_shapefiles("./data/clifton/clifton_test.shp")
    correct_centerlines!(g_clifton, b_clifton)
    s_clifton = CompositeBuildings.cast_shadows(b_clifton, [1.0, -0.4, 0.2])
    add_shadow_intervals!(g_clifton, s_clifton)
    run_floyd_warshall_test_on(g_clifton)
end