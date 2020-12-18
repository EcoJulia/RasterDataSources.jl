@testset "EarthEnv LandCover" begin
    using RasterDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{LandCover}, 2; discover=true) == "landcover_complete_2.tif"
    landcover_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "EarthEnv", "consensus_landcover")
    @test rasterpath(EarthEnv{LandCover}) == landcover_path
    @test rasterpath(EarthEnv{LandCover}, 2; discover=true) == joinpath(landcover_path, "landcover_complete_2.tif")
    @test rasterurl(EarthEnv{LandCover}, 2; discover=true) == 
        URI(scheme="https", host="data.earthenv.org", path="/consensus_landcover/with_DISCover/consensus_full_class_2.tif")
    getraster(EarthEnv{LandCover}, 2)
    @test isfile(joinpath(landcover_path, "landcover_partial_2.tif"))
end
