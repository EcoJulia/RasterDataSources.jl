using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "ERA5" begin

    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5")
    @test rasterpath(ERA5) == era5_path

    @test rastername(ERA5, :t2m; date=Date(2020, 1)) == "e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc"
    @test rastername(ERA5, :t2m; date=Date(2020, 2)) == "e5.oper.an.sfc.128_167_2t.ll025sc.2020020100_2020022923.nc"

    @test rasterpath(ERA5, :t2m; date=Date(2020, 1)) ==
        joinpath(era5_path, "e5.oper.an.sfc", "202001", "e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc")

    @test rasterurl(ERA5, :t2m; date=Date(2020, 1)) ==
        URI(scheme="https", host="nsf-ncar-era5.s3.us-west-2.amazonaws.com",
            path="/e5.oper.an.sfc/202001/e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc")

    @test RasterDataSources.getraster_keywords(ERA5) == (:date,)

    # Test actual download
    raster_path = joinpath(era5_path, "e5.oper.an.sfc", "202001", "e5.oper.an.sfc.128_167_2t.ll025sc.2020010100_2020013123.nc")
    @test getraster(ERA5, :t2m; date=DateTime(2020, 1, 1)) == raster_path
    @test isfile(raster_path)

    # Test tuple of layers returns NamedTuple
    raster_path_sp = joinpath(era5_path, "e5.oper.an.sfc", "202001", "e5.oper.an.sfc.128_134_sp.ll025sc.2020010100_2020013123.nc")
    result = getraster(ERA5, (:t2m, :sp); date=DateTime(2020, 1, 1))
    @test result == (t2m=raster_path, sp=raster_path_sp)
    @test isfile(raster_path_sp)

    # Test array of layers
    @test getraster(ERA5, [:t2m]; date=DateTime(2020, 1, 1)) == (t2m=raster_path,)

    # Test array of dates
    @test getraster(ERA5, :t2m; date=[DateTime(2020, 1, 1)]) == [raster_path]
end
