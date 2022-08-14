using RasterDataSources, Test

@testset verbose = true "MODIS product information functions" begin
    # product name
    @test RasterDataSources.product(VNP09A1) == "VNP09A1"
    # layers list
    @test RasterDataSources.list_layers(SIF005) == ["EVI_Quality", "SIF_740_daily_corr", "SIF_740_daily_corr_SD"]
    # dates list (2 modis dates 16 days apart), in two formats
    @test length(RasterDataSources.list_dates(MOD13Q1; lat = 48.25, lon = -4.5, from = "2002-02-02", to = "2002-02-18", format = "ModisDate")) == 2
    @test string(RasterDataSources.list_dates(MOD13Q1; lat = 48.25, lon = -4.5, from = "2002-02-02", to = "2002-02-18")[1]) == "2002-02-02"
end