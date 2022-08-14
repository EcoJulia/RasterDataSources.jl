using RasterDataSources, Test
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath, layers

@testset "MODIS interface functions" begin
    @test rastername(
        MOD13Q1; RasterDataSources.crozon..., date = "2002-02-02"
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
    @test layers(MOD13Q1) == Tuple(1:12)

end