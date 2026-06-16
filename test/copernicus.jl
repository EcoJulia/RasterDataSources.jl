
using RasterDataSources, URIs, Test, Extents
using RasterDataSources: rasterpath, rasterurl, rastername, resolutions, defres,
    bounds_to_tile_indices, _cop_row, _cop_col

@testset "CopernicusDEM" begin
    @test resolutions(CopernicusDEM) == ("30m", "90m")
    @test defres(CopernicusDEM) == "30m"
    @test RasterDataSources.getraster_keywords(CopernicusDEM) ==
        (:bounds, :extent, :tile_index, :res)

    # N42 E011 (Italy), addressed by the south-west corner of the 1°×1° tile.
    tile_index = CartesianIndex(_cop_row(42), _cop_col(11))

    @test rastername(CopernicusDEM; tile_index) == "Copernicus_DSM_COG_10_N42_00_E011_00_DEM.tif"
    @test rastername(CopernicusDEM; tile_index, res="90m") == "Copernicus_DSM_COG_30_N42_00_E011_00_DEM.tif"

    url30 = URI(scheme="https", host="copernicus-dem-30m.s3.amazonaws.com",
        path="/Copernicus_DSM_COG_10_N42_00_E011_00_DEM/Copernicus_DSM_COG_10_N42_00_E011_00_DEM.tif")
    @test rasterurl(CopernicusDEM; tile_index) == url30
    @test rasterurl(CopernicusDEM; tile_index, res="90m").host == "copernicus-dem-90m.s3.amazonaws.com"

    # Resolution lives in its own subdirectory of the cache.
    @test rasterpath(CopernicusDEM; tile_index) ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "CopernicusDEM", "30m", "Copernicus_DSM_COG_10_N42_00_E011_00_DEM.tif")
    @test rasterpath(CopernicusDEM; tile_index, res="90m") ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "CopernicusDEM", "90m", "Copernicus_DSM_COG_30_N42_00_E011_00_DEM.tif")
    # With no spatial keyword, the (non-getraster) accessors return the cache directory.
    @test rasterpath(CopernicusDEM; res="90m") ==
        joinpath(ENV["RASTERDATASOURCES_PATH"], "CopernicusDEM", "90m")

    # Southern/western hemisphere naming.
    tile_sw = CartesianIndex(_cop_row(-34), _cop_col(-59))
    @test rastername(CopernicusDEM; tile_index=tile_sw) == "Copernicus_DSM_COG_10_S34_00_W059_00_DEM.tif"

    # Bounds/extent map to a block of tiles. The Tyrrhenian-Sea tile (N41 E010)
    # does not exist in the dataset and comes back as `missing`.
    ext = Extent(X=(10.5, 11.5), Y=(41.5, 42.5))
    @test bounds_to_tile_indices(CopernicusDEM, ext) ==
        bounds_to_tile_indices(CopernicusDEM, ((10.5, 11.5), (41.5, 42.5)))
    names = rastername(CopernicusDEM; extent=ext)
    @test size(names) == (2, 2)
    @test names[1, 2] == "Copernicus_DSM_COG_10_N42_00_E011_00_DEM.tif"
    @test ismissing(names[2, 1])
    # `bounds` is the legacy alias for `extent`.
    @test isequal(rastername(CopernicusDEM; bounds=ext), names)

    # The Caucasus tile N40 E045 exists only at 90m resolution.
    tile_cauc = CartesianIndex(_cop_row(40), _cop_col(45))
    @test ismissing(rastername(CopernicusDEM; tile_index=tile_cauc:tile_cauc)[1])
    @test rastername(CopernicusDEM; tile_index=tile_cauc:tile_cauc, res="90m")[1] ==
        "Copernicus_DSM_COG_30_N40_00_E045_00_DEM.tif"

    # Argument validation.
    @test_throws ArgumentError rastername(CopernicusDEM; tile_index, res="20m")
    @test_throws ArgumentError getraster(CopernicusDEM)
    @test_throws ArgumentError getraster(CopernicusDEM; extent=ext, bounds=ext)

    # Real download of a single small 90m tile.
    path = getraster(CopernicusDEM; bounds=((11.2, 11.4), (42.2, 42.4)), res="90m")
    file = first(skipmissing(path))
    @test isfile(file)
    @test rasterpath(CopernicusDEM; tile_index, res="90m") == file
end
