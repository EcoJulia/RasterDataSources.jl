using RasterDataSources, Test
using RasterDataSources: rasterpath, layername, layers, CachedCloudSource

@testset "ERA5" begin
    # Test rasterpath returns the cache directory
    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "arco-era5-zarr")
    @test rasterpath(ERA5) == era5_path

    # Test layers returns available layer symbols
    @test :t2m in layers(ERA5)
    @test :sp in layers(ERA5)
    @test :tp in layers(ERA5)

    # Test layername converts symbols to ARCO-ERA5 variable names
    @test layername(ERA5, :t2m) == "2m_temperature"
    @test layername(ERA5, :sp) == "surface_pressure"
    @test layername(ERA5, :tp) == "total_precipitation"

    # Test getraster returns a CachedCloudSource
    source = getraster(ERA5)
    @test source isa CachedCloudSource
    @test source.url == "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"
    @test source.cache == era5_path
    @test isdir(source.cache)
end
