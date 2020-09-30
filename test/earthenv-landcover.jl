@testset "EarthEnv LandCover" begin
    using SimpleSDMDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{LandCover}, 2, true) == "landcover_complete_2.tif"
    landcover_path = joinpath(ENV["ECODATASOURCES_PATH"], "EarthEnv/consensus_landcover")
    @test rasterpath(EarthEnv{LandCover}) == landcover_path
    @test rasterpath(EarthEnv{LandCover}, 2, true) == joinpath(landcover_path, "landcover_complete_2.tif")
    @test rasterurl(EarthEnv{LandCover}, 2, true) == 
        "https://data.earthenv.org/consensus_landcover/with_DISCover/consensus_full_class_2.tif"
    download_raster(EarthEnv{LandCover}; layer=2)
    @test isfile(joinpath(landcover_path, "landcover_partial_2.tif"))
end
