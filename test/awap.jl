@testset "AWAP" begin
    using RasterDataSources: rastername, zipurl, zipname, zippath

    raster_file = joinpath(ENV["ECODATASOURCES_PATH"], "AWAP/vprp/vprph09/20010101.grid")
    @test rasterpath(AWAP, VapourPressure{H09}, Date(2001, 1)) == raster_file
    @test rastername(AWAP, VapourPressure{H09}, Date(2001, 1)) == "20010101.grid" 

    @test zipurl(AWAP, VapourPressure{H09}, Date(2001, 1)) ==
        "http://www.bom.gov.au/web03/ncc/www/awap/vprp/vprph09/daily/grid/0.05/history/nat/2001010120010101.grid.Z"
    @test zippath(AWAP, VapourPressure{H09}, Date(2001, 1)) ==
        joinpath(ENV["ECODATASOURCES_PATH"], "AWAP/vprp/vprph09/20010101.grid.Z")
    @test zipname(AWAP, VapourPressure{H09}, Date(2001, 1)) == "20010101.grid.Z"

    dates = DateTime(2001, 01, 01), DateTime(2001, 01, 02)
    download_raster(AWAP, VapourPressure{H09}; dates=dates)

    @test isfile(raster_file)
end
