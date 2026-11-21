using RasterDataSources, Test, Dates, Extents
using RasterDataSources: rasterpath, layername, layers

@testset "ERA5{Google,ARCO}" begin
    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "Google", "ARCO")
    @test rasterpath(ERA5{Google,ARCO}) == era5_path

    @test length(layers(ERA5{Google,ARCO})) == 262
    @test :temperature_2m in layers(ERA5{Google,ARCO})
    @test :total_precipitation in layers(ERA5{Google,ARCO})

    @test layername(ERA5{Google,ARCO}, :temperature_2m) == "2m_temperature"

    # Pre-v0.8 short names still work
    @test layername(ERA5, :t2m) == "2m_temperature"
    @test layername(ERA5, :tp) == "total_precipitation"
    @test layername(ERA5, :sd) == layername(ERA5, :snow_depth_water_equivalent)
    @test layername(ERA5{ECMWF,OnDemand}, :t2m) == "t2m"
    @test layername(ERA5{ECMWF,ARCO,Land}, :t2m) == "t2m"
    @test_throws ArgumentError getraster(ERA5{ECMWF,OnDemand}, :not_a_layer;
        date=Date(2020, 1, 1), extent=Extent(X=(145.0, 145.1), Y=(-37.9, -37.8)))
    arco_t2m = getraster(ERA5{ECMWF,ARCO}, :t2m)
    @test arco_t2m == getraster(ERA5{ECMWF,ARCO}, :temperature_2m)
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
