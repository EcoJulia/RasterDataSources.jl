using GeoData, RasterDataSources, Test, Dates, NCDatasets, ArchGDAL

# Too big to test
# @testset "load WorldClim Weather" begin
#     # Weather time-series
#     dates = (Date(2001), Date(2002))
#     ser = series(WorldClim{Weather}, (:prec,); date=dates, window=(Lat(600:1900), Lon(600:1900)))
#     ser[Date(2001, 1)][:prec]
#     # Select Australia, using regular lat/lon selectors
#     A = geoarray(WorldClim{Weather}, :prec; date=DateTime(2001, 05), mappedcrs=EPSG(4326))
# end

@testset "load WorldClim Climate" begin
    # Weather time-series
    ser = series(WorldClim{Climate}, (:prec,); res="10m", month=Jan:March)
    ser[Jan][:prec] 
    # Select Australia, using regular lat/lon selectors
    A = geoarray(WorldClim{Climate}, :prec; month=1, mappedcrs=EPSG(4326))
    A[Lat(Between(-10, -45)), Lon(Between(110, 160))]
    st = stack(WorldClim{BioClim}, (1, 2))
    st[:BIO1]
    @test st isa DiskStack
    @test A isa GDALarray
end

@testset "load WorldClim BioClim" begin
    A = geoarray(WorldClim{BioClim}, 1; mappedcrs=EPSG(4326))
    A[Lat(Between(-10, -45)), Lon(Between(110, 160))]
    @test A isa GDALarray
end

@testset "load CHELSA BioClim" begin
    A = geoarray(CHELSA{BioClim}, 1; mappedcrs=EPSG(4326))
    A[Lat(Between(-10, -45)), Lon(Between(110, 160))]
    st = stack(CHELSA{BioClim}, (1, 2))
    @test A isa GDALarray
    @test st isa DiskStack
    @test st[:BIO2] isa GeoArray
end

@testset "load EarthEnv HabitatHeterogeneity" begin
    A = geoarray(EarthEnv{HabitatHeterogeneity}, :cv; mappedcrs=EPSG(4326))
    A[Lat(Between(-10, -45)), Lon(Between(110, 160))]
    st = stack(EarthEnv{HabitatHeterogeneity}, (:cv, :evenness))
    @test A isa GDALarray
    @test st isa DiskStack
    @test st[:evenness] isa GeoArray
end

@testset "load EarthEnv LandCover" begin
    A = geoarray(EarthEnv{LandCover}, 2; mappedcrs=EPSG(4326))
    A[Lat(Between(-10, -45)), Lon(Between(110, 160))]
    @test A isa GDALarray
end

@testset "load ALWB" begin
    A = geoarray(ALWB{Values,Day}, :ss_pct; date=DateTime(2019, 10, 19))
    st = stack(ALWB{Values,Day}, (:s0_pct, :ss_pct); date=DateTime(2019, 10, 19))
    dates = DateTime(2019, 10, 19):Day(1):DateTime(2019, 11, 20)
    s = series(ALWB{Values,Day}, (:s0_pct, :ss_pct); date=dates)
    @test A isa NCDarray
    @test st isa DiskStack
    @test s isa GeoSeries
end

if Sys.islinux()
    @testset "load AWAP" begin
        A = geoarray(AWAP, :rainfall; date=DateTime(2019, 10, 19))
        st = stack(AWAP, (:tmax, :rainfall); date=DateTime(2019, 10, 19))
        st[:tmax]
        dates = DateTime(2019, 09, 19), DateTime(2019, 11, 19)
        s = series(AWAP; date=dates)
        s[DateTime(2019, 10, 1)][:solar]
        @test A isa GDALarray
        @test st isa DiskStack
        @test s isa GeoSeries
    end
end
