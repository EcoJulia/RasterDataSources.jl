import Proj
using RasterDataSources, URIs, Extents, Test
using RasterDataSources: rastername, rasterpath, rasterurl, layers

@testset "SoilGrids" begin
    soilgrids_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SoilGrids")

    # Layers
    @test :clay in layers(SoilGrids)
    @test :ocs in layers(SoilGrids)
    @test length(layers(SoilGrids)) == 11

    # Depths
    @test depths(SoilGrids) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
    @test depths(SoilGrids, :clay) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
    @test depths(SoilGrids, :ocs) == ("0-30cm",)

    @test rasterpath(SoilGrids) == soilgrids_path
    @test RasterDataSources.getraster_keywords(SoilGrids) == (:extent, :depth, :quantile)

    # Validation errors — checked before `extent` is required, so no network access.
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-30cm", quantile="mean")
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-5cm", quantile="Q0.99")
    @test_throws ArgumentError getraster(SoilGrids, :not_a_layer; depth="0-5cm", quantile="mean")

    # `extent` is required — SoilGrids is a global 250 m dataset.
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-5cm", quantile="mean")

    # A small extent that resolves to a single real tile.
    extent = Extent(X=(144.9, 145.1), Y=(-37.9, -37.7))
    tile_name = "tileSG-028-080_2-1.tif"

    # Introspection — no download of the tile itself, only the small index VRT.
    @test rastername(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean") == [tile_name]
    tile_path = joinpath(soilgrids_path, "clay", "clay_0-5cm_mean", "tileSG-028-080", tile_name)
    @test rasterpath(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean") == [tile_path]
    @test rasterurl(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean") ==
        [URI(scheme="https", host="files.isric.org",
            path="/soilgrids/latest/data/clay/clay_0-5cm_mean/tileSG-028-080/$tile_name")]

    # Download — single layer, real tile data cached locally.
    paths = getraster(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean")
    @test paths == [tile_path]
    @test isfile(tile_path)

    # Second call is served entirely from the local cache (no re-download).
    @test getraster(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean") == paths

    # Download — Tuple → NamedTuple of Vectors
    result = getraster(SoilGrids, (:clay, :sand); extent, depth="0-5cm", quantile="mean")
    @test result isa NamedTuple
    @test haskey(result, :clay)
    @test haskey(result, :sand)
    @test all(isfile, result.clay)
    @test all(isfile, result.sand)

    # Download — array of depths → Vector of Vectors
    result = getraster(SoilGrids, :clay; extent, depth=["0-5cm", "5-15cm"], quantile="mean")
    @test result isa AbstractVector
    @test length(result) == 2
    @test all(paths -> all(isfile, paths), result)

    # ocs uses its own default depth
    ocs_paths = getraster(SoilGrids, :ocs; extent, quantile="mean")
    @test only(ocs_paths) |> isfile
    @test endswith(only(ocs_paths), tile_name)
end
