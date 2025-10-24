
using RasterDataSources, Test, Dates, URIs
using RasterDataSources: rastername, rasterpath, rasterurl

@testset "NCEP" begin
    @testset "reanalysis" begin
        @testset "SurfaceGauss" begin
            @test rastername(NCEP{SurfaceGauss}, "tmax.2m.gauss"; date=Date(2001)) == "tmax.2m.gauss.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "surface_gauss", "tmax.2m.gauss.2001.nc")
            @test rasterpath(NCEP{SurfaceGauss}, :tmax; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/surface_gauss/tmax.2m.gauss.2001.nc")
            @test rasterurl(NCEP{SurfaceGauss}, "tmax.2m.gauss", Date(2001), "reanalysis") == url
        end
        @testset "DailyPressure" begin
            @test rastername(NCEP{DailyPressure}, "hgt"; date=Date(2001)) == "hgt.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Dailies", "pressure", "hgt.2001.nc")
            @test rasterpath(NCEP{DailyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Dailies/pressure/hgt.2001.nc")
            @test rasterurl(NCEP{DailyPressure}, "hgt", Date(2001), "reanalysis") == url
        end
        @testset "MonthlyPressure" begin
            @test rastername(NCEP{MonthlyPressure}, "hgt"; date=Date(2001)) == "hgt.mon.mean.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "pressure", "hgt.mon.mean.nc")
            @test rasterpath(NCEP{MonthlyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Monthlies/pressure/hgt.mon.mean.nc")
            @test rasterurl(NCEP{MonthlyPressure}, "hgt", Date(2001), "reanalysis") == url
        end
    end
    @testset "reanalysis2" begin
        @testset "DailySurfaceReanalysis2" begin
            @test rastername(NCEP{DailySurfaceReanalysis2}, "mslp"; date=Date(2001)) == "mslp.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis2", "Dailies", "surface", "mslp.2001.nc")
            @test rasterpath(NCEP{DailySurfaceReanalysis2}, :mslp; date=Date(2001), dataset="reanalysis2") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis2/Dailies/surface/mslp.2001.nc")
            @test rasterurl(NCEP{DailySurfaceReanalysis2}, "mslp", Date(2001), "reanalysis2") == url
        end
    end
end
