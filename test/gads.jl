using RasterDataSources, URIs, Test
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "GADS" begin
    gads_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "GADS", "gads.nc")
    @test rasterpath(GADS) == gads_path
    @test rastername(GADS) == "gads.nc"
    @test rasterurl(GADS) == URI(scheme="https", host="zenodo.org",
        path="/records/19246341/files/gads.nc")
    @test RasterDataSources.getraster_keywords(GADS) == ()

    if !Sys.iswindows()
        @test getraster(GADS) == gads_path
        @test isfile(gads_path)
    end
end
