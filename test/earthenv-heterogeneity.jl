using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, rasterurl

@testset "EarthEnv HabitatHeterogeneity" begin
    using RasterDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{HabitatHeterogeneity}, :Dissimilarity; res="1km") == "Dissimilarity_1km.tif"
    hh_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "EarthEnv", "HabitatHeterogeneity")
    @test rasterpath(EarthEnv{HabitatHeterogeneity}) == hh_path
    @test rasterpath(EarthEnv{HabitatHeterogeneity}, :Dissimilarity; res="1km") == joinpath(hh_path, "1km", "Dissimilarity_1km.tif")

    @test rasterurl(EarthEnv{HabitatHeterogeneity}, :Dissimilarity; res="1km") == 
        URI(scheme="https", host="data.earthenv.org", path="/habitat_heterogeneity/1km/Dissimilarity_01_05_1km_uint32.tif")
    raster_path = joinpath(hh_path, "25km", "Dissimilarity_25km.tif")
    @test getraster(EarthEnv{HabitatHeterogeneity}, :dissimilarity; res="25km") == raster_path
    @test getraster(EarthEnv{HabitatHeterogeneity}, (:Dissimilarity,)) == (dissimilarity=raster_path,)
    @test getraster(EarthEnv{HabitatHeterogeneity}, [:dissimilarity]) == (dissimilarity=raster_path,)
    @test isfile(raster_path)
    files = getraster(EarthEnv{HabitatHeterogeneity})
    @test all(map(isfile, files))

    @test RasterDataSources.getraster_keywords(EarthEnv{HabitatHeterogeneity}) == (:res,)
end
