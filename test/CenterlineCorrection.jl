@testitem "node_directions" begin
    # TODO: Add tests for node_directions
    @test_skip "Add tests for node_directions"
end

@testitem "offset_line" begin
    using ArchGDAL, CoolWalksUtils, GeoInterface

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

    # TODO: Add tests for offsets where neighbouring points cause self intersections
    @test_skip "Add tests for offsets where neighbouring points cause self intersections"

    # tests for lines where endpoints cause selfintersections when offset
    line_base1 = ArchGDAL.fromWKT("LINESTRING (3934.87898744502 -1709.68525248961,3913.16528299286 -1727.08895857984,3912.32179368535 -1731.47259104177,3918.55900722447 -1739.94467994297,3921.74863920827 -1740.08690153956,3924.93677426558 -1738.2378608001,3926.06400162936 -1735.83415011952,3926.63281383384 -1732.16268149945,3936.39812198756 -1721.69842298361,3937.10036007102 -1717.18140067276,3936.95678163544 -1713.93319395115)")
    line_base_offset_self_intersecting1 = ArchGDAL.fromWKT("LINESTRING (3937.06793025181 -1712.41628327959,3916.35893944606 -1729.0147034235,3916.04803452983 -1730.63048310311,3920.38589894022 -1736.5226611887,3920.87991114841 -1736.54468855883,3922.23308611933 -1735.75988001066,3922.68208972574 -1734.80242031928,3923.33900142136 -1730.56230265474,3933.1049950634 -1720.09730958525,3933.58839145662 -1716.98794775573,3933.46019590094 -1714.08775132684)")

    line_base2 = ArchGDAL.fromWKT("LINESTRING (843.906433772938 -991.375652795077,835.011739342345 -1005.33817253192,783.73474269526 -1019.88568050308,754.028997345945 -1054.05300638576,737.374069249498 -1076.70460852253,751.572185498237 -1092.74392814748,759.333884724936 -1096.51396686661,763.686719015401 -1093.3095126212,799.633370844518 -1036.8701868898,812.500105231316 -1020.63773916535,821.536387699683 -1009.16709555123)")
    line_base_offset_self_intersecting2 = ArchGDAL.fromWKT("LINESTRING (844.776307414618 -991.929797772674,835.670768067172 -1006.22329305607,784.311630372491 -1020.79410480024,754.834987265269 -1054.69791900305,738.698369360075 -1076.64459127233,752.20800035286 -1091.90614327987,759.224126389504 -1095.31403967053,762.920217760965 -1092.59306412285,798.792040372465 -1036.27122667367,811.690878002009 -1019.99827805844,820.726201682559 -1008.5288515298)")

    line_base3 = ArchGDAL.fromWKT("LINESTRING (-2397.73653827728 2292.17435134502,-2399.12636122392 2290.49520142268,-2405.51108885839 2282.78891180797,-2392.08489831 2269.66702927593,-2387.72986387939 2279.57690184107,-2394.91107919593 2287.82339972632,-2394.77603676533 2290.15946845484,-2394.24542243403 2294.05277604482)")
    line_base_offset_self_intersecting3 = ArchGDAL.fromWKT("LINESTRING (-2395.04030139756 2289.9426912422,-2396.43066332912 2288.26289013264,-2400.75906141324 2283.03856560111,-2393.25477164208 2275.70436246093,-2391.82728405669 2278.95260775076,-2398.48759068431 2286.60092381437,-2398.26235105782 2290.49729361352,-2397.71336276183 2294.52541756942)")

    lines_base = [line_base1, line_base2, line_base3]
    apply_wsg_84!.(lines_base)
    lines_self_intersecting = [line_base_offset_self_intersecting1, line_base_offset_self_intersecting2, line_base_offset_self_intersecting3]
    lines_intersection_corrected = map(i -> MinistryOfCoolWalks.offset_line(i, -3.2), lines_base)

    for i in lines_base
        @test !MinistryOfCoolWalks.is_selfintersecting(i)[1]
    end
    for i in lines_self_intersecting
        @test MinistryOfCoolWalks.is_selfintersecting(i)[1]
    end
    for i in lines_intersection_corrected
        @test !MinistryOfCoolWalks.is_selfintersecting(i)[1]
    end
