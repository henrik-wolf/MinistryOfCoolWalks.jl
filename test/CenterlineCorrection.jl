@testset "centerline correction" begin

    @testset "node_directions" begin
        println("you need to add tests for node_directions")
    end

    @testset "offset_line" begin
        line1 = ArchGDAL.createlinestring([0.0, 0.4, 1.0], [0.0, 0.6, 1.0])
        line2 = ArchGDAL.createlinestring([0.0, 0.0], [0.0, 1.0])
        line3 = ArchGDAL.createlinestring([0.0, 1.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 1.0, 0.0])
        apply_wsg_84!.([line1, line2, line3])

        #line 1
        l1p = MinistryOfCoolWalks.offset_line(line1, 0.1)
        l1n = MinistryOfCoolWalks.offset_line(line1, -0.2)
        @test ArchGDAL.geomlength(l1p) < ArchGDAL.geomlength(line1)
        @test ArchGDAL.geomlength(l1n) > ArchGDAL.geomlength(line1)
        @test ArchGDAL.distance(l1p, line1) ≈ 0.1
        @test ArchGDAL.distance(l1n, line1) ≈ 0.2

        #line 2
        l2p = MinistryOfCoolWalks.offset_line(line2, 0.5)
        l2n = MinistryOfCoolWalks.offset_line(line2, -0.4)

        p2p = [(ArchGDAL.getx(p, 0), ArchGDAL.gety(p, 0)) for p in getgeom(l2p)]
        p2n = [(ArchGDAL.getx(p, 0), ArchGDAL.gety(p, 0)) for p in getgeom(l2n)]

        @test p2p == [(0.5, 0.0), (0.5, 1.0)]
        @test p2n == [(-0.4, 0.0), (-0.4, 1.0)]
        @test ArchGDAL.geomlength(l2p) == ArchGDAL.geomlength(line2)
        @test ArchGDAL.geomlength(l2n) == ArchGDAL.geomlength(line2)
        @test ArchGDAL.distance(l2p, line2) ≈ 0.5
        @test ArchGDAL.distance(l2n, line2) ≈ 0.4

        # line 3
        l3p = MinistryOfCoolWalks.offset_line(line3, 0.2)
        l3n = MinistryOfCoolWalks.offset_line(line3, -0.1)
        p3p = [(ArchGDAL.getx(p, 0), ArchGDAL.gety(p, 0)) for p in getgeom(l3p)]
        p3n = [(ArchGDAL.getx(p, 0), ArchGDAL.gety(p, 0)) for p in getgeom(l3n)]
        
        @test p3p == [(-0.2, -0.2), (1.2, -0.2), (1.2, 1.2), (-0.2, 1.2), (-0.2, -0.2)]
        @test p3n == [(0.1, 0.1), (0.9, 0.1), (0.9, 0.9), (0.1, 0.9), (0.1, 0.1)]
        @test ArchGDAL.geomlength(l3p) > ArchGDAL.geomlength(line3)
        @test ArchGDAL.geomlength(l3n) < ArchGDAL.geomlength(line3)
        @test ArchGDAL.distance(l3p, line3) ≈ 0.2
        @test ArchGDAL.distance(l3n, line3) ≈ 0.1

        println("you need to add tests for selfintersecting offsets")
    end

    @testset "guess_offset_distance" begin
        g = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        edge_list = g |> edges |> collect

        # check if forwarding works
        for edge_id in [773, 544, 2610, 1392, 1775, 2745, 1476, 2315, 599, 266]
            edge = edge_list[edge_id]
            @test MinistryOfCoolWalks.guess_offset_distance(g, edge, 2.0) == MinistryOfCoolWalks.guess_offset_distance(get_prop(g, edge, :tags), get_prop(g, edge, :parsing_direction), 2.0)
        end

        # helper edges should not have a width
        @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(106, 1637), 2.0)
        @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(180, 1638), 2.0)
        @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(203, 1639), 2.0)


        # edges in no offset
        for edge_id in [2055, 3347, 523, 2246, 2658, 2073, 611, 3757, 1419, 1622]
            edge = edge_list[edge_id]
            @test MinistryOfCoolWalks.guess_offset_distance(g, edge, edge_id/15) == 0.0
        end

        # edges with new highway type
        for new_higway in ["crawlway", "red_carpet", "swimmlane"]
            @test MinistryOfCoolWalks.guess_offset_distance(Dict("highway"=>new_higway, "width"=>missing), 1, 2.0) == 0.0
        end

        #edges with different number of lanes in both directions
        for (edge, solution) in zip([Edge(1261, 731), Edge(788, 1198), Edge(490, 383), Edge(788, 468)], [2.0, 4.0, 4.0, 2.0])
            @test MinistryOfCoolWalks.guess_offset_distance(g, edge, 2.0) == solution
        end

        #random edges
        test_edges = [Edge(476, 697), Edge(701, 554), Edge(564, 1261), Edge(961, 1011), Edge(959, 717), Edge(676, 463), Edge(879, 1496), Edge(1363, 478), Edge(196, 534), Edge(816, 608)]
        for (edge, solution) in zip(test_edges, [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0, 2.0, 2.0, 2.0])
            @test MinistryOfCoolWalks.guess_offset_distance(g, edge, 2.0) == solution
        end
    end

    @testset "check_building_intersection" begin
        function triangle(x, y, w, h)
            return ArchGDAL.createpolygon([x, x+w, x+0.3w, x], [y, y, y+h, y])
        end
        trigs = [triangle(i...) for i in zip([0,1,3,7,6], [0.2, 4.9, 5, 1], [1, 3, 5.2, 0.4, 1.0], [0.4, 7, 3.2, 1, 9.1])]

        rtree = build_rtree(trigs)

        l1 = ArchGDAL.createlinestring([0.0, 1.0, 6.9, 4.3], [3.4, 6.9, 5.4, 1.8])
        l2 = ArchGDAL.createlinestring([0.1, 2.0, 6.3, 7.5], [-0.3, 7.6, 6.1, 0.2])
        l3 = ArchGDAL.createlinestring([0.3, 1.2, 9.8], [2.3, 14.5, 7.5])

        
        @test [i in trigs[[2,3]] for i in MinistryOfCoolWalks.check_building_intersection(rtree, l1)] |> all
        @test length(MinistryOfCoolWalks.check_building_intersection(rtree, l1)) == 2
        @test [i in trigs for i in MinistryOfCoolWalks.check_building_intersection(rtree, l2)] |> all
        @test length(MinistryOfCoolWalks.check_building_intersection(rtree, l2)) == 4
        @test MinistryOfCoolWalks.check_building_intersection(rtree, l3) == []
    end

    @testset "correct_centerlines!" begin
        g = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
        b = load_british_shapefiles("./data/clifton/clifton_test.shp")
        test_edges = [Edge(476, 697), Edge(701, 554), Edge(564, 1261), Edge(961, 1011), Edge(959, 717), Edge(676, 463), Edge(879, 1496), Edge(1363, 478), Edge(196, 534), Edge(816, 608)]
        correct_centerlines!(g, b, 2.0)
        @test true  # test that it runs...

        project_local!(g, metadata(b, "center_lon"), metadata(b, "center_lat"))
        project_local!(b.geometry, metadata(b, "center_lon"), metadata(b, "center_lat"))
        for (i, sol) in zip(test_edges, [4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0])
            reversed = Edge(dst(i), src(i))
            if has_edge(g, reversed)
                @test ArchGDAL.distance(get_prop(g, i, :edgegeom), get_prop(g, reversed, :edgegeom)) ≈ sol
            end
        end

        # different number of lanes in directions
        for (i, sol) in zip([Edge(1261, 731), Edge(788, 1198), Edge(490, 383), Edge(788, 468)], [6.0, 6.0, 6.0, 6.0])
            reversed = Edge(dst(i), src(i))
            if has_edge(g, reversed)
                @test ArchGDAL.distance(get_prop(g, i, :edgegeom), get_prop(g, reversed, :edgegeom)) ≈ sol
            end 
        end
    end
end