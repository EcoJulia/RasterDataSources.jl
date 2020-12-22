@testset "EarthEnv HabitatHeterogeneity" begin
    using RasterDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{HabitatHeterogeneity}, :cv; res="1km") == "cv_1km.tif"
    hh_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "EarthEnv", "habitat_heterogeneity")
    @test rasterpath(EarthEnv{HabitatHeterogeneity}) == hh_path
    @test rasterpath(EarthEnv{HabitatHeterogeneity}, :cv; res="1km") == joinpath(hh_path, "1km", "cv_1km.tif")

    @test rasterurl(EarthEnv{HabitatHeterogeneity}, :cv; res="1km") == 
        URI(scheme="https", host="data.earthenv.org", path="/habitat_heterogeneity/1km/cv_01_05_1km_uint16.tif")
    getraster(EarthEnv{HabitatHeterogeneity}, :cv)
    @test isfile(joinpath(hh_path, "25km", "cv_25km.tif"))
end
