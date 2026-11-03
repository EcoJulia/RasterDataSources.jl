import Proj
using RasterDataSources, URIs, Extents, Test
using RasterDataSources: rastername, rasterpath, rasterurl, layers, depths, _vrt_tiles, _tile_extents

@testset "SoilGrids" begin
    soilgrids_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SoilGrids")
    @test rasterpath(SoilGrids) == soilgrids_path

    @test length(layers(SoilGrids)) == 11
    @test depths(SoilGrids) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
    @test RasterDataSources.getraster_keywords(SoilGrids) == (:extent, :depth, :component)

    @test rasterpath(SoilGrids, :clay; depth="0-5cm", component="mean") ==
        joinpath(soilgrids_path, "clay", "clay_0-5cm_mean")
    @test rasterpath(SoilGrids, :ocs; depth="5-15cm", component="mean") ==
        joinpath(soilgrids_path, "ocs", "ocs_0-30cm_mean")
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-5cm")
    @test_throws ArgumentError getraster(SoilGrids, :clay; depth="0-30cm", extent=Extent(X=(0, 1), Y=(0, 1)))
    @test_throws ArgumentError getraster(SoilGrids, :clay; component="Q0.99", extent=Extent(X=(0, 1), Y=(0, 1)))
    @test_throws ArgumentError getraster(SoilGrids, :wrb; extent=Extent(X=(0, 1), Y=(0, 1)))

    # Two tiles from the clay_0-5cm_mean index: Melbourne, and one partly outside the
    # projection at 180° longitude.
    vrt = """
    <VRTDataset rasterXSize="159246" rasterYSize="58034">
      <GeoTransform> -1.9949750000000000e+07,  2.5000000000000000e+02,  0.0000000000000000e+00,  8.3610000000000000e+06,  0.0000000000000000e+00, -2.5000000000000000e+02</GeoTransform>
      <VRTRasterBand dataType="Int16" band="1">
        <ComplexSource>
          <SourceFilename relativeToVRT="1">./clay_0-5cm_mean/tileSG-028-080/tileSG-028-080_2-1.tif</SourceFilename>
          <DstRect xOff="143649" yOff="49891" xSize="450" ySize="450" />
        </ComplexSource>
        <ComplexSource>
          <SourceFilename relativeToVRT="1">./clay_0-5cm_mean/tileSG-023-000/tileSG-023-000_2-1.tif</SourceFilename>
          <DstRect xOff="29" yOff="40891" xSize="70" ySize="106" />
        </ComplexSource>
      </VRTRasterBand>
    </VRTDataset>
    """
    melbourne, edge = _tile_extents(_vrt_tiles(vrt))
    @test first(melbourne) == "tileSG-028-080/tileSG-028-080_2-1.tif"
    @test Extents.intersects(last(melbourne), Extent(X=(145.0, 145.0), Y=(-37.8, -37.8)))
    @test all(isfinite, (last(edge).X..., last(edge).Y...))

    extent = Extent(X=(144.9, 145.1), Y=(-37.9, -37.7))
    tile = "tileSG-028-080_2-1.tif"
    tile_path = joinpath(soilgrids_path, "clay", "clay_0-5cm_mean", "tileSG-028-080", tile)
    @test rastername(SoilGrids, :clay; extent, depth="0-5cm", component="mean") == [tile]
    @test rasterpath(SoilGrids, :clay; extent, depth="0-5cm", component="mean") == [tile_path]
    @test rasterurl(SoilGrids, :clay; extent, depth="0-5cm", component="mean") ==
        [URI("https://files.isric.org/soilgrids/latest/data/clay/clay_0-5cm_mean/tileSG-028-080/$tile")]
    @test rastername(SoilGrids, :clay; extent=Extent(X=(-30.0, -29.0), Y=(0.0, 1.0)), depth="0-5cm", component="mean") == []

    @test getraster(SoilGrids, :clay; extent) == [tile_path]
    @test isfile(tile_path)
end
