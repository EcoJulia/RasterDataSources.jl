
@testset "WorldClim Climate" begin
    using RasterDataSources: rastername, zipurl, zipname, zippath

    zip_url = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1/base/wc2.1_10m_wind.zip")
    @test zipurl(WorldClim{Climate}, :wind, "10m") == zip_url
    @test zipname(WorldClim{Climate}, :wind, "10m") == "wc2.1_10m_wind.zip"

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Climate", "wind", "wc2.1_10m_wind_01.tif")
    @test rasterpath(WorldClim{Climate}, :wind, "10m", 1) == raster_file
    @test download_raster(WorldClim{Climate}; layer=:wind, resolution="10m", month=1) == raster_file
    @test isfile(raster_file)
end
