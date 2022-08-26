using RasterDataSources, Test
using DataFrames

@testset verbose = true "MODIS utility functions" begin
    @testset "Coordinate conversions" begin
        @test RasterDataSources.sin_to_ll(0,0) == (0.0, 0.0)
        @test RasterDataSources.meters_to_latlon(0, 45) == (0.0, 0.0)
        @test RasterDataSources.meters_to_latlon(111000, 0)[1] ≈ 1.0 rtol = 0.01
    end
    @testset "Low-level MODIS functions" begin
        # example request : the middle of Crozon peninsula in western France
        simple_request = RasterDataSources.modis_request(
            MOD13Q1,
            "250m_16_days_EVI",
            48.24,
            -4.5,
            1,
            1,
            "A2002033",
            "A2002033"
        )
        # look for a layer by its name
        @test RasterDataSources.modis_int(VNP21A2, :Emis_15) == 2
        # build a geotransform
        @test RasterDataSources._maybe_prepare_params(155555, 266666, 100, 142.4) == (xll = 1.4001660509018832, yll = 2.398184953639242, dx = 0.0012803223271200504, dy = 0.0012835043749800093)
        # request to MODIS and process it
        @test ncol(simple_request) == 15
        @test typeof(RasterDataSources.process_subset(MOD13Q1, simple_request)) == String
    end
end