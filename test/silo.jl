using RasterDataSources, URIs, Test, Dates
using RasterDataSources: rastername, rasterurl, rasterpath

@testset "SILO" begin

    silo_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SILO")
    @test rasterpath(SILO) == silo_path

    @test rastername(SILO, :daily_rain; date=Date(2020, 6, 15)) == "2020.daily_rain.nc"
    @test rastername(SILO, :max_temp;  date=Date(1979, 1, 1))  == "1979.max_temp.nc"

    @test rasterpath(SILO, :daily_rain; date=Date(2020, 6, 15)) ==
        joinpath(silo_path, "daily_rain", "2020.daily_rain.nc")

    @test rasterurl(SILO, :daily_rain; date=Date(2020)) ==
        URI(scheme="https", host="s3-ap-southeast-2.amazonaws.com",
            path="/silo-open-data/Official/annual/daily_rain/2020.daily_rain.nc")

    @test RasterDataSources.getraster_keywords(SILO) == (:date,)
    @test RasterDataSources.layers(SILO) == (
        :daily_rain, :et_morton_actual, :et_morton_potential,
        :et_morton_wet, :et_short_crop, :et_tall_crop, :evap_morton_lake, :evap_pan,
        :evap_syn, :max_temp, :min_temp, :monthly_rain, :mslp, :radiation, :rh_tmax,
        :rh_tmin, :vp, :vp_deficit,
    )
    @test RasterDataSources.date_step(SILO) == Year(1)

    @testset "shorter-coverage variables reject dates before their start year" begin
        @test_throws ArgumentError getraster(SILO, :mslp; date=Date(1950))
        @test_throws ArgumentError getraster(SILO, :evap_pan; date=Date(1965))
    end

    if !Sys.iswindows()
        # monthly_rain is ~14 MB, small enough to actually download in CI.
        # The other layers are annual files of daily data (~400 MB each), so
        # only path/name/url construction is tested for those, above.
        raster_path = joinpath(silo_path, "monthly_rain", "2020.monthly_rain.nc")
        @test getraster(SILO, :monthly_rain; date=Date(2020, 1, 1)) == raster_path
        @test isfile(raster_path)
    end
end
