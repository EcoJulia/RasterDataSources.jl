
using RasterDataSources, URIs, Test, Dates, Extents
using RasterDataSources: rasterpath, zipurl, zipname

@testset "SRTM" begin
    zip_url = URI(scheme = "https", host = "srtm.csi.cgiar.org", path = "/wp-content/uploads/files/srtm_5x5/TIFF/srtm_02_01.zip")
    tile_index1 = CartesianIndex(1, 2)   # [y, x] order
    tile_index2 = CartesianIndex(2, 2)   # [y, x] order
    @test zipurl(SRTM; tile_index = tile_index1) == zip_url
    @test zipurl(SRTM; tile_index = tile_index1) == zip_url
    @test zipname(SRTM; tile_index = tile_index1) == "srtm_02_01.zip"

    raster_path1 = joinpath(ENV["RASTERDATASOURCES_PATH"], "SRTM", "srtm_02_01.tif")
    raster_path2 = joinpath(ENV["RASTERDATASOURCES_PATH"], "SRTM", "srtm_02_02.tif")
    @test rasterpath(SRTM; tile_index = tile_index1) == raster_path1
    @test getraster(SRTM; tile_index = tile_index1) == raster_path1
    @test isfile(raster_path1)

    lon1, lat1 = -175, 60       # Coordinates of [0, 0] pixel of tile x=2, y=1
    @test getraster(SRTM; bounds=((lon1, lon1), (lat1, lat1))) == reshape([raster_path1], 1, 1)
    lon2, lat2 = -171, 55   # Coordinates of [3000, 3000] pixel of tile x=2, y=2
    @test getraster(SRTM; bounds=((lon1, lon2), (lat2, lat1))) == permutedims([raster_path1 raster_path2])
    # `extent` is the canonical spatial keyword; `bounds` is the legacy alias.
    ext = Extent(X=(lon1, lon2), Y=(lat2, lat1))
    @test getraster(SRTM; extent=ext) == permutedims([raster_path1 raster_path2])
    @test getraster(SRTM; bounds=ext) == permutedims([raster_path1 raster_path2])
    @test RasterDataSources.bounds_to_tile_indices(SRTM, ext) ==
          RasterDataSources.bounds_to_tile_indices(SRTM, ((lon1, lon2), (lat2, lat1)))
    # Passing both `extent` and `bounds` together errors
    @test_throws ArgumentError getraster(SRTM; extent=ext, bounds=((lon1, lon2), (lat2, lat1)))

    @test RasterDataSources.getraster_keywords(SRTM) == (:bounds, :extent, :tile_index)
end
