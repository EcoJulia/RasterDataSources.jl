using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath

@testset "WorldClim BioClim" begin
    zip_url = URI(scheme="https", host="geodata.ucdavis.edu", path="/climate/worldclim/2_1/base/wc2.1_10m_bio.zip")
    @test zipurl(WorldClim{BioClim}, 2; res="10m") == zip_url
    @test zipname(WorldClim{BioClim}, 2; res="10m") == "wc2.1_10m_bio.zip"

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "BioClim", "wc2.1_10m_bio_2.tif")
    @test rasterpath(WorldClim{BioClim}, 2; res="10m") == raster_file
    @test getraster(WorldClim{BioClim}, :bio2; res="10m") == raster_file
    @test getraster(WorldClim{BioClim}, (2,); res="10m") == (bio2=raster_file,)
    @test getraster(WorldClim{BioClim}, 2:2; res="10m") == (bio2=raster_file,)
    @test getraster(WorldClim{BioClim}, [:bio2]; res="10m") == (bio2=raster_file,)
    @test isfile(raster_file)

    @test RasterDataSources.getraster_keywords(WorldClim{BioClim}) == (:res,)
end
