using RasterDataSources, Test
using RasterDataSources: rasterpath, layername, layers

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

    source = getraster(ERA5)
    @test source == "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"

    # Omitted parameters default to SingleLevels and GoogleARCO; ERA5-Land isn't on GoogleARCO
    @test getraster(ERA5{SingleLevels}) == getraster(ERA5{SingleLevels,GoogleARCO}) == source
    @test_throws ArgumentError getraster(ERA5{Land})
end
