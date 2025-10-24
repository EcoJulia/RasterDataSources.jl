
using RasterDataSources, Test, Dates, URIs
using RasterDataSources: rastername, rasterpath, rasterurl, _get_filename_part

@testset "TerraClimate" begin
    const RASTERDATASOURCES_PATH = ENV["RASTERDATASOURCES_PATH"]
    @testset "Historical" begin
        filename_part = _get_filename_part(TerraClimate{Historical}, :tmax)
        @test rastername(TerraClimate{Historical}, filename_part; date=Date(2001)) == "TerraClimate_tmax_2001.nc"
        
        path = joinpath(RASTERDATASOURCES_PATH, "TerraClimate", "Historical", "TerraClimate_tmax_2001.nc")
        @test rasterpath(TerraClimate{Historical}, :tmax; date=Date(2001)) == path
        
        url = URI(scheme="http", host="thredds.northwestknowledge.net", port="8080", path="/thredds/fileServer/TERRACLIMATE_ALL/data/TerraClimate_tmax_2001.nc")
        @test rasterurl(TerraClimate{Historical}, filename_part, Date(2001)) == url
    end
    @testset "Plus2C" begin
        filename_part = _get_filename_part(TerraClimate{Plus2C}, :tmax)
        @test rastername(TerraClimate{Plus2C}, filename_part; date=Date(2001)) == "TerraClimate_2c_tmax_2001.nc"
        
        path = joinpath(RASTERDATASOURCES_PATH, "TerraClimate", "Plus2C", "TerraClimate_2c_tmax_2001.nc")
        @test rasterpath(TerraClimate{Plus2C}, :tmax; date=Date(2001)) == path
        
        url = URI(scheme="http", host="thredds.northwestknowledge.net", port="8080", path="/thredds/fileServer/TERRACLIMATE_ALL/data_plus2C/TerraClimate_2c_tmax_2001.nc")
        @test rasterurl(TerraClimate{Plus2C}, filename_part, Date(2001)) == url
    end
    @testset "Plus4C" begin
        filename_part = _get_filename_part(TerraClimate{Plus4C}, :tmax)
        @test rastername(TerraClimate{Plus4C}, filename_part; date=Date(2001)) == "TerraClimate_4c_tmax_2001.nc"
        
        path = joinpath(RASTERDATASOURCES_PATH, "TerraClimate", "Plus4C", "TerraClimate_4c_tmax_2001.nc")
        @test rasterpath(TerraClimate{Plus4C}, :tmax; date=Date(2001)) == path
        
        url = URI(scheme="http", host="thredds.northwestknowledge.net", port="8080", path="/thredds/fileServer/TERRACLIMATE_ALL/data_plus4C/TerraClimate_4c_tmax_2001.nc")
        @test rasterurl(TerraClimate{Plus4C}, filename_part, Date(2001)) == url
    end
end
