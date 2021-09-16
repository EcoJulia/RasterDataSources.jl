@testset "EarthEnv LandCover" begin
    using RasterDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{LandCover{:DISCover}}, 2) == "consensus_full_class_2.tif"
    landcover_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "EarthEnv", "LandCover")
    @test rasterpath(EarthEnv{LandCover{:DISCover}}) == joinpath(landcover_path, "with_DISCover")
    @test rasterpath(EarthEnv{LandCover}) == joinpath(landcover_path, "without_DISCover")
    @test rasterpath(EarthEnv{LandCover{:DISCover}}, 2) == joinpath(landcover_path, "with_DISCover", "consensus_full_class_2.tif")
    @test rasterurl(EarthEnv{LandCover{:DISCover}}, 2) ==
        URI(scheme="https", host="data.earthenv.org", path="/consensus_landcover/with_DISCover/consensus_full_class_2.tif")
    without_discover_path = joinpath(landcover_path, "without_DISCover", "Consensus_reduced_class_2.tif")
    with_discover_path = joinpath(landcover_path, "with_DISCover", "consensus_full_class_2.tif")
    @test getraster(EarthEnv{LandCover{:DISCover}}, 2) == with_discover_path
    @test getraster(EarthEnv{LandCover{:DISCover}}, 2) == (EvergreenBroadleafTrees=with_discover_path)
    @test isfile(with_discover_path)
    @test getraster(EarthEnv{LandCover}, 2) == without_discover_path
    @test getraster(EarthEnv{LandCover}, (2,)) == (EvergreenBroadleafTrees=without_discover_path,)
    @test getraster(EarthEnv{LandCover}, [2]) == (EvergreenBroadleafTrees=without_discover_path,)
    @test isfile(without_discover_path)
    for layer in RasterDataSources.layers(EarthEnv{LandCover})
        getraster(EarthEnv{LandCover{:DISCover}}, layer)
    end
end
