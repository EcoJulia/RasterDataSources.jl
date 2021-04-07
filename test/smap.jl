using Dates, Test, URIs, RasterDataSources

@testset "SMAP L4" begin
    using RasterDataSources: rastername, rasterurl, rasterpath
    ENV["RASTERDATASOURCES_EARTHDATA_USER"] = "rafaelschouten"
    ENV["RASTERDATASOURCES_EARTHDATA_PASSWORD"] = "Ranchorelaxo5"

    @test rastername(SMAP{L4{:carbon}}; date=DateTime(2015)) == "SMAP_L4_C_mdl_20150101T000000_Vv5022_001.h5"
    @test rastername(SMAP{L4{:soilmoisture}}; date=DateTime(2018)) == "SMAP_L4_SM_aup_20180101T000000_Vv5030_001.h5"
    @test rastername(SMAP{L4{:geophysical}}; date=DateTime(2020)) == "SMAP_L4_SM_gph_20200101T000000_Vv5012_001.h5"
    l4_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SMAP", "SPL4CMDL.005")
    @test rasterpath(SMAP{L4{:carbon}}) == l4_path
    @test rasterpath(SMAP{L4{:carbon}}; date=DateTime(2020)) == 
        joinpath(l4_path, "2020.01.01", "SMAP_L4_C_mdl_20200101T000000_Vv5012_001.h5")
    @test rasterurl(SMAP{L4{:carbon}}; date=DateTime(2020)) == 
        URI(scheme="https", host="n5eil01u.ecs.nsidc.org", path="/SMAP/SPL4CMDL.005/2020.01.01/SMAP_L4_C_mdl_20200101T000000_Vv5012_001.h5")
    @test isfile(rasterpath(SMAP{L4{:carbon}}; date=DateTime(2018, 3))) == false
    getraster(SMAP{L4{:carbon}}, DateTime(2018, 3))
    @test isfile(rasterpath(SMAP{L4{:carbon}}; date=DateTime(2018, 3))) == true

    @test isfile(rasterpath(SMAP{L4{:soilmoisture}}; date=DateTime(2020, 3, 1, 3))) == false
    getraster(SMAP{L4{:soilmoisture}}; date=DateTime(2017, 3, 1))
    @test isfile(rasterpath(SMAP{L4{:soilmoisture}}; date=DateTime(2018, 3, 1, 3))) == true
end
