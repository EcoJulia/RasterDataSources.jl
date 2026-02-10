
using RasterDataSources, Test, Dates
using URIs: URI
using RasterDataSources: rastername, rasterpath, rasterurl, layers, getraster_keywords

@testset "NCEP" begin
    @testset "layers" begin
        @test :hgt in layers(NCEP{SixHourlyPressure})
        @test :pr_wtr in layers(NCEP{SixHourlySurface})
        @test :hgt in layers(NCEP{DailyPressure})
        @test :slp in layers(NCEP{DailySurface})
        @test :mslp in layers(NCEP{DailySurfaceReanalysis2})
        @test :hgt in layers(NCEP{MonthlyPressure})
        @test :slp in layers(NCEP{MonthlySurface})
        @test :tmax in layers(NCEP{SurfaceGauss})
    end

    @testset "getraster_keywords" begin
        @test getraster_keywords(NCEP) == (:date, :dataset)
    end

    @testset "reanalysis" begin
        @testset "SixHourlyPressure" begin
            @test rastername(NCEP{SixHourlyPressure}, "hgt"; date=Date(2001)) == "hgt.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "pressure", "hgt.2001.nc")
            @test rasterpath(NCEP{SixHourlyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/pressure/hgt.2001.nc")
            @test rasterurl(NCEP{SixHourlyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "SixHourlySurface" begin
            @test rastername(NCEP{SixHourlySurface}, "pr_wtr.eatm"; date=Date(2001)) == "pr_wtr.eatm.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "surface", "pr_wtr.eatm.2001.nc")
            @test rasterpath(NCEP{SixHourlySurface}, :pr_wtr; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/surface/pr_wtr.eatm.2001.nc")
            @test rasterurl(NCEP{SixHourlySurface}, :pr_wtr; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "SurfaceGauss" begin
            @test rastername(NCEP{SurfaceGauss}, "tmax.2m.gauss"; date=Date(2001)) == "tmax.2m.gauss.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "surface_gauss", "tmax.2m.gauss.2001.nc")
            @test rasterpath(NCEP{SurfaceGauss}, :tmax; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/surface_gauss/tmax.2m.gauss.2001.nc")
            @test rasterurl(NCEP{SurfaceGauss}, :tmax; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "DailyPressure" begin
            @test rastername(NCEP{DailyPressure}, "hgt"; date=Date(2001)) == "hgt.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Dailies", "pressure", "hgt.2001.nc")
            @test rasterpath(NCEP{DailyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Dailies/pressure/hgt.2001.nc")
            @test rasterurl(NCEP{DailyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "DailySurface" begin
            @test rastername(NCEP{DailySurface}, "slp"; date=Date(2001)) == "slp.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Dailies", "surface", "slp.2001.nc")
            @test rasterpath(NCEP{DailySurface}, :slp; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Dailies/surface/slp.2001.nc")
            @test rasterurl(NCEP{DailySurface}, :slp; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "MonthlyPressure" begin
            @test rastername(NCEP{MonthlyPressure}, "hgt"; date=Date(2001)) == "hgt.mon.mean.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "pressure", "hgt.mon.mean.nc")
            @test rasterpath(NCEP{MonthlyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Monthlies/pressure/hgt.mon.mean.nc")
            @test rasterurl(NCEP{MonthlyPressure}, :hgt; date=Date(2001), dataset="reanalysis") == url
        end
        @testset "MonthlySurface" begin
            @test rastername(NCEP{MonthlySurface}, "slp"; date=Date(2001)) == "slp.mon.mean.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "surface", "slp.mon.mean.nc")
            @test rasterpath(NCEP{MonthlySurface}, :slp; date=Date(2001), dataset="reanalysis") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Monthlies/surface/slp.mon.mean.nc")
            @test rasterurl(NCEP{MonthlySurface}, :slp; date=Date(2001), dataset="reanalysis") == url
        end
    end

    @testset "reanalysis2" begin
        @testset "DailySurfaceReanalysis2" begin
            @test rastername(NCEP{DailySurfaceReanalysis2}, "mslp"; date=Date(2001)) == "mslp.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis2", "Dailies", "surface", "mslp.2001.nc")
            @test rasterpath(NCEP{DailySurfaceReanalysis2}, :mslp; date=Date(2001), dataset="reanalysis2") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis2/Dailies/surface/mslp.2001.nc")
            @test rasterurl(NCEP{DailySurfaceReanalysis2}, :mslp; date=Date(2001), dataset="reanalysis2") == url
        end
        @testset "SurfaceGauss reanalysis2" begin
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis2", "gaussian_grid", "tmax.2m.gauss.2001.nc")
            @test rasterpath(NCEP{SurfaceGauss}, :tmax; date=Date(2001), dataset="reanalysis2") == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis2/gaussian_grid/tmax.2m.gauss.2001.nc")
            @test rasterurl(NCEP{SurfaceGauss}, :tmax; date=Date(2001), dataset="reanalysis2") == url
        end
    end

    @testset "getraster download" begin
        # Test actual download - uses a small monthly file
        raster_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "surface", "slp.mon.mean.nc")
        @test getraster(NCEP{MonthlySurface}, :slp; date=Date(2001), dataset="reanalysis") == raster_path
        @test isfile(raster_path)

        # Test tuple of layers
        @test getraster(NCEP{MonthlySurface}, (:slp,); date=Date(2001), dataset="reanalysis") == (slp=raster_path,)
    end
end
