using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath

@testset "WorldClim Climate" begin

    zip_url = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1/base/wc2.1_10m_wind.zip")
    @test zipurl(WorldClim{Climate}, :wind; res="10m") == zip_url
    @test zipname(WorldClim{Climate}, :wind; res="10m") == "wc2.1_10m_wind.zip"

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Climate", "wind", "wc2.1_10m_wind_01.tif")
    @test rasterpath(WorldClim{Climate}, :wind; month=1, res="10m") == raster_file
    @test getraster(WorldClim{Climate}, (:wind,); month=1, res="10m") == (wind=raster_file,)
    @test getraster(WorldClim{Climate}, :wind; month=1:1, res="10m") == [raster_file]
    @test getraster(WorldClim{Climate}, (:wind,); month=1:1, res="10m") == [(; wind=raster_file)]
    @test getraster(WorldClim{Climate}, [:wind]; month=1:1, res="10m") == [(; wind=raster_file)]
    @test isfile(raster_file)
end
