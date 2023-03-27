using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "ALWB" begin

    alwb_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ALWB")
    @test rasterpath(ALWB) == alwb_path
    @test rasterpath(ALWB{Values,Year}) == joinpath(alwb_path, "values", "year")
    @test rastername(ALWB{Values,Year}, :ss_pct; date=Date(2001, 1)) == "ss_pct.nc"
    @test rastername(ALWB{Values,Month}, :ss_pct; date=Date(2001, 1)) == "ss_pct.nc"
    @test rastername(ALWB{Values,Day}, :ss_pct; date=Date(2001, 1)) == "ss_pct_2001.nc"
    @test rasterpath(ALWB{Values,Day}, :ss_pct; date=Date(2001, 1)) == 
        joinpath(alwb_path, "values", "day", "ss_pct_2001.nc")

    @test rasterurl(ALWB{Values,Year}, :ss_pct; date=Date(2001, 1)) ==
        URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS/values/year/ss_pct.nc")
    @test rasterurl(ALWB{Values,Day}, :ss_pct; date=Date(2001, 1)) ==
        URI(scheme="http", host="www.bom.gov.au", path="/jsp/awra/thredds/fileServer/AWRACMS/values/day/ss_pct_2001.nc")

    raster_path = joinpath(alwb_path, "values", "day", "ss_pct_2018.nc")
    @test getraster(ALWB{Values,Day}, :ss_pct; date=DateTime(2018, 01, 01)) == raster_path
    @test isfile(raster_path)
    raster_path = joinpath(alwb_path, "deciles", "month", "s0_pct.nc")
    @test getraster(ALWB{Deciles,Month}, :s0_pct; date=DateTime(2018, 01, 01)) == raster_path
    @test isfile(raster_path)

    raster_path = joinpath(alwb_path, "values", "day", "ma_wet_2018.nc")
    @test getraster(ALWB{Values,Day}, :ma_wet; date=DateTime(2018, 01, 01)) == raster_path
    @test isfile(raster_path)
    raster_path = joinpath(alwb_path, "values", "month", "etot.nc")
    @test getraster(ALWB{Values,Month}, (:etot,); date=DateTime(2018, 01, 01)) == (etot=raster_path,)
    @test isfile(raster_path)
    raster_path = joinpath(alwb_path, "values", "year", "asce_pet.nc")
    @test getraster(ALWB{Values,Year}, :asce_pet; date=[DateTime(2018, 01, 01)]) == [raster_path]
    @test isfile(raster_path)
    raster_path = joinpath(alwb_path, "values", "year", "dd.nc")
    @test getraster(ALWB{Values,Year}, [:dd]; date=DateTime(2018, 01, 01)) == (dd=raster_path,)
    @test isfile(raster_path)

    @test RasterDataSources.getraster_keywords(ALWB) == (:date,)
end
