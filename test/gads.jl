using RasterDataSources, URIs, Test
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "GADS" begin
    gads_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "GADS")
    @test rasterpath(GADS) == gads_path
    @test rastername(GADS, :optdepth) == "gads.nc"
    @test rasterpath(GADS, :optdepth) == joinpath(gads_path, "gads.nc")
    @test rasterurl(GADS, :optdepth) == URI(scheme="https", host="zenodo.org",
        path="/records/19246341/files/gads.nc")
    @test RasterDataSources.getraster_keywords(GADS) == ()
    @test RasterDataSources.layers(GADS) == (:optdepth,)

    if !Sys.iswindows()
        raster_path = joinpath(gads_path, "gads.nc")
        @test getraster(GADS, :optdepth) == raster_path
        @test isfile(raster_path)
        @test getraster(GADS) == (optdepth=raster_path,)
    end
end
