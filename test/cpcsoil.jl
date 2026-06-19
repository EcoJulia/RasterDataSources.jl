using RasterDataSources, URIs, Test
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "CPCSoil" begin
    cpcsoil_dir = joinpath(ENV["RASTERDATASOURCES_PATH"], "CPCSoil")

    @testset "LTM period 1991-2020 (default)" begin
        path = joinpath(cpcsoil_dir, "soilw.mon.1991-2020.ltm.v2.nc")
        @test rasterpath(CPCSoil) == path
        @test rastername(CPCSoil) == "soilw.mon.1991-2020.ltm.v2.nc"
        @test rasterurl(CPCSoil) == URI(scheme="https", host="psl.noaa.gov",
            path="/thredds/fileServer/Datasets/cpcsoil/soilw.mon.1991-2020.ltm.v2.nc")
        @test RasterDataSources.getraster_keywords(CPCSoil) == (:period,)
    end

    @testset "LTM period 1981-2010" begin
        path = joinpath(cpcsoil_dir, "soilw.mon.1981-2010.ltm.v2.nc")
        @test rasterpath(CPCSoil; period="1981-2010") == path
        @test rastername(CPCSoil; period="1981-2010") == "soilw.mon.1981-2010.ltm.v2.nc"
        @test rasterurl(CPCSoil; period="1981-2010") == URI(scheme="https", host="psl.noaa.gov",
            path="/thredds/fileServer/Datasets/cpcsoil/soilw.mon.1981-2010.ltm.v2.nc")
    end

    @testset "invalid period" begin
        @test_throws ArgumentError getraster(CPCSoil; period="2000-2030")
    end

    @testset "Mean" begin
        path = joinpath(cpcsoil_dir, "soilw.mon.mean.v2.nc")
        @test rasterpath(CPCSoil{Mean}) == path
        @test rastername(CPCSoil{Mean}) == "soilw.mon.mean.v2.nc"
        @test rasterurl(CPCSoil{Mean}) == URI(scheme="https", host="psl.noaa.gov",
            path="/thredds/fileServer/Datasets/cpcsoil/soilw.mon.mean.v2.nc")
        @test RasterDataSources.getraster_keywords(CPCSoil{Mean}) == ()
    end

    if !Sys.iswindows()
        @testset "download LTM" begin
            path = joinpath(cpcsoil_dir, "soilw.mon.1991-2020.ltm.v2.nc")
            @test getraster(CPCSoil) == path
            @test isfile(path)
        end
    end
end
