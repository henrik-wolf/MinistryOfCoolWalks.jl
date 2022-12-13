@testset "shadow intersection" begin
    @testset "combine_lines" begin
        
    end

    @testset "combine_along_tree" begin
        
    end

    @testset "rebuild_lines" begin
        
    end

    @testset "get_length_by_buffering" begin
        
    end

    @testset "add_shadow_intervals!" begin
        g = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b = load_british_shapefiles("./data/clifton/clifton_test.shp")
        s = CompositeBuildings.cast_shadow(b, :height_mean, [1.0, -0.4, 0.2])

        edge_list = filter(e->!get_prop(g, e, :helper), edges(g) |> collect)
        for i in [1478, 138, 2935, 2196, 456]
            @test !has_prop(g, edge_list[i], :shadowed_length)
            @test !has_prop(g, edge_list[i], :shadowgeom)
        end

        add_shadow_intervals!(g, s)
        edge_ids = [2774, 1192, 1743, 1608, 2612, 1076, 261, 2565, 338, 2766] 
        sl_before = []
        for i in edge_ids
            @test has_prop(g, edge_list[i], :shadowed_length)
            push!(sl_before, get_prop(g, edge_list[i], :shadowed_length))
            if has_prop(g, edge_list[i], :shadowgeom)
                @test get_prop(g, edge_list[i], :shadowed_length) > 0.0
                @test ArchGDAL.distance(get_prop(g, edge_list[i], :shadowgeom), get_prop(g, edge_list[i], :edgegeom)) ≈ 0.0 atol=1e-8
            else
                @test get_prop(g, edge_list[i], :shadowed_length) == 0.0
            end
        end

        add_shadow_intervals!(g, s)

        for (i, sl) in zip(edge_ids, sl_before)
            @test get_prop(g, edge_list[i], :shadowed_length) ≈ sl atol=1e-8
        end
    end
end