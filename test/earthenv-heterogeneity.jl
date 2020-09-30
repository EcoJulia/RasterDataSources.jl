@testset "EarthEnv HabitatHeterogeneity" begin
    using SimpleSDMDataSources: rastername, rasterurl, rasterpath

    @test rastername(EarthEnv{HabitatHeterogeneity}, :cv, 1) == "cv_1km.tif"
    hh_path = joinpath(ENV["ECODATASOURCES_PATH"], "EarthEnv/habitat_heterogeneity")
    @test rasterpath(EarthEnv{HabitatHeterogeneity}) == hh_path
    @test rasterpath(EarthEnv{HabitatHeterogeneity}, :cv, 1) == joinpath(hh_path, "1km/cv_1km.tif")

    @test rasterurl(EarthEnv{HabitatHeterogeneity}, :cv, 1) == 
        "https://data.earthenv.org/habitat_heterogeneity/cv_01_05_1km_uint16.tif"
    download_raster(EarthEnv{HabitatHeterogeneity}; layer=:cv)
    @test isfile(joinpath(hh_path, "25km/cv_25km.tif"))
end
