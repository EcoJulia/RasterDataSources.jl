@testset "WorldClim BioClim" begin
    using RasterDataSources: rastername, zipurl, zipname, zippath

    zip_url = URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1/base/wc2.1_10m_bio.zip")
    @test zipurl(WorldClim{BioClim}, 2; res="10m") == zip_url
    @test zipname(WorldClim{BioClim}, 2; res="10m") == "wc2.1_10m_bio.zip"

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "BioClim", "wc2.1_10m_bio_2.tif")
    @test rasterpath(WorldClim{BioClim}, 2; res="10m") == raster_file
    @test getraster(WorldClim{BioClim}, 2; res="10m") == raster_file
    @test getraster(WorldClim{BioClim}, (2,), "10m") == (raster_file,)
    @test isfile(raster_file)
end
