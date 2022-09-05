using MinistryOfCoolWalks
using Dates
using Test

@testset "SunPosition" begin
    # test date calculation for general date
    @test MinistryOfCoolWalks.date_from_2060(0, 1, 1, 2060) == 0.0
    @test MinistryOfCoolWalks.date_from_2060(13.6, 5, 9, 2022) ≈ -13631.43 atol=0.1

    # test date calculation for DateTime date
    @test MinistryOfCoolWalks.date_from_2060(DateTime(2060)) == 0.0
    @test MinistryOfCoolWalks.date_from_2060(DateTime(2022, 9, 5, 13, 36)) ≈ -13631.43 atol=0.1


    # test algorithm for global position
    alg1_test1 = MinistryOfCoolWalks.algorithm_1(0.0, deg2rad(12))
    alg1_test1_exp = (4.90698, -0.39921, -2.944716)
    alg1_test2 = MinistryOfCoolWalks.algorithm_1(-13631.43, deg2rad(12))
    alg1_test2_exp = (2.868172, 0.1186921, 0.6547033)
    for (i,j) in zip(alg1_test1, alg1_test1_exp)
        @test i ≈ j atol=1e-4
    end
    for (i,j) in zip(alg1_test2, alg1_test2_exp)
        @test i ≈ j atol=1e-4
    end

    # test algorithm for global to local position transformation
    local_transform_test1 = MinistryOfCoolWalks.get_local_sun_pos(deg2rad(55), alg1_test1[2], alg1_test1[3])
    local_transform_test1_exp = (-0.9911949, -2.806291)
    local_transform_test2 = MinistryOfCoolWalks.get_local_sun_pos(deg2rad(55), alg1_test2[2], alg1_test2[3])
    local_transform_test2_exp = (0.5808625, 0.8085391)
    for (i,j) in zip(local_transform_test1, local_transform_test1_exp)
        @test i ≈ j atol=1e-4
    end
    for (i,j) in zip(local_transform_test2, local_transform_test2_exp)
        @test i ≈ j atol=1e-4
    end

    # test the full function for non date signature
    pos1 = sunposition(7.5, 5, 9, 2022, deg2rad(12), deg2rad(55))
    @test pos1[1] > 0
    @test pos1[2] ≈ 0 atol=0.01
    @test pos1[3] > 0
    pos2 = sunposition(13+1/6, 5, 9, 2022, deg2rad(12), deg2rad(55))
    @test pos2[1] ≈ 0 atol=0.01
    @test pos2[2] < 0
    @test pos2[3] > 0
    pos3 = sunposition(18+53/60, 5, 9, 2022, deg2rad(12), deg2rad(55))
    @test pos3[1] < 0
    @test pos3[2] ≈ 0 atol=0.01
    @test pos3[3] > 0

    # test the full function for DateTime signature
    pos4 = sunposition(DateTime(2022, 9, 5, 7, 30), deg2rad(12), deg2rad(55))
    @test pos1[1] > 0
    @test pos1[2] ≈ 0 atol=0.01
    @test pos1[3] > 0
    pos5 = sunposition(DateTime(2022, 9, 5, 13, 10), deg2rad(12), deg2rad(55))
    @test pos5[1] ≈ 0 atol=0.01
    @test pos5[2] < 0
    @test pos5[3] > 0
    pos6 = sunposition(DateTime(2022, 9, 5, 18, 53), deg2rad(12), deg2rad(55))
    @test pos6[1] < 0
    @test pos6[2] ≈ 0 atol=0.01
    @test pos6[3] > 0

    # test if both options give the same result
    @test pos1 == pos4
    @test pos2 == pos5
    @test pos3 == pos6
end

@testset "ShadowProjection" begin
    @test true
end