using RasterDataSources, URIs, Test
using RasterDataSources: rastername, rasterpath, rasterurl, layers, depths

@testset "SLGA" begin
    slga_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SLGA")

    # Layers
    @test :clay in layers(SLGA)
    @test :der in layers(SLGA)
    @test length(layers(SLGA)) == 17

    # Depths
    @test depths(SLGA) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
    @test depths(SLGA, :clay) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
    @test depths(SLGA, :der) == ("0-999cm",)
    @test depths(SLGA, :des) == ("0-200cm",)

    # Filenames
    @test rastername(SLGA, :clay; depth="0-5cm", component="EV") ==
        "CLY_000_005_EV_N_P_AU_TRN_N_20210902.tif"
    @test rastername(SLGA, :bdod; depth="100-200cm", component="05") ==
        "BDW_100_200_05_N_P_AU_TRN_N_20230607.tif"
    @test rastername(SLGA, :der; depth="0-999cm", component="EV") ==
        "DER_000_999_EV_N_P_AU_NAT_C_20150601.tif"
    @test rastername(SLGA, :phc; depth="0-5cm", component="95") ==
        "PHC_000_005_95_N_P_AU_NAT_C_20210913.tif"

    # Paths
    @test rasterpath(SLGA) == slga_path
    @test rasterpath(SLGA, :clay; depth="0-5cm", component="EV") ==
        joinpath(slga_path, "clay", "CLY_000_005_EV_N_P_AU_TRN_N_20210902.tif")

    # URLs
    @test rasterurl(SLGA, :clay; depth="0-5cm", component="EV") ==
        URI(scheme="https", host="esoil.io",
            path="/TERNLandscapes/Public/Products/TERN/SLGA/CLY/CLY_000_005_EV_N_P_AU_TRN_N_20210902.tif")
    @test rasterurl(SLGA, :der; depth="0-999cm", component="EV") ==
        URI(scheme="https", host="esoil.io",
            path="/TERNLandscapes/Public/Products/TERN/SLGA/DER/DER_000_999_EV_N_P_AU_NAT_C_20150601.tif")

    # Validation errors
    @test_throws ArgumentError getraster(SLGA, :clay; depth="0-999cm", component="EV")
    @test_throws ArgumentError getraster(SLGA, :clay; depth="0-5cm", component="50")
    @test_throws ArgumentError getraster(SLGA, :not_a_layer; depth="0-5cm", component="EV")
    @test_throws ArgumentError getraster(SLGA, :der; depth="0-5cm", component="EV")

    # Keywords trait
    @test RasterDataSources.getraster_keywords(SLGA) == (:depth, :component)

    # Attribute metadata accessible
    @test RasterDataSources.SLGA_ATTRS.clay.description == "Clay content"
    @test RasterDataSources.SLGA_ATTRS.nto.description == "Total nitrogen"
    @test RasterDataSources.SLGA_ATTRS.dul.units == "% vol"

    # cfg no longer in SLGA
    @test :cfg ∉ layers(SLGA)
end

@testset "SLGA_CFG" begin
    # Depths
    @test depths(SLGA_CFG) == ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")

    # Filenames
    names = RasterDataSources.rasternames(SLGA_CFG; depth="0-5cm")
    @test names.class1   == "CFG_000_005_EV_N_P_AU_TRN_N_20221006_CF_Probability_Class1.tif"
    @test names.class6   == "CFG_000_005_EV_N_P_AU_TRN_N_20221006_CF_Probability_Class6.tif"
    @test names.dominant == "CFG_000_005_EV_N_P_AU_TRN_N_20221006_Dominant_Class.tif"

    # Paths
    slga_cfg_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "SLGA", "cfg")
    @test rasterpath(SLGA_CFG) == slga_cfg_path

    # URLs
    urls = RasterDataSources.rasterurls(SLGA_CFG; depth="0-5cm")
    @test urls.class1 == URI(scheme="https", host="esoil.io",
        path="/TERNLandscapes/Public/Products/TERN/SLGA/CFG/CFG_000_005_EV_N_P_AU_TRN_N_20221006_CF_Probability_Class1.tif")
    @test urls.dominant == URI(scheme="https", host="esoil.io",
        path="/TERNLandscapes/Public/Products/TERN/SLGA/CFG/CFG_000_005_EV_N_P_AU_TRN_N_20221006_Dominant_Class.tif")

    # Validation error
    @test_throws ArgumentError getraster(SLGA_CFG; depth="0-999cm")

    # Keywords trait
    @test RasterDataSources.getraster_keywords(SLGA_CFG) == (:depth,)
end
