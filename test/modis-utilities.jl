using RasterDataSources
using DataFrames

@testset verbose = true "MODIS utility functions" begin
    @testset "Coordinate conversions" begin
        @test RasterDataSources.sin_to_ll(0,0) == (0.0, 0.0)
        @test RasterDataSources.meters_to_latlon(0, 45) == (0.0, 0.0)
        @test RasterDataSources.meters_to_latlon(111000, 0)[1] ≈ 1.0 rtol = 0.01
    end
    @testset "Low-level MODIS functions" begin
        # example request : the Crozon peninsula in western France
        simple_request = RasterDataSources.modis_request(
            MOD13Q1,
            "250m_16_days_EVI",
            48.24,
            -4.5,
            10,
            10,
            "A2002033",
            "A2002033"
        )
        # look for a layer by its name
        @test RasterDataSources.modis_int(VNP21A2, :Emis_15) == 2
        # build a geotransform
        @test round.(RasterDataSources.maybe_build_gt(155555, 266666, 100, 142.4), digits = 1) == [1.4, 0.0, 0.0, 2.5, 0.0, -0.0]
        # request to MODIS and process it
        @test ncol(simple_request) == 15
        @test typeof(RasterDataSources.process_subset(MOD13Q1, simple_request)) == String
    end
end