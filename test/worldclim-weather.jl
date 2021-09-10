@testset "WorldClim Weather" begin

    using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Weather", "prec", "wc2.1_2.5m_prec_2001-01.tif")
    @test rasterpath(WorldClim{Weather}, :prec; date=Date(2001, 1)) == raster_file
    @test rastername(WorldClim{Weather}, :prec; date=Date(2001, 1)) == "wc2.1_2.5m_prec_2001-01.tif"

    zip_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Weather", "zips", "wc2.1_2.5m_prec_2010-2018.zip")
    @test zippath(WorldClim{Weather}, :prec; decade=Date(2010)) == zip_file
    @test zipurl(WorldClim{Weather}, :prec; decade=Date(2010)) == 
        URI(scheme="https", host="biogeo.ucdavis.edu", path="/data/worldclim/v2.1/hist/wc2.1_2.5m_prec_2010-2018.zip")
    @test zipname(WorldClim{Weather}, :prec; decade=Date(2010)) == 
        "wc2.1_2.5m_prec_2010-2018.zip"

    # These files are 3GB each. Too big to test in CI.
    if !haskey(ENV, "CI")
        @test getraster(WorldClim{Weather}, :prec; date=Date(2001, 1)) == raster_file
        @test getraster(WorldClim{Weather}, (:prec,); date=Date(2001, 1)) == (prec=raster_file,)
        raster_files = [joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Weather", "prec", "wc2.1_2.5m_prec_2001-$(lpad(string(x), 2, '0')).tif") for x in 1:12]
        @test getraster(WorldClim{Weather}, :prec; date=Date(2001):Month(1):Date(2001, 12)) == raster_files
        @test getraster(WorldClim{Weather}, (:prec,); date=Date(2001):Month(1):Date(2001, 12)) == map(f -> (prec=f,), raster_files)
    end
end