end

@testitem "guess_offset_distance" begin
    using ShadowGraphs, Graphs, MetaGraphs
    cd(@__DIR__)

    g = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    edge_list = g |> edges |> collect

    # check if forwarding works
    for edge_id in [773, 544, 2610, 1392, 1775, 2745, 1476, 2315, 599, 266]
        edge = edge_list[edge_id]
        @test MinistryOfCoolWalks.guess_offset_distance(g, edge, 2.0) == MinistryOfCoolWalks.guess_offset_distance(get_prop(g, edge, :sg_tags), get_prop(g, edge, :sg_parsing_direction), 2.0)
    end

    # helper edges should not have a width
    @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(106, 1637), 2.0)
    @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(180, 1638), 2.0)
    @test_throws KeyError MinistryOfCoolWalks.guess_offset_distance(g, Edge(203, 1639), 2.0)


    # edges in no offset
    for edge_id in [2055, 3347, 523, 2246, 2658, 2073, 611, 3757, 1622]
        edge = edge_list[edge_id]
        @test MinistryOfCoolWalks.guess_offset_distance(g, edge, edge_id / 15) == 0.0
    end

    # edges with new highway type
    for new_higway in ["crawlway", "red_carpet", "swimmlane"]
        @test MinistryOfCoolWalks.guess_offset_distance(Dict("highway" => new_higway, "width" => missing), 1, 2.0) == 0.0
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

@testitem "check_building_intersection" begin
    using ArchGDAL, CoolWalksUtils

    function triangle(x, y, w, h)
        return ArchGDAL.createpolygon([x, x + w, x + 0.3w, x], [y, y, y + h, y])
    end
    trigs = [triangle(i...) for i in zip([0, 1, 3, 7, 6], [0.2, 4.9, 5, 1], [1, 3, 5.2, 0.4, 1.0], [0.4, 7, 3.2, 1, 9.1])]

    rtree = build_rtree(trigs)

    l1 = ArchGDAL.createlinestring([0.0, 1.0, 6.9, 4.3], [3.4, 6.9, 5.4, 1.8])
    l2 = ArchGDAL.createlinestring([0.1, 2.0, 6.3, 7.5], [-0.3, 7.6, 6.1, 0.2])
    l3 = ArchGDAL.createlinestring([0.3, 1.2, 9.8], [2.3, 14.5, 7.5])


    @test [i in trigs[[2, 3]] for i in MinistryOfCoolWalks.check_building_intersection(rtree, l1)] |> all
    @test length(MinistryOfCoolWalks.check_building_intersection(rtree, l1)) == 2
    @test [i in trigs for i in MinistryOfCoolWalks.check_building_intersection(rtree, l2)] |> all
    @test length(MinistryOfCoolWalks.check_building_intersection(rtree, l2)) == 4
    @test MinistryOfCoolWalks.check_building_intersection(rtree, l3) == []
end

