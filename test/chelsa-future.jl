using RasterDataSources, Test, Dates
using RasterDataSources: rasterurl, rastername, rasterpath

@testset "CHELSA Future BioClim CMIP5" begin
    @test rastername(CHELSA{Future{BioClim,CMIP5,CCSM4,RCP26}}, 5; date=Date(2050)) == "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif"

    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "BioClim", "RCP26", "CCSM4")
    @test rasterpath(CHELSA{Future{BioClim,CMIP5,CCSM4,RCP26}}) == bioclim_path

    raster_path = joinpath(bioclim_path, "CHELSA_bio_mon_CCSM4_rcp26_r1i1p1_g025.nc_5_2041-2060_V1.2.tif")

    @test getraster(CHELSA{Future{BioClim,CMIP5,CCSM4,RCP26}}, 5; date=Date(2050)) == raster_path
    @test getraster(CHELSA{Future{BioClim,CMIP5,CCSM4,RCP26}}, (5,); date=Date(2050)) == (bio5=raster_path,)
    @test getraster(CHELSA{Future{BioClim,CMIP5,CCSM4,RCP26}}, [5]; date=Date(2050)) == (bio5=raster_path,)
    @test isfile(raster_path)

    @test RasterDataSources.getraster_keywords(CHELSA{Future{BioClim}}) == (:date,)
end

@testset "CHELSA Future BioClim CMIP6" begin
    bioclim_name = "CHELSA_bio5_2041-2070_mri-esm2-0_ssp126_V.2.1.tif"
    @test rastername(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, 5; date=Date(2050)) == bioclim_name
    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "BioClim", "SSP126", "MRIESM20")
    @test rasterpath(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}) == bioclim_path

    raster_path = joinpath(bioclim_path, bioclim_name)
    raster_path2 = joinpath(bioclim_path, "CHELSA_bio5_2071-2100_mri-esm2-0_ssp126_V.2.1.tif")
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, 5; date=Date(2050)) == raster_path
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (5,); date=Date(2050)) == (bio5=raster_path,)
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, [5]; date=Date(2050)) == (bio5=raster_path,)
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (5,); date=[Date(2050)]) == 
        [(bio5=raster_path,)]
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, :bio5; date=Date(2050)) == raster_path
    @test getraster(CHELSA{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (:bio5,); date=Date(2050)) == (bio5=raster_path,)
    @test getraster(CHELSA{Future{BioClimPlus,CMIP6,MRI_ESM2_0,SSP126}}, :bio5; date=Date(2050)) == raster_path
    @test getraster(CHELSA{Future{BioClimPlus,CMIP6,MRI_ESM2_0,SSP126}}, (:bio5,); date=Date(2050)) == (bio5=raster_path,)
    @test isfile(raster_path)

    # bioclimplus requires symbol input
    @test_throws ArgumentError getraster(CHELSA{Future{BioClimPlus,CMIP6,MRI_ESM2_0,SSP126}}, 5; date=Date(2050))
end

@testset "CHELSA Future Climate CMIP5" begin
    tmax_name = "CHELSA_tasmax_mon_CCSM4_rcp60_r1i1p1_g025.nc_7_2041-2060_V1.2.tif"
    @test rastername(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, :tmax; date=Date(2050), month=7) == tmax_name

    climate_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "Climate", "RCP60", "CCSM4")
    @test rasterpath(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}) == climate_path

    raster_path = joinpath(climate_path, tmax_name)
    @test rasterpath(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, :tmax; date=Date(2050), month=7) == raster_path
    @test rasterurl(CHELSA{Future{Climate,CMIP5,CCSM4,RCP45}}, :prec; date=Date(2050), month=6) |> string ==
        "https://os.zhdk.cloud.switch.ch/chelsav1/cmip5/2041-2060/prec/CHELSA_pr_mon_CCSM4_rcp45_r1i1p1_g025.nc_6_2041-2060.tif"
    @test rasterurl(CHELSA{Future{Climate,CMIP5,CCSM4,RCP45}}, :tmin; date=Date(2050), month=1) |> string ==
        "https://os.zhdk.cloud.switch.ch/chelsav1/cmip5/2041-2060/tmin/CHELSA_tasmin_mon_CCSM4_rcp45_r1i1p1_g025.nc_1_2041-2060_V1.2.tif"
    @test getraster(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, :tmax; date=Date(2050), month=7) == raster_path
    @test getraster(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, [:tmax]; date=Date(2050), month=7) == (tmax=raster_path,)
    @test getraster(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, (:tmax,); date=Date(2050), month=7:7) == [(tmax=raster_path,)]
    @test getraster(CHELSA{Future{Climate,CMIP5,CCSM4,RCP60}}, :tmax; date=[Date(2050)], month=7:7) == [[raster_path]]
    @test isfile(raster_path)
    @test RasterDataSources.getraster_keywords(CHELSA{Future{Climate}}) == (:date, :month)
end
@edit rasterpath(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}})
@testset "CHELSA Future Climate CMIP6" begin
    date_name =  "CHELSA_gfdl-esm4_r1i1p1f1_w5e5_ssp585_tas_01_2011_2040_norm.tif"
    date_name2 = "CHELSA_gfdl-esm4_r1i1p1f1_w5e5_ssp585_tas_01_2041_2070_norm.tif"
    date_name3 = "CHELSA_gfdl-esm4_r1i1p1f1_w5e5_ssp585_tas_01_2071_2100_norm.tif"
    month_name =  "CHELSA_gfdl-esm4_r1i1p1f1_w5e5_ssp585_tas_01_2011_2040_norm.tif"
    month_name2 = "CHELSA_gfdl-esm4_r1i1p1f1_w5e5_ssp585_tas_02_2011_2040_norm.tif"
    @test rastername(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) == date_name

    climate_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "CHELSA", "Future", "Climate", "SSP585", "GFDLESM4")
    @test rasterpath(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}) == climate_path
    date_path = joinpath(climate_path, date_name)
    date_path2 = joinpath(climate_path, date_name2)
    date_path3 = joinpath(climate_path, date_name3)
    month_path = joinpath(climate_path, month_name)
    month_path2 = joinpath(climate_path, month_name2)
    @test rasterpath(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) == date_path
    @test rasterpath(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) == date_path
    date_url = "https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/2011-2040/GFDL-ESM4/ssp585/tas/" * date_name
    @test rasterurl(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) |> string == date_url
    @test getraster(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) == date_path
    @test getraster(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, (:temp,); date=Date(2030), month=1) == (temp=date_path,)
    @test getraster(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, :temp; date=Date(2030), month=1) == date_path
    # Month is the inner vector
    @test getraster(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, [:temp]; date=[Date(2030)], month=1:2) == 
        [[(temp=month_path,), (temp=month_path2,)]]
    @test getraster(CHELSA{Future{Climate,CMIP6,GFDL_ESM4,SSP585}}, [:temp]; date=(Date(2030), Date(2090)), month=1:1) == 
        [[(temp=date_path,)], [(temp=date_path2,)], [(temp=date_path3,)]]

    @test isfile(date_path)
    @test isfile(date_path2)
    @test isfile(date_path3)
    @test isfile(month_path)
    @test isfile(month_path2)
end
