
using RasterDataSources, Test, Dates
using URIs: URI
using RasterDataSources: _rastername, rasterpath, rasterurl, layers, getraster_keywords

# NCEP is organised on orthogonal type parameters: NCEP{Group, Reanalysis, Period}.
# Group ∈ {Pressure, Surface, SurfaceFlux}, Reanalysis ∈ {1, 2}, Period ∈ {SixHour, Day, Month}.
# Period defaults to SixHour (native) when the trailing parameter is omitted.

@testset "NCEP" begin
    @testset "layers" begin
        @test :hgt in layers(NCEP{Pressure, 1})
        @test :pr_wtr in layers(NCEP{Surface, 1})
        @test :hgt in layers(NCEP{Pressure, 1, Day})
        @test :slp in layers(NCEP{Surface, 1, Day})
        @test :mslp in layers(NCEP{Surface, 2, Day})
        @test :hgt in layers(NCEP{Pressure, 1, Month})
        @test :slp in layers(NCEP{Surface, 1, Month})
        @test :tmax in layers(NCEP{SurfaceFlux, 1})
    end

    @testset "getraster_keywords" begin
        @test getraster_keywords(NCEP) == (:date,)
    end

    @testset "reanalysis 1" begin
        @testset "Pressure (native)" begin
            @test _rastername(NCEP{Pressure, 1}, "hgt"; date=Date(2001)) == "hgt.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "pressure", "hgt.2001.nc")
            @test rasterpath(NCEP{Pressure, 1}, :hgt; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/pressure/hgt.2001.nc")
            @test rasterurl(NCEP{Pressure, 1}, :hgt; date=Date(2001)) == url
        end
        @testset "Surface (native)" begin
            @test _rastername(NCEP{Surface, 1}, "pr_wtr.eatm"; date=Date(2001)) == "pr_wtr.eatm.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "surface", "pr_wtr.eatm.2001.nc")
            @test rasterpath(NCEP{Surface, 1}, :pr_wtr; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/surface/pr_wtr.eatm.2001.nc")
            @test rasterurl(NCEP{Surface, 1}, :pr_wtr; date=Date(2001)) == url
        end
        @testset "SurfaceFlux (native)" begin
            @test _rastername(NCEP{SurfaceFlux, 1}, "tmax.2m.gauss"; date=Date(2001)) == "tmax.2m.gauss.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "surface_gauss", "tmax.2m.gauss.2001.nc")
            @test rasterpath(NCEP{SurfaceFlux, 1}, :tmax; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/surface_gauss/tmax.2m.gauss.2001.nc")
            @test rasterurl(NCEP{SurfaceFlux, 1}, :tmax; date=Date(2001)) == url
        end
        @testset "Pressure Day" begin
            @test _rastername(NCEP{Pressure, 1, Day}, "hgt"; date=Date(2001)) == "hgt.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Dailies", "pressure", "hgt.2001.nc")
            @test rasterpath(NCEP{Pressure, 1, Day}, :hgt; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Dailies/pressure/hgt.2001.nc")
            @test rasterurl(NCEP{Pressure, 1, Day}, :hgt; date=Date(2001)) == url
        end
        @testset "Surface Day" begin
            @test _rastername(NCEP{Surface, 1, Day}, "slp"; date=Date(2001)) == "slp.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Dailies", "surface", "slp.2001.nc")
            @test rasterpath(NCEP{Surface, 1, Day}, :slp; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Dailies/surface/slp.2001.nc")
            @test rasterurl(NCEP{Surface, 1, Day}, :slp; date=Date(2001)) == url
        end
        @testset "Pressure Month" begin
            @test _rastername(NCEP{Pressure, 1, Month}, "hgt"; date=Date(2001)) == "hgt.mon.mean.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "pressure", "hgt.mon.mean.nc")
            @test rasterpath(NCEP{Pressure, 1, Month}, :hgt; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Monthlies/pressure/hgt.mon.mean.nc")
            @test rasterurl(NCEP{Pressure, 1, Month}, :hgt; date=Date(2001)) == url
        end
        @testset "Surface Month" begin
            @test _rastername(NCEP{Surface, 1, Month}, "slp"; date=Date(2001)) == "slp.mon.mean.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "surface", "slp.mon.mean.nc")
            @test rasterpath(NCEP{Surface, 1, Month}, :slp; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis/Monthlies/surface/slp.mon.mean.nc")
            @test rasterurl(NCEP{Surface, 1, Month}, :slp; date=Date(2001)) == url
        end
    end

    @testset "reanalysis 2" begin
        @testset "Surface Day" begin
            @test _rastername(NCEP{Surface, 2, Day}, "mslp"; date=Date(2001)) == "mslp.2001.nc"
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis2", "Dailies", "surface", "mslp.2001.nc")
            @test rasterpath(NCEP{Surface, 2, Day}, :mslp; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis2/Dailies/surface/mslp.2001.nc")
            @test rasterurl(NCEP{Surface, 2, Day}, :mslp; date=Date(2001)) == url
        end
        @testset "SurfaceFlux" begin
            path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis2", "gaussian_grid", "tmax.2m.gauss.2001.nc")
            @test rasterpath(NCEP{SurfaceFlux, 2}, :tmax; date=Date(2001)) == path
            url = URI(scheme="https", host="downloads.psl.noaa.gov", path="/Datasets/ncep.reanalysis2/gaussian_grid/tmax.2m.gauss.2001.nc")
            @test rasterurl(NCEP{SurfaceFlux, 2}, :tmax; date=Date(2001)) == url
        end
    end

    @testset "getraster download" begin
        # Test actual download - uses a small monthly file
        raster_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "NCEP", "reanalysis", "Monthlies", "surface", "slp.mon.mean.nc")
        @test getraster(NCEP{Surface, 1, Month}, :slp; date=Date(2001)) == raster_path
        @test isfile(raster_path)

        # Test tuple of layers
        @test getraster(NCEP{Surface, 1, Month}, (:slp,); date=Date(2001)) == (slp=raster_path,)
    end
end
