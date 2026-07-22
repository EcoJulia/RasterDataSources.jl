using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "GRIDMET" begin

    gridmet_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "GRIDMET")
    @test rasterpath(GRIDMET) == gridmet_path

    @test rastername(GRIDMET, :tmmx; date=Date(2020, 6, 15)) == "tmmx_2020.nc"
    @test rastername(GRIDMET, :pr;   date=Date(1979, 1, 1))  == "pr_1979.nc"

    @test rasterpath(GRIDMET, :tmmx; date=Date(2020, 6, 15)) ==
        joinpath(gridmet_path, "tmmx", "tmmx_2020.nc")

    @test rasterurl(GRIDMET, :tmmx; date=Date(2020)) ==
        URI(scheme="https", host="www.northwestknowledge.net", path="/metdata/data/tmmx_2020.nc")

    @test RasterDataSources.getraster_keywords(GRIDMET) == (:date,)
    @test RasterDataSources.layers(GRIDMET) == (
        :tmmx, :tmmn, :pr, :rmax, :rmin, :sph, :srad, :th, :vs, :etr, :pet,
        :vpd, :erc, :bi, :fm1, :fm100, :pdsi, :z, :spi, :spei, :eddi,
    )
    @test RasterDataSources.date_step(GRIDMET) == Year(1)

    # Static elevation is a separate parametric type
    @test RasterDataSources.layers(GRIDMET{Elevation}) == (:elev,)
    @test RasterDataSources.getraster_keywords(GRIDMET{Elevation}) == ()
    @test rastername(GRIDMET{Elevation}, :elev) == "metdata_elevationdata.nc"
    @test rasterpath(GRIDMET{Elevation}, :elev) ==
        joinpath(gridmet_path, "elev", "metdata_elevationdata.nc")
    @test rasterurl(GRIDMET{Elevation}, :elev) ==
        URI("http://thredds.northwestknowledge.net:8080/thredds/fileServer/MET/elev/metdata_elevationdata.nc")

    if !Sys.iswindows()
        # Test actual download
        raster_path = joinpath(gridmet_path, "tmmx", "tmmx_2020.nc")
        @test getraster(GRIDMET, :tmmx; date=Date(2020, 1, 1)) == raster_path
        @test isfile(raster_path)

        # Tuple of layers returns NamedTuple
        raster_path_pr = joinpath(gridmet_path, "pr", "pr_2020.nc")
        result = getraster(GRIDMET, (:tmmx, :pr); date=Date(2020, 1, 1))
        @test result == (tmmx=raster_path, pr=raster_path_pr)
        @test isfile(raster_path_pr)

        # Tuple of dates expands across the year range
        @test getraster(GRIDMET, :tmmx; date=(Date(2019), Date(2020))) ==
            [joinpath(gridmet_path, "tmmx", "tmmx_2019.nc"), raster_path]

        # Static elevation layer, no date required
        raster_path_elev = joinpath(gridmet_path, "elev", "metdata_elevationdata.nc")
        @test getraster(GRIDMET{Elevation}, :elev) == raster_path_elev
        @test isfile(raster_path_elev)
    end
end
