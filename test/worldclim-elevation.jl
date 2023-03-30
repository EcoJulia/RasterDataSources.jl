using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath

@testset "WorldClim Elevation" begin
    zip_url = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1/base/wc2.1_10m_elev.zip")
    @test zipurl(WorldClim{Elevation}, :elev; res="10m") == zip_url
    @test zipname(WorldClim{Elevation}, :elev; res="10m") == "wc2.1_10m_elev.zip"

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Elevation", "wc2.1_10m_elev.tif")
    @test rasterpath(WorldClim{Elevation}, :elev; res="10m") == raster_file
    @test getraster(WorldClim{Elevation}; res="10m") == (elev=raster_file,)
    @test getraster(WorldClim{Elevation}, (:elev,); res="10m") == (elev=raster_file,)
    @test getraster(WorldClim{Elevation}, :elev; res="10m") == raster_file
    @test getraster(WorldClim{Elevation}, [:elev]; res="10m") == (elev=raster_file,)
    @test isfile(raster_file)
    @test RasterDataSources.getraster_keywords(WorldClim{Weather}) == (:res,)
end
