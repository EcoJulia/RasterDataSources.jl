using RasterDataSources, Test
using RasterDataSources: rasterpath, layername, layers

@testset "ERA5{Google,ARCO}" begin
    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "Google", "ARCO")
    @test rasterpath(ERA5{Google,ARCO}) == era5_path

    @test length(layers(ERA5{Google,ARCO})) == 262
    @test :temperature_2m in layers(ERA5{Google,ARCO})
    @test :total_precipitation in layers(ERA5{Google,ARCO})

    @test layername(ERA5{Google,ARCO}, :temperature_2m) == "2m_temperature"
    @test layername(ERA5{Google,ARCO}, :geopotential_at_surface) == "geopotential_at_surface"
    @test layername(ERA5{Google,ARCO}, :snow_depth_water_equivalent) == "snow_depth"

    source = getraster(ERA5{Google,ARCO})
    @test source isa CachedCloudSource
    @test source.url == "https://storage.googleapis.com/gcp-public-data-arco-era5/ar/full_37-1h-0p25deg-chunk-1.zarr-v3"
    @test source.cache == era5_path
    @test isdir(source.cache)
    @test getraster(ERA5) == source
    @test layers(ERA5) == layers(ERA5{Google,ARCO})
    @test layername(ERA5, :total_precipitation) == "total_precipitation"
    @test_throws MethodError getraster(ERA5{Google,ARCO,Land})
end
