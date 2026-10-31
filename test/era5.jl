using RasterDataSources, Test
using RasterDataSources: rasterpath, layername, layers

@testset "ERA5{GoogleARCO}" begin
    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "arco-era5-zarr")
    @test rasterpath(ERA5{GoogleARCO}) == era5_path

    @test :t2m in layers(ERA5{GoogleARCO})
    @test :sp in layers(ERA5{GoogleARCO})
    @test :tp in layers(ERA5{GoogleARCO})

    @test layername(ERA5{GoogleARCO}, :t2m) == "2m_temperature"
    @test layername(ERA5{GoogleARCO}, :sp) == "surface_pressure"
    @test layername(ERA5{GoogleARCO}, :tp) == "total_precipitation"

    source = getraster(ERA5{GoogleARCO})
    @test source isa CachedCloudSource
    @test source.url == "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"
    @test source.cache == era5_path
    @test isdir(source.cache)
    @test getraster(ERA5{GoogleARCO,SingleLevels}) == source
    @test_throws MethodError getraster(ERA5{GoogleARCO,Land})
end
