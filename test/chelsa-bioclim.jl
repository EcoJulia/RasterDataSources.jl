using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, rasterurl

@testset "CHELSEA BioClim" begin
    @test rastername(CHELSA{BioClim}, 5) == "CHELSA_bio10_05.tif"

    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "BioClim")
    @test rasterpath(CHELSA{BioClim}) == bioclim_path
    @test rasterpath(CHELSA{BioClim}, 5) == joinpath(bioclim_path, "CHELSA_bio10_05.tif")

    @test rasterurl(CHELSA) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/")
    @test rasterurl(CHELSA{BioClim}, 5) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/climatologies/bio/CHELSA_bio10_05.tif")

    raster_path = joinpath(bioclim_path, "CHELSA_bio10_05.tif")
    @test getraster(CHELSA{BioClim}, :bio5) == raster_path
    @test getraster(CHELSA{BioClim}, (5,)) == (bio5=raster_path,)
    @test getraster(CHELSA{BioClim}, 5:5) == (bio5=raster_path,)
    @test getraster(CHELSA{BioClim}, [:bio5]) == (bio5=raster_path,)
    @test isfile(raster_path)

    @test RasterDataSources.getraster_keywords(CHELSA{BioClim}) == ()
end
