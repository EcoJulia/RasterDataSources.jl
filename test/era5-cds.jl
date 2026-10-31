using RasterDataSources, URIs, Extents, Test, Dates
using RasterDataSources: rastername, rasterpath, layers, _cds_area, _cds_request_body, _cds_dataset_id,
    _cds_snap, _validate_cds_extent, _cds_token

@testset "ERA5{CDS} / ERA5{CDS,Land}" begin

    tas_extent = Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))

    @test _cds_dataset_id(ERA5{CDS}) == "reanalysis-era5-single-levels"
    @test _cds_dataset_id(ERA5{CDS,Land}) == "reanalysis-era5-land"

    @test _cds_area(tas_extent) == [-40.0, 143.0, -44.0, 149.0]

    body = _cds_request_body(ERA5{CDS,Land}, :t2m, Date(2020, 2, 1), tas_extent)
    inputs = body["inputs"]
    @test inputs["variable"] == ["2m_temperature"]
    @test inputs["year"] == ["2020"]
    @test inputs["month"] == ["02"]
    @test inputs["day"] == [lpad(d, 2, '0') for d in 1:29] # 2020 is a leap year
    @test length(inputs["time"]) == 24
    @test inputs["time"][1] == "00:00"
    @test inputs["time"][end] == "23:00"
    @test inputs["area"] == [-40.0, 143.0, -44.0, 149.0]
    @test inputs["data_format"] == "netcdf"
    @test !haskey(inputs, "product_type")

    body2 = _cds_request_body(ERA5{CDS}, :t2m, Date(2021, 1, 1), tas_extent)
    @test body2["inputs"]["product_type"] == "reanalysis"

    @test rasterpath(ERA5{CDS}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "CDS-ERA5")
    @test rasterpath(ERA5{CDS,Land}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "CDS-ERA5-Land")

    @test layername(ERA5{CDS,Land}, :e) == "total_evaporation"
    @test layername(ERA5{CDS}, :e) == "evaporation"
    @test :tcc in layers(ERA5{CDS})
    @test !(:tcc in layers(ERA5{CDS,Land}))

    # Extents expand outward to the grid
    odd_extent = Extent(X=(143.13, 148.97), Y=(-44.01, -0.1))
    @test _cds_snap(ERA5{CDS}, odd_extent) == Extent(X=(143.0, 149.0), Y=(-44.25, 0.0))
    @test _cds_snap(ERA5{CDS,Land}, odd_extent) == Extent(X=(143.1, 149.0), Y=(-44.1, -0.1))
    @test _cds_area(_cds_snap(ERA5{CDS,Land}, odd_extent)) ==
        _cds_request_body(ERA5{CDS,Land}, :t2m, Date(2020, 2, 1), odd_extent)["inputs"]["area"]

    @test rastername(ERA5{CDS}, :t2m; date=Date(2020, 2, 1), extent=odd_extent) ==
        "143.0_149.0_-44.25_0.0_202002.nc"
    @test rasterpath(ERA5{CDS,Land}, :t2m; date=Date(2020, 2, 1), extent=tas_extent) ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "CDS-ERA5-Land", "t2m", "143.0_149.0_-44.0_-40.0_202002.nc")

    @test RasterDataSources.getraster_keywords(ERA5{CDS,Land}) == (:date, :extent)
    @test RasterDataSources.date_step(ERA5{CDS,Land}) == Month(1)

    @test_throws ArgumentError getraster(ERA5{CDS,Land}, :tcc; date=Date(2020, 2, 1), extent=tas_extent)
    @test_throws ArgumentError getraster(ERA5{CDS,Land}, :t2m;
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
end
