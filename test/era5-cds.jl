using RasterDataSources, URIs, Extents, Test, Dates, JSON
using RasterDataSources: rastername, rasterpath, _cds_area, _cds_request_body, _cds_dataset_id,
    _normalize_cds_variables, _extent_tag, _cds_result_href, _validate_cds_extent, _cds_credentials

@testset "ERA5{SingleLevels,CDS} / ERA5{Land,CDS}" begin

    tas_extent = Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))

    @test _cds_dataset_id(ERA5{SingleLevels,CDS}) == "reanalysis-era5-single-levels"
    @test _cds_dataset_id(ERA5{Land,CDS}) == "reanalysis-era5-land"

    @test _cds_area(tas_extent) == [-40.0, 143.0, -44.0, 149.0]

    body = _cds_request_body(ERA5{Land,CDS}, ("2m_temperature", "total_precipitation"), Date(2020, 2, 1), tas_extent)
    inputs = body["inputs"]
    @test inputs["variable"] == ["2m_temperature", "total_precipitation"]
    @test inputs["year"] == ["2020"]
    @test inputs["month"] == ["02"]
    @test inputs["day"] == [lpad(d, 2, '0') for d in 1:29] # 2020 is a leap year
    @test length(inputs["time"]) == 24
    @test inputs["time"][1] == "00:00"
    @test inputs["time"][end] == "23:00"
    @test inputs["area"] == [-40.0, 143.0, -44.0, 149.0]
    @test inputs["data_format"] == "netcdf"
    @test !haskey(inputs, "product_type")

    body2 = _cds_request_body(ERA5{SingleLevels,CDS}, ("2m_temperature",), Date(2021, 1, 1), tas_extent)
    @test body2["inputs"]["product_type"] == "reanalysis"

    @test rasterpath(ERA5{SingleLevels,CDS}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "CDS-ERA5")
    @test rasterpath(ERA5{Land,CDS}) == joinpath(ENV["RASTERDATASOURCES_PATH"], "CDS-ERA5-Land")

    name1 = rastername(ERA5{Land,CDS}, ("2m_temperature",); date=Date(2020, 2, 1), extent=tas_extent)
    name2 = rastername(ERA5{Land,CDS}, ("2m_temperature", "total_precipitation"); date=Date(2020, 2, 1), extent=tas_extent)
    @test name1 != name2 # different variable sets must not collide on disk
    @test occursin("202002", name1)
    @test endswith(name1, ".nc")

    @test RasterDataSources.getraster_keywords(ERA5{Land,CDS}) == (:date, :extent)
    @test RasterDataSources.date_step(ERA5{Land,CDS}) == Month(1)

    @test_throws ArgumentError getraster(ERA5{Land,CDS}; date=Date(2020, 2, 1), extent=tas_extent)

    # Same variables, different input order/type/duplicates -> identical
    # normalized tuple -> identical cache path.
    @test _normalize_cds_variables(("tp", "t2m")) == _normalize_cds_variables(("t2m", "tp"))
    name3 = rastername(ERA5{Land,CDS}, _normalize_cds_variables(("tp", "t2m")); date=Date(2020, 2, 1), extent=tas_extent)
    name4 = rastername(ERA5{Land,CDS}, _normalize_cds_variables(("t2m", "tp")); date=Date(2020, 2, 1), extent=tas_extent)
    @test name3 == name4
    @test _normalize_cds_variables((:t2m, "t2m", "t2m")) == ("t2m",) # Symbol + dupes collapse to one
    @test_throws ArgumentError _normalize_cds_variables(())
    @test_throws ArgumentError _normalize_cds_variables(String[])
    @test_throws ArgumentError _normalize_cds_variables((1, 2))

    # Reversed bounds must error, not silently build a nonsensical area/path.
    @test_throws ArgumentError _extent_tag(Extent(X=(149.0, 143.0), Y=(-44.0, -40.0)))
    @test_throws ArgumentError getraster(ERA5{Land,CDS}, "2m_temperature";
        date=Date(2020, 2, 1), extent=Extent(X=(149.0, 143.0), Y=(-44.0, -40.0)))

    # Out-of-range/non-finite coordinates must error too (an antimeridian
    # crossing, e.g. X=(170,-170), is already caught by the reversed-bounds check).
    @test_throws ArgumentError _validate_cds_extent(Extent(X=(200.0, 210.0), Y=(-10.0, 10.0)))
    @test_throws ArgumentError _validate_cds_extent(Extent(X=(1.0, 2.0), Y=(-100.0, -10.0)))
    @test_throws ArgumentError _validate_cds_extent(Extent(X=(NaN, 2.0), Y=(-10.0, 10.0)))

    # Rounding-adjacent extents must not collide onto the same cache tag.
    near1 = Extent(X=(143.00001, 149.0), Y=(-44.0, -40.0))
    near2 = Extent(X=(143.00002, 149.0), Y=(-44.0, -40.0))
    @test _extent_tag(near1) != _extent_tag(near2)

    @test_throws ArgumentError _normalize_cds_variables(("",))
    @test_throws ArgumentError _normalize_cds_variables(("  ",))

    # Regression: `JSON.parse` output here is a `JSON.Object`, not a
    # `Base.Dict` -- a `body::Dict`-typed `_cds_result_href` passed hand-built
    # `Dict` tests but raised a `MethodError` on a real parsed response.
    # Run through the actual parser, not a hand-built `Dict`, to catch that.
    @test _cds_result_href(JSON.parse("""{"location": "https://example.com/f.nc"}""")) ==
        "https://example.com/f.nc"
    @test _cds_result_href(JSON.parse("""{"asset": {"value": {"href": "https://example.com/g.nc"}}}""")) ==
        "https://example.com/g.nc"
    @test_throws ErrorException _cds_result_href(JSON.parse("""{"other": 1}"""))
    @test_throws ErrorException _cds_result_href(JSON.parse("""{"asset": {"value": {}}}"""))

    # ENV and the `.cdsapirc` file are overridden independently: an env key
    # with no env URL must still pick up the file's URL, not fall back to the
    # package default.
    mktempdir() do dir
        write(joinpath(dir, ".cdsapirc"), "url: https://example.com/custom\nkey: filekey\n")
        withenv("HOME" => dir, "USERPROFILE" => dir, "CDSAPI_KEY" => "envkey", "CDSAPI_URL" => nothing) do
            creds = _cds_credentials()
            @test creds.key == "envkey"
            @test creds.url == "https://example.com/custom"
        end
    end

    # Network access requires a CDS API token -- request/path construction
    # only, no download.
end
