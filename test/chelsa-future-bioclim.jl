@testset "CHELSEA Future BioClim" begin
    using RasterDataSources: rasterurl

    @test rastername(CHELSA{Future{BioClim}}, 5; "CCSM4", "rcp26", "2041-2060") == "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif"

    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "BioClim", "rcp26", "CCSM4", "2041-2060")
    @test rasterpath(CHELSA{Future{BioClim}}, "CCSM4", "rcp26", "2041-2060") == bioclim_path

    raster_path = joinpath(bioclim_path, "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif")

    @test getraster(CHELSA{BioClim}, 5; model=CCSM4, rcp=RCP26, date=Year(2050)) == raster_path
    @test isfile(raster_path)
end
