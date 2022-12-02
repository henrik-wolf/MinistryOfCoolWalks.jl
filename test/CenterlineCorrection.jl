@testset "centerline correction" begin
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
    end

    @testset "guess_offset_distance" begin
        
    end
end