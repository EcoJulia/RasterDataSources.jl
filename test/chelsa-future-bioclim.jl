@testset "CHELSA Future BioClim" begin
    using RasterDataSources: rasterurl

    @test rastername(CHELSA{BioClim}, FutureClimate{CCSM4,RCP26}, 5, Year(2050)) == "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif"

    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "BioClim", "rcp26", "CCSM4")
    @test rasterpath(CHELSA{BioClim}, FutureClimate{CCSM4,RCP26}) == bioclim_path

    raster_path = joinpath(bioclim_path, "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif")

    @test getraster(CHELSA{BioClim}, FutureClimate{CCSM4,RCP26}, 5) == raster_path
    @test isfile(raster_path)
end
