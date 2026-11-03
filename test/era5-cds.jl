using RasterDataSources, URIs, Extents, Test, Dates
using RasterDataSources: rastername, rasterpath, layers, _cds_area, _cds_request_body, _cds_dataset_id,
    _cds_snap, _validate_cds_extent, _cds_token

@testset "ERA5{ECMWF,CDS} / ERA5{ECMWF,CDS,Land}" begin

    tas_extent = Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))

    @test _cds_dataset_id(ERA5{ECMWF,CDS}) == "reanalysis-era5-single-levels"
    @test _cds_dataset_id(ERA5{ECMWF,CDS,Land}) == "reanalysis-era5-land"

    @test _cds_area(tas_extent) == [-40.0, 143.0, -44.0, 149.0]

    body = _cds_request_body(ERA5{ECMWF,CDS,Land}, :skin_temperature, Date(2020, 2, 1), tas_extent)
    inputs = body["inputs"]
    @test inputs["variable"] == ["skin_temperature"]
    @test inputs["year"] == ["2020"]
    @test inputs["month"] == ["02"]
    @test inputs["day"] == [lpad(d, 2, '0') for d in 1:29] # 2020 is a leap year
    @test length(inputs["time"]) == 24
    @test inputs["time"][1] == "00:00"
    @test inputs["time"][end] == "23:00"
    @test inputs["area"] == [-40.0, 143.0, -44.0, 149.0]
    @test inputs["data_format"] == "netcdf"
    @test !haskey(inputs, "product_type")

    body2 = _cds_request_body(ERA5{ECMWF,CDS}, :skin_temperature, Date(2021, 1, 1), tas_extent)
    @test body2["inputs"]["product_type"] == "reanalysis"

    @test rasterpath(ERA5{ECMWF,CDS}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "CDS")
    @test rasterpath(ERA5{ECMWF,CDS,Land}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "CDS", "Land")

    @test length(layers(ERA5{ECMWF,CDS})) == 262
    @test length(layers(ERA5{ECMWF,CDS,Land})) == 60
    @test layers(ERA5{ECMWF,CDS}) == layers(ERA5{Google,ARCO})
    @test layername(ERA5{ECMWF,CDS}, :snow_depth_water_equivalent) == "sd"
    @test layername(ERA5{ECMWF,CDS,Land}, :snow_depth_water_equivalent) == "sd"
    @test layername(ERA5{ECMWF,CDS,Land}, :snow_depth) == "sde"
    @test !(:snow_depth in layers(ERA5{ECMWF,CDS}))
    cds_variable(T, layer) = only(_cds_request_body(T, layer, Date(2020, 2, 1), tas_extent)["inputs"]["variable"])
    @test cds_variable(ERA5{ECMWF,CDS}, :snow_depth_water_equivalent) == "snow_depth"
    @test cds_variable(ERA5{ECMWF,CDS,Land}, :snow_depth_water_equivalent) == "snow_depth_water_equivalent"
    @test cds_variable(ERA5{ECMWF,CDS}, :temperature_2m) == "2m_temperature"
    @test cds_variable(ERA5{ECMWF,CDS,Land}, :u_component_of_wind_10m) == "10m_u_component_of_wind"
    @test cds_variable(ERA5{ECMWF,CDS}, :geopotential_at_surface) == "geopotential"
    @test cds_variable(ERA5{ECMWF,CDS,Land}, :geopotential_at_surface) == "geopotential"
    @test layername(ERA5{ECMWF,CDS,Land}, :total_evaporation) == "e"
    @test :total_cloud_cover in layers(ERA5{ECMWF,CDS})
    @test !(:total_cloud_cover in layers(ERA5{ECMWF,CDS,Land}))

    # Extents expand outward to the grid
    odd_extent = Extent(X=(143.13, 148.97), Y=(-44.01, -0.1))
    @test _cds_snap(ERA5{ECMWF,CDS}, odd_extent) == Extent(X=(143.0, 149.0), Y=(-44.25, 0.0))
    @test _cds_snap(ERA5{ECMWF,CDS,Land}, odd_extent) == Extent(X=(143.1, 149.0), Y=(-44.1, -0.1))
    @test _cds_area(_cds_snap(ERA5{ECMWF,CDS,Land}, odd_extent)) ==
        _cds_request_body(ERA5{ECMWF,CDS,Land}, :skin_temperature, Date(2020, 2, 1), odd_extent)["inputs"]["area"]

    @test rastername(ERA5{ECMWF,CDS}, :skin_temperature; date=Date(2020, 2, 1), extent=odd_extent) ==
        "143.0_149.0_-44.25_0.0_202002.nc"
    @test rasterpath(ERA5{ECMWF,CDS,Land}, :skin_temperature; date=Date(2020, 2, 1), extent=tas_extent) ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "CDS", "Land", "skin_temperature", "143.0_149.0_-44.0_-40.0_202002.nc")
    @test rasterpath(ERA5{ECMWF,CDS}, :temperature_2m; date=Date(2020, 2, 1), extent=tas_extent) ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "CDS", "temperature_2m", "143.0_149.0_-44.0_-40.0_202002.nc")

    @test RasterDataSources.getraster_keywords(ERA5{ECMWF,CDS,Land}) == (:date, :extent, :update)
    @test RasterDataSources.date_step(ERA5{ECMWF,CDS,Land}) == Month(1)

    @test_throws ArgumentError getraster(ERA5{ECMWF,CDS,Land}, :total_cloud_cover; date=Date(2020, 2, 1), extent=tas_extent)
    @test_throws ArgumentError getraster(ERA5{ECMWF,CDS,Land}, :skin_temperature;
        date=Date(2020, 2, 1), extent=Extent(X=(149.0, 143.0), Y=(-44.0, -40.0)))

    @test_throws ArgumentError _validate_cds_extent(Extent(X=(200.0, 210.0), Y=(-10.0, 10.0)))
    @test_throws ArgumentError _validate_cds_extent(Extent(X=(1.0, 2.0), Y=(-100.0, -10.0)))
    @test_throws ArgumentError _validate_cds_extent(Extent(X=(NaN, 2.0), Y=(-10.0, 10.0)))

    withenv("RASTERDATASOURCES_ERA5_CDS_TOKEN" => "abc") do
        @test _cds_token() == "abc"
    end
    withenv("RASTERDATASOURCES_ERA5_CDS_TOKEN" => nothing) do
        @test_throws ErrorException _cds_token()
    end

    if haskey(ENV, "RASTERDATASOURCES_ERA5_CDS_TOKEN")
        small_extent = Extent(X=(145.0, 145.1), Y=(-37.9, -37.8))
        live_layers = (:skin_temperature, :total_precipitation)
        paths = getraster(ERA5{ECMWF,CDS,Land}, live_layers; date=Date(2020, 1, 1), extent=small_extent)
        @test keys(paths) == live_layers
        @test all(isfile, paths)
        @test all(p -> read(p, 4) == UInt8[0x89, 'H', 'D', 'F'], paths)
        @test paths.skin_temperature == rasterpath(ERA5{ECMWF,CDS,Land}, :skin_temperature; date=Date(2020, 1, 1), extent=small_extent)
        @test getraster(ERA5{ECMWF,CDS,Land}, live_layers; date=Date(2020, 1, 1), extent=small_extent) == paths
    end
end
