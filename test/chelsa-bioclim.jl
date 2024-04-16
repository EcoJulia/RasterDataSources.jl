using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterpath, rasterurl, CHELSA_warn_version

bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "BioClim")

@testset "CHELSEA BioClim" begin
    @test rasterpath(CHELSA{BioClim}) == bioclim_path
    @test rasterurl(CHELSA) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/")
    
    # version 1
    @test rastername(CHELSA{BioClim}, 5; version = 1) == "CHELSA_bio10_05.tif" # version 1
    @test rasterpath(CHELSA{BioClim}, 5; version = 1) == joinpath(bioclim_path, "CHELSA_bio10_05.tif")
    @test rasterurl(CHELSA{BioClim}, 5; version = 1) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V1/climatologies/bio/CHELSA_bio10_05.tif")
    raster_path = joinpath(bioclim_path, "CHELSA_bio10_05.tif")
    @test getraster(CHELSA{BioClim}, :bio5; version = 1) == raster_path
    @test getraster(CHELSA{BioClim}, (5,); version = 1) == (bio5=raster_path,)
    @test getraster(CHELSA{BioClim}, 5:5; version = 1) == (bio5=raster_path,)
    @test getraster(CHELSA{BioClim}, [:bio5]; version = 1) == (bio5=raster_path,)
    @test isfile(raster_path)



    # version 2 (default)
    # test if warning when downloading data for a new chelsa version works
    @test_logs (:info, ) CHELSA_warn_version(CHELSA{BioClim}, 5, 2, 1, rasterpath(CHELSA{BioClim}, 5; version = 2))

    @test rastername(CHELSA{BioClim}, 6) == "CHELSA_bio6_1981-2010_V.2.1.tif" # version 2
    @test rasterpath(CHELSA{BioClim}, 6) == joinpath(bioclim_path, "CHELSA_bio6_1981-2010_V.2.1.tif")
    @test rasterurl(CHELSA{BioClim}, 6) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_bio6_1981-2010_V.2.1.tif")
    raster_path = joinpath(bioclim_path, "CHELSA_bio6_1981-2010_V.2.1.tif")
    @test getraster(CHELSA{BioClim}, :bio6) == raster_path
    @test getraster(CHELSA{BioClim}, (6,)) == (bio6=raster_path,)
    @test getraster(CHELSA{BioClim}, 6:6) == (bio6=raster_path,)
    @test getraster(CHELSA{BioClim}, [:bio6]) == (bio6=raster_path,)
    @test isfile(raster_path)

    @test RasterDataSources.getraster_keywords(CHELSA{BioClim}) == (:version, :patch)

    # test non-valid version
    @test_throws ArgumentError rastername(CHELSA{BioClim}, 6; version = 3)
end

@testset "CHELSEA BioClimPlus" begin
    @test rastername(CHELSA{BioClimPlus}, :bio5) == rastername(CHELSA{BioClim}, 5)

    @test rasterpath(CHELSA{BioClimPlus}) == bioclim_path

    @test rasterpath(CHELSA{BioClimPlus}, :clt_mean) == joinpath(bioclim_path, "CHELSA_clt_mean_1981-2010_V.2.1.tif")

    @test rasterurl(CHELSA{BioClimPlus}, :clt_mean) == 
        URI(scheme="https", host="os.zhdk.cloud.switch.ch", path="/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_clt_mean_1981-2010_V.2.1.tif")

    raster_path = joinpath(bioclim_path, "CHELSA_clt_mean_1981-2010_V.2.1.tif")
    @test getraster(CHELSA{BioClimPlus}, :clt_mean) == raster_path
    @test getraster(CHELSA{BioClimPlus}, [:clt_mean]) == (clt_mean=raster_path,)
    @test isfile(raster_path)

    @test RasterDataSources.getraster_keywords(CHELSA{BioClimPlus}) == (:version, :patch)

    @test length(RasterDataSources.BIOCLIMPLUS_LAYERS) == 75
    @test length(RasterDataSources.BIOCLIMPLUS_LAYERS_FUTURE) == 46
end