@testitem "correct_centerlines!" begin
    using ShadowGraphs, CompositeBuildings, CoolWalksUtils, Graphs, MetaGraphs, ArchGDAL
    cd(@__DIR__)

    g = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    b = load_british_shapefiles("./data/clifton/clifton_test.shp")
    test_edges = [Edge(476, 697), Edge(701, 554), Edge(564, 1261), Edge(961, 1011), Edge(959, 717), Edge(676, 463), Edge(879, 1496), Edge(1363, 478), Edge(196, 534), Edge(816, 608)]
    correct_centerlines!(g, b, 2.0)
    @test true  # test that it runs...

    project_local!(g)
    project_local!(b, get_prop(g, :sg_observatory))
    for (i, sol) in zip(test_edges, [4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0])
        reversed = Edge(dst(i), src(i))
        if has_edge(g, reversed)
            @test ArchGDAL.distance(get_prop(g, i, :sg_street_geometry), get_prop(g, reversed, :sg_street_geometry)) ≈ sol
        end
    end

    # different number of lanes in directions
    for (i, sol) in zip([Edge(1261, 731), Edge(788, 1198), Edge(490, 383), Edge(788, 468)], [6.0, 6.0, 6.0, 6.0])
        reversed = Edge(dst(i), src(i))
        if has_edge(g, reversed)
            @test ArchGDAL.distance(get_prop(g, i, :sg_street_geometry), get_prop(g, reversed, :sg_street_geometry)) ≈ sol
        end
    end

    # check repeatability
    g1 = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    g2 = shadow_graph_from_file("./data/test_clifton_bike.json"; network_type=:bike)
    b2 = load_british_shapefiles("./data/clifton/clifton_test.shp")

    correct_centerlines!(g1, b2, 2.0)
    correct_centerlines!(g2, b2, 1.0)
    correct_centerlines!(g2, b2, 2.0)

    # test if only last application counts
    project_local!(g1, -1, 53)
    project_local!(g2, -1, 53)
    @test map(edges(g1)) do e
        prop_lengths_equal = length(props(g1, e)) == length(props(g2, e))
        if !get_prop(g1, e, :sg_helper)
            osm_id_same = get_prop(g1, e, :sg_osm_id) == get_prop(g2, e, :sg_osm_id)
            full_length_equal = get_prop(g1, e, :sg_street_length) ≈ get_prop(g2, e, :sg_street_length)

            distance_base_g1 = ArchGDAL.distance(get_prop(g1, e, :sg_street_geometry), get_prop(g1, e, :sg_geometry_base))
            distance_base_g2 = ArchGDAL.distance(get_prop(g2, e, :sg_street_geometry), get_prop(g2, e, :sg_geometry_base))
            distance_to_base_equal = isapprox(distance_base_g1, distance_base_g2, atol=1e-6)
            return osm_id_same && prop_lengths_equal && full_length_equal && distance_to_base_equal
        end
        return prop_lengths_equal
    end |> all
    project_back!(g1)
    project_back!(g2)

    s2 = CompositeBuildings.cast_shadows(b2, [1.0, -0.4, 0.2])
    add_shadow_intervals!(g2, s2)

    # check if there are edges with new props
    @test map(edges(g1)) do e
              prop_lengths_equal = length(props(g1, e)) == length(props(g2, e))
          end |> all |> !

    # repeat offsetting
    correct_centerlines!(g2, b2, 2.0)

    # test if the offsetting reset all changed fields
    project_local!(g1, -1, 53)
    project_local!(g2, -1, 53)
    @test map(edges(g1)) do e
        prop_lengths_equal = length(props(g1, e)) == length(props(g2, e))
        if !get_prop(g1, e, :sg_helper)
            osm_id_same = get_prop(g1, e, :sg_osm_id) == get_prop(g2, e, :sg_osm_id)
            full_length_equal = get_prop(g1, e, :sg_street_length) ≈ get_prop(g2, e, :sg_street_length)
            distance_base_g1 = ArchGDAL.distance(get_prop(g1, e, :sg_street_geometry), get_prop(g1, e, :sg_geometry_base))
            distance_base_g2 = ArchGDAL.distance(get_prop(g2, e, :sg_street_geometry), get_prop(g2, e, :sg_geometry_base))
            distance_to_base_equal = isapprox(distance_base_g1, distance_base_g2, atol=1e-6)
            return osm_id_same && prop_lengths_equal && full_length_equal && distance_to_base_equal
        end
        return prop_lengths_equal
    end |> all
    project_back!(g1)
    project_back!(g2)
end