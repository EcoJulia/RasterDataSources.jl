using RasterDataSources, Extents, Dates, Test
using RasterDataSources: rastername, rasterpath, layers, _cds_dataset_id, _cds_request_body

@testset "SEAS5" begin
    extent = Extent(X=(143.2, 149.0), Y=(-44.0, -40.5))
    date = Date(2025, 1, 1)
    root = joinpath(ENV["RASTERDATASOURCES_PATH"], "SEAS5")

    @test length(layers(SEAS5)) == 35
    @test length(layers(SEAS5{Month})) == 35
    @test layername(SEAS5, :total_precipitation) == "tp"
    @test layername(SEAS5{Month}, :total_precipitation) == "tprate"
    @test !(:volumetric_soil_moisture in layers(SEAS5{Month}))
    @test !(:wind_speed_10m in layers(SEAS5))

    @test _cds_dataset_id(SEAS5) == "seasonal-original-single-levels"
    @test _cds_dataset_id(SEAS5{Month}) == "seasonal-monthly-single-levels"
    @test RasterDataSources.getraster_keywords(SEAS5) == (:date, :extent, :system)
    @test RasterDataSources.getraster_keywords(SEAS5{Month}) == (:date, :extent, :system, :product_type)
    @test RasterDataSources.date_step(SEAS5{Month}) == Month(1)

    name = "143.0_149.0_-44.0_-40.0_202501.nc"
    @test rastername(SEAS5, :temperature_2m; date, extent) == name
    @test rasterpath(SEAS5, :temperature_2m; date, extent) == joinpath(root, "system51", "temperature_2m", name)
    @test rasterpath(SEAS5, :temperature_2m; date, extent, system="5") == joinpath(root, "system5", "temperature_2m", name)
    @test rasterpath(SEAS5{Month}, :temperature_2m; date, extent) ==
        joinpath(root, "Month", "monthly_mean", "system51", "temperature_2m", name)
    @test rasterpath(SEAS5{Month}, :temperature_2m; date, extent, product_type="ensemble_mean") ==
        joinpath(root, "Month", "ensemble_mean", "system51", "temperature_2m", name)

    inputs = _cds_request_body(SEAS5, :temperature_2m, date, extent; system="51")["inputs"]
    @test inputs["originating_centre"] == "ecmwf"
    @test inputs["system"] == "51"
    @test inputs["variable"] == ["2m_temperature"]
    @test inputs["year"] == ["2025"]
    @test inputs["month"] == ["01"]
    @test inputs["day"] == ["01"]
    @test inputs["area"] == [-40.0, 143.0, -44.0, 149.0]
    @test inputs["data_format"] == "netcdf"
    @test length(inputs["leadtime_hour"]) == 860
    @test first(inputs["leadtime_hour"]) == "6"
    @test !haskey(inputs, "product_type")

    inputs = _cds_request_body(SEAS5, :total_precipitation, date, extent; system="51")["inputs"]
    @test length(inputs["leadtime_hour"]) == 215
    @test first(inputs["leadtime_hour"]) == "24"
    @test last(inputs["leadtime_hour"]) == "5160"

    inputs = _cds_request_body(SEAS5{Month}, :wind_speed_10m, date, extent; system="5", product_type="ensemble_mean")["inputs"]
    @test inputs["variable"] == ["10m_wind_speed"]
    @test inputs["system"] == "5"
    @test inputs["product_type"] == ["ensemble_mean"]
    @test inputs["leadtime_month"] == string.(1:6)
    @test !haskey(inputs, "day")
    @test !haskey(inputs, "leadtime_hour")
    @test _cds_request_body(SEAS5, :snow_depth_water_equivalent, date, extent; system="51")["inputs"]["variable"] == ["snow_depth"]

    @test_throws ArgumentError getraster(SEAS5, :wind_speed_10m; date, extent)
    @test_throws ArgumentError getraster(SEAS5, :temperature_2m; date, extent, system="4")
    @test_throws ArgumentError getraster(SEAS5{Month}, :volumetric_soil_moisture; date, extent)
    @test_throws ArgumentError getraster(SEAS5{Month}, :temperature_2m; date, extent, product_type="monthly_median")
    @test_throws ArgumentError getraster(SEAS5{Month}, :temperature_2m; date, extent=Extent(X=(149.0, 143.0), Y=(-44.0, -40.0)))

    # Only monthly runs live: `SEAS5` requests can queue for hours
    if haskey(ENV, "RASTERDATASOURCES_ERA5_CDS_TOKEN")
        small_extent = Extent(X=(144.2, 144.8), Y=(-37.8, -37.2))
        path = getraster(SEAS5{Month}, :temperature_2m; date, extent=small_extent)
        @test path == rasterpath(SEAS5{Month}, :temperature_2m; date, extent=small_extent)
        @test isfile(path)
        @test read(path, 4) == UInt8[0x89, 'H', 'D', 'F']
        @test getraster(SEAS5{Month}, :temperature_2m; date, extent=small_extent) == path
    end
end
