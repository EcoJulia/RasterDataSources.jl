using RasterDataSources, URIs, Test
using RasterDataSources: rasterpath, layers, getraster_keywords, _ecmwf_arco_group_url, _check_arco_chunking

@testset "ERA5{SingleLevels,ECMWF} / ERA5{Land,ECMWF}" begin

    @test layers(ERA5{SingleLevels,ECMWF}) == (:sfc, :wav)
    @test :sfc_2m_temperature in layers(ERA5{Land,ECMWF})
    @test length(layers(ERA5{Land,ECMWF})) == 8

    @test getraster_keywords(ERA5{SingleLevels,ECMWF}) == (:chunking,)
    @test getraster_keywords(ERA5{Land,ECMWF}) == (:chunking,)

    @test _ecmwf_arco_group_url(ERA5{SingleLevels,ECMWF}, :sfc) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-002/arco/reanalysis_era5_single_levels/sfc/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{SingleLevels,ECMWF}, :sfc; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-002/arco/reanalysis_era5_single_levels/sfc/timeChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{SingleLevels,ECMWF}, :wav) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-003/arco/reanalysis_era5_single_levels/wav/geoChunked.zarr")

    @test _ecmwf_arco_group_url(ERA5{Land,ECMWF}, :sfc_2m_temperature) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-geo-007/arco/reanalysis_era5_land/sfc-2m-temperature/geoChunked.zarr")
    @test _ecmwf_arco_group_url(ERA5{Land,ECMWF}, :sfc_skin_temperature; chunking=:time) ==
        URI(scheme="https", host="arco.datastores.ecmwf.int",
            path="/cadl-arco-time-043/arco/reanalysis_era5_land/sfc-skin-temperature/timeChunked.zarr")

    @test_throws Exception _ecmwf_arco_group_url(ERA5{SingleLevels,ECMWF}, :not_a_group)
    @test_throws ArgumentError _check_arco_chunking(:bogus)

    # Invalid chunking must be rejected before getraster does anything else
    # (in particular, before any cache directory could be created).
    @test_throws ArgumentError getraster(ERA5{SingleLevels,ECMWF}, :sfc; chunking=:bogus)

    # No topic group specified: must error, not silently fetch every group.
    @test_throws ArgumentError getraster(ERA5{SingleLevels,ECMWF})
    @test_throws ArgumentError getraster(ERA5{SingleLevels,ECMWF}; chunking=:geo)

    era5_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ECMWF-ARCO-ERA5")
    @test rasterpath(ERA5{SingleLevels,ECMWF}) == era5_path
    land_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "ECMWF-ARCO-ERA5-Land")
    @test rasterpath(ERA5{Land,ECMWF}) == land_path

    # geo- and time-chunked stores for the same group are different remote
    # data and must not share a cache directory (the bug the review caught).
    geo_path = rasterpath(ERA5{Land,ECMWF}, :sfc_2m_temperature; chunking=:geo)
    time_path = rasterpath(ERA5{Land,ECMWF}, :sfc_2m_temperature; chunking=:time)
    @test geo_path != time_path
    @test occursin("geo", geo_path)
    @test occursin("time", time_path)

    @test getraster(ERA5{Land,ECMWF}, :sfc_2m_temperature) ==
        string(_ecmwf_arco_group_url(ERA5{Land,ECMWF}, :sfc_2m_temperature))

    sources = getraster(ERA5{Land,ECMWF}, (:sfc_2m_temperature, :sfc_wind))
    @test sources isa NamedTuple
    @test keys(sources) == (:sfc_2m_temperature, :sfc_wind)
    @test all(s -> s isa String, sources)
end
