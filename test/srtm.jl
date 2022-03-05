
using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rasterpath, zipurl, zipname

@testset "SRTM" begin

    zip_url = URI(scheme = "https", host = "srtm.csi.cgiar.org", path = "/wp-content/uploads/files/srtm_5x5/TIFF/srtm_01_02.zip")
    tile_index1 = CartesianIndex(2, 1)   # [y, x] order
    tile_index2 = CartesianIndex(2, 2)   # [y, x] order
    @test zipurl(SRTM; tile_index = tile_index1) == zip_url
    @test zipurl(SRTM; tile_index = tile_index1) == zip_url
    @test zipname(SRTM; tile_index = tile_index1) == "srtm_01_02.zip"

    raster_path1 = joinpath(ENV["RASTERDATASOURCES_PATH"], "SRTM", "srtm_01_02.tif")
    raster_path2 = joinpath(ENV["RASTERDATASOURCES_PATH"], "SRTM", "srtm_02_02.tif")
    @test rasterpath(SRTM; tile_index = tile_index1) == raster_path1
    @test getraster(SRTM; tile_index = tile_index1) == raster_path1
    @test isfile(raster_path1)

    lon1, lat1 = -180, 55       # Coordinates of [0, 0] pixel of tile x=1, y=2
    @test 
    getraster(SRTM; bounds=(lon1, lat1, lon1, lat1))
    == reshape([raster_path1], 1, 1)
    lon2, lat2 = -172.5, 52.5   # Coordinates of [3000, 3000] pixel of tile x=2, y=2
    @test getraster(SRTM; bounds=(lon1, lat1, lon2, lat2)) == reshape([raster_path1, raster_path2], 1, 2)
end
