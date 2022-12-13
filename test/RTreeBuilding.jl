@testset "rtee building" begin
    pointrect = MinistryOfCoolWalks.rect_from_geom(ArchGDAL.createpoint(1.0, 1.0))
    @test pointrect.low == (1.0, 1.0)
    @test pointrect.high == (1.0, 1.0)

    linerect = MinistryOfCoolWalks.rect_from_geom(ArchGDAL.createlinestring([0.0, 1.5, 0.6], [1.4, 3.5, 9.8]))
    @test linerect.low == (0.0, 1.4)
    @test linerect.high == (1.5, 9.8)

    polyrect = MinistryOfCoolWalks.rect_from_geom(ArchGDAL.createpolygon([0.0, 0.4, 0.2, 0.0], [0.0, 0.0, 0.6, 0.0]))
    @test polyrect.low == (0.0, 0.0)
    @test polyrect.high == (0.4, 0.6)


    function triangle(x, y, w, h)
        return ArchGDAL.createpolygon([x, x+w, x+0.3w, x], [y, y, y+h, y])
    end

    trigs = [triangle(i...) for i in zip([0,1,3,7,6], [0.2, 4.9, 5, 1], [1, 3, 5.2, 0.4, 1.0], [0.4, 7, 3.2, 1, 9.1])]
    tree = build_rtree(trigs)
    @test tree isa RTree
    @test length(collect(contained_in(tree, SpatialIndexing.Rect((0.4, 0.2), (9.3, 10.6))))) == 2
    @test length(collect(intersects_with(tree, SpatialIndexing.Rect((0.4, 0.2), (9.3, 10.6))))) == 4


    @test_throws TypeError build_rtree([ArchGDAL.createpoint(1.2, 4.5)])
    @test_throws TypeError build_rtree([ArchGDAL.createpoint(1.2, 4.5), ArchGDAL.createlinestring([0.0, 1.5, 0.6], [1.4, 3.5, 9.8])])
    @test_throws TypeError build_rtree([ArchGDAL.createlinestring([0.0, 1.5, 0.6], [1.4, 3.5, 9.8])])
end