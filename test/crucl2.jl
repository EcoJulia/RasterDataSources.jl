using RasterDataSources, URIs, Test
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "CRUCL2" begin
    crucl2_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CRUCL2", "cru_cl2.nc")
    @test rasterpath(CRUCL2) == crucl2_path
    @test rastername(CRUCL2) == "cru_cl2.nc"
    @test rasterurl(CRUCL2) == URI(scheme="https", host="zenodo.org",
        path="/records/20754689/files/cru_cl2.nc")
    @test RasterDataSources.getraster_keywords(CRUCL2) == ()

    if !Sys.iswindows()
        @test getraster(CRUCL2) == crucl2_path
        @test isfile(crucl2_path)
    end
end
