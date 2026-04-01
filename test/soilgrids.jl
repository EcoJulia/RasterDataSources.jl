using RasterDataSources, URIs, Test
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

    # Filenames
    @test rastername(SoilGrids, :clay; depth="0-5cm", quantile="mean") == "clay_0-5cm_mean.vrt"
    @test rastername(SoilGrids, :ocs; depth="0-30cm", quantile="Q0.05") == "ocs_0-30cm_Q0.05.vrt"
    @test rastername(SoilGrids, :sand; depth="15-30cm", quantile="Q0.95") == "sand_15-30cm_Q0.95.vrt"

    # Paths
    @test rasterpath(SoilGrids) == soilgrids_path
    clay_path = joinpath(soilgrids_path, "clay", "clay_0-5cm_mean.vrt")
    @test rasterpath(SoilGrids, :clay; depth="0-5cm", quantile="mean") == clay_path

    # URLs
    @test rasterurl(SoilGrids, :clay; depth="0-5cm", quantile="mean") ==
        URI(scheme="https", host="files.isric.org",
            path="/soilgrids/latest/data/clay/clay_0-5cm_mean.vrt")
    @test rasterurl(SoilGrids, :ocs; depth="0-30cm", quantile="Q0.05") ==
        URI(scheme="https", host="files.isric.org",
            path="/soilgrids/latest/data/ocs/ocs_0-30cm_Q0.05.vrt")

    # Validation errors
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-30cm", quantile="mean")
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-5cm", quantile="Q0.99")
    @test_throws ArgumentError getraster(SoilGrids, :not_a_layer; depth="0-5cm", quantile="mean")

    # Download — single layer
    path = getraster(SoilGrids, :clay; depth="0-5cm", quantile="mean")
    @test path == clay_path
    @test isfile(path)

    # Download — Tuple → NamedTuple
    result = getraster(SoilGrids, (:clay, :sand); depth="0-5cm", quantile="mean")
    @test result isa NamedTuple
    @test haskey(result, :clay)
    @test haskey(result, :sand)
    @test isfile(result.clay)
    @test isfile(result.sand)

    # Download — array of depths → Vector
    result = getraster(SoilGrids, :clay; depth=["0-5cm", "5-15cm"], quantile="mean")
    @test result isa AbstractVector
    @test length(result) == 2
    @test all(isfile, result)

    # ocs uses its own default depth
    ocs_path = getraster(SoilGrids, :ocs; quantile="mean")
    @test endswith(ocs_path, "ocs_0-30cm_mean.vrt")
    @test isfile(ocs_path)

    # Keywords trait
    @test RasterDataSources.getraster_keywords(SoilGrids) == (:depth, :quantile)
end
