@testset "AWAP" begin
    using RasterDataSources: rastername, rasterurl, Values, Deciles, 
          SoilMoisture, Lower, Upper, Evapotrans, Potential, Areal, Actual, RefCrop, Tall,
          DeepDrainage

    alwb_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ALWB")
    @test rasterpath(ALWB) == alwb_path
    @test rasterpath(ALWB{Values,Year}) == joinpath(alwb_path, "values/year")
    @test rastername(ALWB{Values,Year}, SoilMoisture{Lower}, Date(2001, 1)) == "ss_pct.nc"
    @test rastername(ALWB{Values,Month}, SoilMoisture{Lower}, Date(2001, 1)) == "ss_pct.nc"
    @test rastername(ALWB{Values,Day}, SoilMoisture{Lower}, Date(2001, 1)) == "ss_pct_2001.nc"
    @test rasterpath(ALWB{Values,Day}, SoilMoisture{Lower}, Date(2001, 1)) == 
        joinpath(alwb_path, "values/day/ss_pct_2001.nc")

    @test rasterurl(ALWB{Values,Year}, SoilMoisture{Lower}, Date(2001, 1)) ==
        URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS/values/year/ss_pct.nc")
    @test rasterurl(ALWB{Values,Day}, SoilMoisture{Lower}, Date(2001, 1)) ==
        URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS/values/day/ss_pct_2001.nc")

    dates = DateTime(2018, 01, 01), DateTime(2018, 03, 02)
    download_raster(ALWB{Values,Day}, SoilMoisture{Lower}; dates=dates)
    @test isfile(joinpath(alwb_path, "values/day/ss_pct_2018.nc"))
    download_raster(ALWB{Deciles,Month}, SoilMoisture{Upper}; dates=dates)
    @test isfile(joinpath(alwb_path, "deciles/month/s0_pct.nc"))

    download_raster(ALWB{Values,Day}, Evapotrans{Potential{Areal}}; dates=dates)
    @test isfile(joinpath(alwb_path, "values/day/ma_wet_2018.nc"))
    download_raster(ALWB{Values,Month}, Evapotrans{Actual}; dates=dates)
    @test isfile(joinpath(alwb_path, "values/month/etot.nc"))
    download_raster(ALWB{Values,Year}, Evapotrans{RefCrop{Tall}}; dates=dates)
    @test isfile(joinpath(alwb_path, "values/year/asce_pet.nc"))
    download_raster(ALWB{Values,Year}, DeepDrainage; dates=dates)
    @test isfile(joinpath(alwb_path, "values/year/dd.nc"))
end
