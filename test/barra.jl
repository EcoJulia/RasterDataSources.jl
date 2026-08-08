using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "BARRA" begin

    barra_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "BARRA")
    @test rasterpath(BARRA{BARRAC2, AUST04}) == barra_path

    @testset "confirmed real URL (BARRA-C2, AUST-04, day, tas, 1979-01)" begin
        @test rastername(BARRA{BARRAC2, AUST04, Day}, :tas; date=Date(1979, 1, 1)) ==
            "tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_day_197901-197901.nc"
        @test rasterurl(BARRA{BARRAC2, AUST04, Day}, :tas; date=Date(1979, 1, 1)) ==
            URI("https://thredds.nci.org.au/thredds/fileServer/ob53/output/reanalysis/AUST-04/BOM/ERA5/historical/hres/BARRA-C2/v1/day/tas/latest/tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_day_197901-197901.nc")
    end

    @testset "default frequency is Hour" begin
        @test rastername(BARRA{BARRAC2, AUST04}, :tas; date=Date(1979, 1, 1)) ==
            "tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_1hr_197901-197901.nc"
    end

    @testset "domain validity per product" begin
        @test :tas in RasterDataSources.layers(BARRA{BARRAR2, AUS11})
        @test :tas in RasterDataSources.layers(BARRA{BARRAR2, AUST11})
        @test :tas in RasterDataSources.layers(BARRA{BARRAC2, AUST04})
        @test_throws ArgumentError RasterDataSources.layers(BARRA{BARRAC2, AUS11})
        @test_throws ArgumentError RasterDataSources.layers(BARRA{BARRAR2, AUST04})
        @test_throws ArgumentError getraster(BARRA{BARRAR2, AUST04}, :tas; date=Date(2020, 1, 1))
    end

    @testset "tasmax unavailable at BARRA-R2 Hour frequency only" begin
        @test !(:tasmax in RasterDataSources.layers(BARRA{BARRAR2, AUS11}))
        @test :tasmax in RasterDataSources.layers(BARRA{BARRAR2, AUS11, Day})
        @test :tasmax in RasterDataSources.layers(BARRA{BARRAC2, AUST04})
        @test_throws ArgumentError getraster(BARRA{BARRAR2, AUS11}, :tasmax; date=Date(2020, 1, 1))
    end

    @testset "soil variables: mrso/mrsol/tsl are day/mon only, mrsos is hourly too" begin
        @test !(:mrso  in RasterDataSources.layers(BARRA{BARRAC2, AUST04}))
        @test !(:mrsol in RasterDataSources.layers(BARRA{BARRAC2, AUST04}))
        @test !(:tsl   in RasterDataSources.layers(BARRA{BARRAC2, AUST04}))
        @test :mrso  in RasterDataSources.layers(BARRA{BARRAC2, AUST04, Day})
        @test :mrsol in RasterDataSources.layers(BARRA{BARRAC2, AUST04, Day})
        @test :tsl   in RasterDataSources.layers(BARRA{BARRAC2, AUST04, Day})
        @test :mrsos in RasterDataSources.layers(BARRA{BARRAC2, AUST04})
        @test_throws ArgumentError getraster(BARRA{BARRAC2, AUST04}, :mrsol; date=Date(2020, 1, 1))
        @test rastername(BARRA{BARRAC2, AUST04, Day}, :mrsol; date=Date(1979, 1, 1)) ==
            "mrsol_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_day_197901-197901.nc"
    end

    @testset "static layers use the Static frequency and take no date" begin
        name = "orog_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1.nc"
        @test RasterDataSources.layers(BARRA{BARRAC2, AUST04, Static}) == (:orog, :sftlf)
        @test RasterDataSources.getraster_keywords(BARRA{BARRAC2, AUST04, Static}) == ()
        @test rastername(BARRA{BARRAC2, AUST04, Static}, :orog) == name
        @test rasterpath(BARRA{BARRAC2, AUST04, Static}, :orog) ==
            joinpath(barra_path, "BARRA-C2", "AUST-04", "fx", "orog", name)
        @test rasterurl(BARRA{BARRAC2, AUST04, Static}, :sftlf) ==
            URI("https://thredds.nci.org.au/thredds/fileServer/ob53/output/reanalysis/AUST-04/BOM/ERA5/historical/hres/BARRA-C2/v1/fx/sftlf/latest/sftlf_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1.nc")
    end

    @test RasterDataSources.getraster_keywords(BARRA) == (:date,)
    @test RasterDataSources.date_step(BARRA{BARRAC2, AUST04}) == Month(1)
    @test_throws ArgumentError getraster(BARRA{BARRAC2, AUST04}, :tas)

    if !Sys.iswindows()
        # orog is a small static file (~1.5 MB), safe to actually download in
        # CI, unlike any dated variable file (~51 MB per variable-month).
        raster_path = joinpath(barra_path, "BARRA-C2", "AUST-04", "fx", "orog",
            "orog_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1.nc")
        @test getraster(BARRA{BARRAC2, AUST04, Static}, :orog) == raster_path
        @test isfile(raster_path)
    end
end
