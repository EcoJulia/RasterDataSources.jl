@testset "ALWB" begin
    using RasterDataSources: rastername, rasterurl, Values, Deciles

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

    date = DateTime(2018, 01, 01), DateTime(2018, 03, 02)
    getraster(ALWB{Values,Day}, :ss_pct; date)
    @test isfile(joinpath(alwb_path, "values", "day", "ss_pct_2018.nc"))
    getraster(ALWB{Deciles,Month}, :ss_pct; date)
    @test isfile(joinpath(alwb_path, "deciles", "month", "s0_pct.nc"))

    getraster(ALWB{Values,Day}, :ma_wet; date)
    @test isfile(joinpath(alwb_path, "values", "day", "ma_wet_2018.nc"))
    getraster(ALWB{Values,Month}, :ma_wet; date)
    @test isfile(joinpath(alwb_path, "values", "month", "etot.nc"))
    getraster(ALWB{Values,Year}, :asce_pet; date)
    @test isfile(joinpath(alwb_path, "values", "year", "asce_pet.nc"))
    getraster(ALWB{Values,Year}, :dd; date)
    @test isfile(joinpath(alwb_path, "values", "year", "dd.nc"))
end
