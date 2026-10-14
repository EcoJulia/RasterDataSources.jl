using RasterDataSources, Extents, Test, Dates
using RasterDataSources: rastername, rasterpath, _cds_request_body, _cds_dataset_id,
    _check_seas5_leadtime, _check_seas5_system, _check_seas5_product_type

@testset "SEAS5 / SEAS5Monthly" begin

    tas_extent = Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))

    @test _cds_dataset_id(SEAS5) == "seasonal-original-single-levels"
    @test _cds_dataset_id(SEAS5Monthly) == "seasonal-monthly-single-levels"

    options = (; leadtime = _check_seas5_leadtime(SEAS5, 24:24:72), system = "51")
    inputs = _cds_request_body(SEAS5, ("2m_temperature", "total_precipitation"), Date(2026, 9, 1), tas_extent, options)["inputs"]
    @test inputs["originating_centre"] == "ecmwf"
    @test inputs["system"] == "51"
    @test inputs["variable"] == ["2m_temperature", "total_precipitation"]
    @test inputs["year"] == ["2026"]
    @test inputs["month"] == ["09"]
    @test inputs["day"] == ["01"]
    @test inputs["leadtime_hour"] == ["24", "48", "72"]
    @test inputs["area"] == [-40.0, 143.0, -44.0, 149.0]
    @test inputs["data_format"] == "netcdf"
    @test !haskey(inputs, "product_type")
    @test !haskey(inputs, "leadtime_month")

    moptions = (; leadtime = _check_seas5_leadtime(SEAS5Monthly, 1:6), product_type = "ensemble_mean", system = "51")
    minputs = _cds_request_body(SEAS5Monthly, ("2m_temperature",), Date(2026, 9, 1), tas_extent, moptions)["inputs"]
    @test minputs["leadtime_month"] == string.(1:6)
    @test minputs["product_type"] == ["ensemble_mean"]
    @test !haskey(minputs, "day")
    @test !haskey(minputs, "leadtime_hour")

    # Lead times: sorted, de-duplicated, and restricted to each dataset's grid.
    @test _check_seas5_leadtime(SEAS5, [48, 24, 24]) == [24, 48]
    @test _check_seas5_leadtime(SEAS5, 6) == [6]
    @test _check_seas5_leadtime(SEAS5Monthly, 3) == [3]
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5, 5)       # not a multiple of 6
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5, 5166)    # beyond 215 days
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5, Int[])
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5, 24.0)
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5Monthly, 0)
    @test_throws ArgumentError _check_seas5_leadtime(SEAS5Monthly, 7)

    @test _check_seas5_system(51) == "51"
    @test _check_seas5_system("5") == "5"
    @test_throws ArgumentError _check_seas5_system("4")
    @test _check_seas5_product_type(:monthly_maximum) == "monthly_maximum"
    @test_throws ArgumentError _check_seas5_product_type("monthly_median")

    @test rasterpath(SEAS5) == joinpath(ENV["RASTERDATASOURCES_PATH"], "SEAS5")
    @test rasterpath(SEAS5Monthly) == joinpath(ENV["RASTERDATASOURCES_PATH"], "SEAS5-Monthly")

    # Every request-shaping option must reach the cache filename.
    vars = ("2m_temperature",)
    base = rastername(SEAS5, vars; date=Date(2026, 9, 1), extent=tas_extent, leadtime=[24, 48], system="51")
    @test startswith(base, "202609_sys51_")
    @test endswith(base, ".nc")
    @test base != rastername(SEAS5, vars; date=Date(2026, 9, 1), extent=tas_extent, leadtime=[24, 48], system="5")
    @test base != rastername(SEAS5, vars; date=Date(2026, 9, 1), extent=tas_extent, leadtime=[24, 72], system="51")
    @test base != rastername(SEAS5, ("2m_temperature", "total_precipitation"); date=Date(2026, 9, 1), extent=tas_extent, leadtime=[24, 48], system="51")
    mname(p) = rastername(SEAS5Monthly, vars; date=Date(2026, 9, 1), extent=tas_extent, leadtime=[1, 2], system="51", product_type=p)
    @test mname("monthly_mean") != mname("ensemble_mean")
    @test occursin("ensemble_mean", mname("ensemble_mean"))

    @test RasterDataSources.date_step(SEAS5) == Month(1)
    @test RasterDataSources.getraster_keywords(SEAS5Monthly) == (:date, :extent, :leadtime, :product_type, :system)

    @test_throws ArgumentError getraster(SEAS5; date=Date(2026, 9, 1), extent=tas_extent)
    # Invalid options and extents must error before any credential lookup or request.
    @test_throws ArgumentError getraster(SEAS5, "2m_temperature"; date=Date(2026, 9, 1), extent=tas_extent, leadtime=7)
    @test_throws ArgumentError getraster(SEAS5Monthly, "2m_temperature"; date=Date(2026, 9, 1), extent=tas_extent, product_type="bogus")
    @test_throws ArgumentError getraster(SEAS5, "2m_temperature";
        date=Date(2026, 9, 1), extent=Extent(X=(149.0, 143.0), Y=(-44.0, -40.0)))

    # A valid cached file short-circuits the request entirely -- no credentials
    # needed. Uses an HDF5 signature so `_check_netcdf` accepts it.
    mktempdir() do dir
        withenv("RASTERDATASOURCES_PATH" => dir, "CDSAPI_KEY" => nothing, "HOME" => dir, "USERPROFILE" => dir) do
            path = rasterpath(SEAS5, vars; date=Date(2026, 9, 1), extent=tas_extent, leadtime=collect(24:24:5160), system="51")
            mkpath(dirname(path))
            write(path, UInt8[0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a])
            @test getraster(SEAS5, "2m_temperature"; date=Date(2026, 9, 1), extent=tas_extent) == path
            paths = getraster(SEAS5, ["2m_temperature"]; date=(Date(2026, 9, 1), Date(2026, 9, 1)), extent=tas_extent)
            @test paths == [path]
        end
    end

    # Network access requires a CDS API token -- request/path construction
    # only, no download.
end
