using RasterDataSources, URIs, Test
using RasterDataSources: rasterpath, layers, layername, getraster_keywords, _ecmwf_arco_group_url, _check_arco_chunking

@testset "ERA5{ECMWF,ARCO} / ERA5{ECMWF,ARCO,Land}" begin
    @test length(layers(ERA5{ECMWF,ARCO})) == 23
    @test length(layers(ERA5{ECMWF,ARCO,Land})) == 20
    @test :temperature_2m in layers(ERA5{ECMWF,ARCO,Land})
    @test all(in(layers(ERA5{ECMWF,CDS})), layers(ERA5{ECMWF,ARCO}))
    @test all(in(layers(ERA5{ECMWF,CDS,Land})), layers(ERA5{ECMWF,ARCO,Land}))

    @test layername(ERA5{ECMWF,ARCO}, :temperature_2m) == "t2m"
    @test layername(ERA5{ECMWF,ARCO,Land}, :snow_depth) == "sde"

    @test getraster_keywords(ERA5{ECMWF,ARCO}) == (:chunking,)
    @test getraster_keywords(ERA5{ECMWF,ARCO,Land}) == (:chunking,)

    @test _ecmwf_arco_group_url(ERA5{ECMWF,ARCO}, :temperature_2m) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-002/arco/reanalysis_era5_single_levels/sfc/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF,ARCO}, :temperature_2m; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-002/arco/reanalysis_era5_single_levels/sfc/timeChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF,ARCO}, :mean_wave_period) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-003/arco/reanalysis_era5_single_levels/wav/geoChunked.zarr")

    @test _ecmwf_arco_group_url(ERA5{ECMWF,ARCO,Land}, :temperature_2m) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-007/arco/reanalysis_era5_land/sfc-2m-temperature/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF,ARCO,Land}, :skin_temperature; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-043/arco/reanalysis_era5_land/sfc-skin-temperature/timeChunked.zarr")

    @test_throws ArgumentError getraster(ERA5{ECMWF,ARCO}, :not_a_layer)
    @test_throws ArgumentError getraster(ERA5{ECMWF,ARCO,Land}, :total_cloud_cover)
    @test_throws ArgumentError _check_arco_chunking(:bogus)
    @test_throws ArgumentError getraster(ERA5{ECMWF,ARCO}, :temperature_2m; chunking=:bogus)

    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "ARCO")
    @test rasterpath(ERA5{ECMWF,ARCO}) == era5_path
    land_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ERA5", "ECMWF", "ARCO", "Land")
    @test rasterpath(ERA5{ECMWF,ARCO,Land}) == land_path

    geo_path = rasterpath(ERA5{ECMWF,ARCO,Land}, :temperature_2m; chunking=:geo)
    @test geo_path == joinpath(land_path, "sfc-2m-temperature", "geo")
    @test rasterpath(ERA5{ECMWF,ARCO,Land}, :temperature_2m; chunking=:time) == joinpath(land_path, "sfc-2m-temperature", "time")

    source = getraster(ERA5{ECMWF,ARCO,Land}, :temperature_2m)
    @test source.url == string(_ecmwf_arco_group_url(ERA5{ECMWF,ARCO,Land}, :temperature_2m))
    @test source.cache == geo_path
    @test isdir(source.cache)
    @test getraster(ERA5{ECMWF,ARCO,Land}, :dewpoint_temperature_2m) == source

    sources = getraster(ERA5{ECMWF,ARCO,Land}, (:temperature_2m, :snowfall))
    @test keys(sources) == (:temperature_2m, :snowfall)
    @test all(s -> s isa CachedCloudSource, sources)
    @test keys(getraster(ERA5{ECMWF,ARCO})) == layers(ERA5{ECMWF,ARCO})
end
