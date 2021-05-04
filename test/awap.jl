using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, zipurl, zipname, zippath

@testset "AWAP" begin
    using RasterDataSources: rastername, zipurl, zipname, zippath

    raster_file = joinpath(ENV["RASTERDATASOURCES_PATH"], "AWAP", "vprp", "vprph09", "20010101.grid")
    @test rasterpath(AWAP, :vprpress09; date=Date(2001, 1)) == raster_file
    @test rastername(AWAP, :vprpress09; date=Date(2001, 1)) == "20010101.grid" 

    @test zipurl(AWAP, :vprpress09; date=Date(2001, 1)) ==
        URI(scheme="http", host="www.bom.gov.au", path="/web03/ncc/www/awap/vprp/vprph09/daily/grid/0.05/history/nat/2001010120010101.grid.Z")
    @test zippath(AWAP, :vprpress09; date=Date(2001, 1)) ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "AWAP", "vprp", "vprph09", "20010101.grid.Z")
    @test zipname(AWAP, :vprpress09; date=Date(2001, 1)) == "20010101.grid.Z"

    if Sys.islinux()
        @test getraster(AWAP, :vprpress09; date=DateTime(2001, 01, 01)) == raster_file
        @test getraster(AWAP, (:vprpress09,); date=DateTime(2001, 01, 01)) == (vprpress09=raster_file,)
        @test getraster(AWAP, [:vprpress09]; date=DateTime(2001, 01, 01)) == (vprpress09=raster_file,)
        @test isfile(raster_file)
    end
end
