using RasterDataSources, Extents, Test

@testset verbose = true "MODIS Extent support" begin
    @testset "latlon_to_meters round-trips meters_to_latlon" begin
        for lat in (0.0, 45.0), d in (1_000, 50_000, 100_000)
            dlat, dlon = RasterDataSources.meters_to_latlon(d, lat)
            m_lat, m_lon = RasterDataSources.latlon_to_meters(dlat, dlon, lat)
            @test m_lat ≈ d rtol = 1e-6
            @test m_lon ≈ d rtol = 1e-6
        end
    end

    @testset "extent_to_modis_params" begin
        # Square ~100km around Crozon (48.24°N, -4.5°E)
        dlat, dlon = RasterDataSources.meters_to_latlon(50_000, 48.24)
        ext = Extent(X=(-4.5 - dlon, -4.5 + dlon), Y=(48.24 - dlat, 48.24 + dlat))
        p = RasterDataSources.extent_to_modis_params(ext)
        @test p.lat ≈ 48.24 atol=1e-6
        @test p.lon ≈ -4.5 atol=1e-6
        @test p.km_ab == 50
        @test p.km_lr == 50
    end

    @testset "getraster routes extent kw" begin
        @test :extent in RasterDataSources.getraster_keywords(MODIS)
        @test :extent in RasterDataSources.getraster_keywords(MOD13Q1)
        # Missing required kwargs (no extent and no coords) errors before any download
        @test_throws ArgumentError getraster(MOD13Q1, :NDVI;
            lon=-4.0, km_ab=1, km_lr=1, date="2012-02-02")
    end
end
