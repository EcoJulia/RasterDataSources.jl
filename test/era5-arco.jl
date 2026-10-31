using RasterDataSources, URIs, Test
using RasterDataSources: rasterpath, layers, getraster_keywords, _ecmwf_arco_group_url, _check_arco_chunking

@testset "ERA5{ECMWF} / ERA5{ECMWF,Land}" begin

    @test layers(ERA5{ECMWF}) == (:sfc, :wav)
    @test :sfc_2m_temperature in layers(ERA5{ECMWF,Land})
    @test length(layers(ERA5{ECMWF,Land})) == 8

    @test getraster_keywords(ERA5{ECMWF}) == (:chunking,)
    @test getraster_keywords(ERA5{ECMWF,Land}) == (:chunking,)

    @test _ecmwf_arco_group_url(ERA5{ECMWF}, :sfc) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-002/arco/reanalysis_era5_single_levels/sfc/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF}, :sfc; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-002/arco/reanalysis_era5_single_levels/sfc/timeChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF}, :wav) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-003/arco/reanalysis_era5_single_levels/wav/geoChunked.zarr")

    @test _ecmwf_arco_group_url(ERA5{ECMWF,Land}, :sfc_2m_temperature) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-007/arco/reanalysis_era5_land/sfc-2m-temperature/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{ECMWF,Land}, :sfc_skin_temperature; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-043/arco/reanalysis_era5_land/sfc-skin-temperature/timeChunked.zarr")

    @test_throws Exception _ecmwf_arco_group_url(ERA5{ECMWF}, :not_a_group)
    @test_throws ArgumentError _check_arco_chunking(:bogus)

    @test_throws ArgumentError getraster(ERA5{ECMWF}, :sfc; chunking=:bogus)

    @test_throws ArgumentError getraster(ERA5{ECMWF})
    @test_throws ArgumentError getraster(ERA5{ECMWF}; chunking=:geo)

    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ECMWF-ARCO-ERA5")
    @test rasterpath(ERA5{ECMWF}) == era5_path
    land_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ECMWF-ARCO-ERA5-Land")
    @test rasterpath(ERA5{ECMWF,Land}) == land_path

    geo_path = rasterpath(ERA5{ECMWF,Land}, :sfc_2m_temperature; chunking=:geo)
    time_path = rasterpath(ERA5{ECMWF,Land}, :sfc_2m_temperature; chunking=:time)
    @test geo_path != time_path
    @test occursin("geo", geo_path)
    @test occursin("time", time_path)

    source = getraster(ERA5{ECMWF,Land}, :sfc_2m_temperature)
    @test source.url == string(_ecmwf_arco_group_url(ERA5{ECMWF,Land}, :sfc_2m_temperature))
    @test source.cache == geo_path
    @test isdir(source.cache)

    sources = getraster(ERA5{ECMWF,Land}, (:sfc_2m_temperature, :sfc_wind))
    @test sources isa NamedTuple
    @test keys(sources) == (:sfc_2m_temperature, :sfc_wind)
    @test all(s -> s isa CachedCloudSource, sources)
end
