using RasterDataSources, Proj, Test

@testset verbose = true "MODIS utility functions" begin
    @testset "Coordinate conversions" begin
        @test RasterDataSources.sinusoidal_to_latlon(0,0) == (0.0, 0.0)
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
            "A2012033",
            "A2012033"
        )
        # look for a layer by its name
        @test RasterDataSources.modis_int(VNP21A2, :Emis_15) == 2
        # `_maybe_prepare_params` converts the LL sinusoidal corner to WGS84
        # purely for the cache filename — the .asc itself keeps sinusoidal coords.
        @test RasterDataSources._maybe_prepare_params(155555, 266666, 142.4) ==
            (xll_wgs = 1.4001660509018832, yll_wgs = 2.398184953639242)
        # request to MODIS and process it
        @test length(simple_request[1]) == 1 # one (date, band)
        @test length(simple_request[2]) == 5 # 5 header params
        asc_path = RasterDataSources.process_subset(MOD13Q1, simple_request...)
        @test typeof(asc_path) == String
        # process_subset writes a `.prj` sidecar declaring MODIS sinusoidal
        # so downstream GDAL/Rasters reprojects the raw sinusoidal grid correctly.
        prj_path = replace(asc_path, r"\.asc$" => ".prj")
        @test isfile(prj_path)
        @test occursin("Sinusoidal", read(prj_path, String))
    end
end
