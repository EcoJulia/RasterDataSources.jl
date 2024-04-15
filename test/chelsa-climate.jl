using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath, layers

@testset "CHELSA Climate" begin
    tmax_name = "CHELSA_tasmax_07_1981-2010_V.2.1.tif"
    @test rastername(CHELSA{Climate}, :tasmax; month=7) == tmax_name

    climate_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Climate")
    @test rasterpath(CHELSA{Climate}) == climate_path

    raster_path = joinpath(climate_path, "tasmax", tmax_name)
    @test rasterpath(CHELSA{Climate}, :tasmax; month=7) == raster_path

    @test rasterurl(CHELSA{Climate}, :pr; month=6) |> string ==
    "https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/pr/CHELSA_pr_06_1981-2010_V.2.1.tif"

    @test getraster(CHELSA{Climate}, :tasmax; month=7) == raster_path
    @test getraster(CHELSA{Climate}, [:tasmax]; month=7) == (tasmax=raster_path,)
    @test getraster(CHELSA{Climate}, (:tasmax,); month=7:7) == [(tasmax=raster_path,)]
    @test isfile(raster_path)
    @test RasterDataSources.getraster_keywords(CHELSA{Climate}) == (:month,)

    @test length(layers(CHELSA{Climate})) == 12
end
