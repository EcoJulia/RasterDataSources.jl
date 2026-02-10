using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "TerraClimate" begin

    terraclimate_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "TerraClimate")
    @test rasterpath(TerraClimate) == terraclimate_path
    @test rasterpath(TerraClimate{Historical}) == joinpath(terraclimate_path, "historical")
    @test rasterpath(TerraClimate{Plus2C}) == joinpath(terraclimate_path, "plus2c")
    @test rasterpath(TerraClimate{Plus4C}) == joinpath(terraclimate_path, "plus4c")

    @test rastername(TerraClimate{Historical}, :tmax; date=Date(2020, 1)) == "TerraClimate_tmax_2020.nc"
    @test rastername(TerraClimate{Plus2C}, :tmax; date=Date(2000, 1)) == "TerraClimate_2c_tmax_2000.nc"
    @test rastername(TerraClimate{Plus4C}, :tmax; date=Date(2000, 1)) == "TerraClimate_4c_tmax_2000.nc"

    @test rasterpath(TerraClimate{Historical}, :tmax; date=Date(2020, 1)) ==
        joinpath(terraclimate_path, "historical", "TerraClimate_tmax_2020.nc")

    @test rasterurl(TerraClimate{Historical}, :tmax; date=Date(2020, 1)) ==
        URI(scheme="https", host="climate.northwestknowledge.net", path="/TERRACLIMATE-DATA/TerraClimate_tmax_2020.nc")
    @test rasterurl(TerraClimate{Plus2C}, :tmax; date=Date(2000, 1)) ==
        URI(scheme="https", host="thredds.northwestknowledge.net", path="/thredds/fileServer/TERRACLIMATE_ALL/data_plus2C/TerraClimate_2c_tmax_2000.nc")
    @test rasterurl(TerraClimate{Plus4C}, :tmax; date=Date(2000, 1)) ==
        URI(scheme="https", host="thredds.northwestknowledge.net", path="/thredds/fileServer/TERRACLIMATE_ALL/data_plus4C/TerraClimate_4c_tmax_2000.nc")

    @test RasterDataSources.getraster_keywords(TerraClimate) == (:date,)
    @test RasterDataSources.getraster_keywords(TerraClimate{Historical}) == (:date,)
    @test RasterDataSources.getraster_keywords(TerraClimate{Plus2C}) == (:date,)

    # Test actual download - historical
    raster_path = joinpath(terraclimate_path, "historical", "TerraClimate_tmax_2023.nc")
    @test getraster(TerraClimate{Historical}, :tmax; date=DateTime(2023, 01, 01)) == raster_path
    @test isfile(raster_path)

    # Test convenience method (TerraClimate without parameter -> Historical)
    @test getraster(TerraClimate, :tmax; date=DateTime(2023, 01, 01)) == raster_path

    # Test tuple of layers returns NamedTuple
    raster_path_tmin = joinpath(terraclimate_path, "historical", "TerraClimate_tmin_2023.nc")
    result = getraster(TerraClimate{Historical}, (:tmax, :tmin); date=DateTime(2023, 01, 01))
    @test result == (tmax=raster_path, tmin=raster_path_tmin)
    @test isfile(raster_path_tmin)

    # Test array of layers
    @test getraster(TerraClimate{Historical}, [:tmax]; date=DateTime(2023, 01, 01)) == (tmax=raster_path,)

    # Test array of dates
    @test getraster(TerraClimate{Historical}, :tmax; date=[DateTime(2023, 01, 01)]) == [raster_path]
end
