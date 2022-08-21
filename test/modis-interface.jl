using RasterDataSources, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath, layers

@testset verbose = true "MODIS interface functions" begin
    @testset "Core interface functionality" begin
        @test rastername(
            MOD13Q1; RasterDataSources.crozon...
        ) == "48.24_-4.5_2002-02-02.tif"

        raster_file = joinpath(
            ENV["RASTERDATASOURCES_PATH"],
            "MODIS",
            "MOD13Q1",
            "250m_16_days_NDVI",
            "48.2511_-4.5146_2002-02-02.tif"
        )
        @test rasterpath(MOD13Q1, :NDVI; lat = 48.2511, lon = -4.5146, date = "2002-02-02") == raster_file
        @test getraster(MOD13Q1, :NDVI; RasterDataSources.crozon...) == raster_file
        @test getraster(MOD13Q1, (:NDVI,); RasterDataSources.crozon...) == (NDVI = raster_file,)
        @test getraster(MOD13Q1, [:NDVI]; RasterDataSources.crozon...) == (NDVI = raster_file,)
        @test isfile(raster_file)

        ## covers three different use cases :
        # - more than 10 dates
        # - MODIS{ModisProduct}
        # - integer layer
        @test length(getraster(MODIS{MOD13Q1}, 3; RasterDataSources.broceliande...)) > 10

        ## covers three use cases:
        # - iterable `date` of length > 2
        # - integer layer
        # - `date` is a 
        @test length(getraster(MOD13Q1, 3; RasterDataSources.crozon2...)) == 3
        @test layers(MOD13Q1) == Tuple(1:12)
    end
    
    @testset "date_sequence" begin
        twodates = [Date(2001, 1, 1), Date(2001, 1, 17)]
        @test RasterDataSources.date_sequence(MOD13Q1, (Date(2001,1,1), Date(2001,2,1)); RasterDataSources.broceliande...) == twodates
        @test RasterDataSources.date_sequence(MODIS{MOD09A1}, (Date(2001,1,1), Date(2001,2,1)); RasterDataSources.broceliande...) == twodates
    end
    
    @testset "Ensure metadata copy opt out" begin
        @test RasterDataSources.has_constant_metadata(MODIS{MOD13Q1}) == false
        @test RasterDataSources.has_constant_metadata(VNP09A1) == false
    end
end