using RasterDataSources, Test, Dates
using RasterDataSources: rasterurl, rastername, rasterpath

@testset "WorldClim Future BioClim CMIP6" begin
    bioclim_name = "wc2.1_10m_bioc_MRI-ESM2-0_ssp126_2041-2060.tif"
    @test rastername(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, 5; date=Date(2050), res = "10m") == bioclim_name
    bioclim_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Future", "BioClim", "ssp126", "MRI-ESM2-0")
    @test rasterpath(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}) == bioclim_path

    raster_path = joinpath(bioclim_path, bioclim_name)
    raster_path2 = joinpath(bioclim_path, "wc2.1_10m_5_MRI-ESM2-0_SSP126_2041-2060.tif")
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}; date=Date(2050), res = "10m") == raster_path
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, 5; date=Date(2050), res = "10m") == raster_path
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, :bio5; date=Date(2050)) == raster_path
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (5,); date=Date(2050), res = "10m") == raster_path
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, [5]; date=Date(2050), res = "10m") == raster_path
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (5,); date=[Date(2050)], res = "10m") == [raster_path]
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (5,); date=(Date(2050),Date(2050)), res = "10m") == 
        [raster_path]
    @test getraster(WorldClim{Future{BioClim,CMIP6,MRI_ESM2_0,SSP126}}, (:bio5,); date=Date(2050)) ==raster_path
    
    @test isfile(raster_path)
end

@testset "WorldClim Future Climate CMIP6" begin
    date_name =  "wc2.1_10m_tmin_GFDL-ESM4_ssp126_2021-2040.tif"
    date_name2 =  "wc2.1_10m_tmin_GFDL-ESM4_ssp126_2041-2060.tif"
    date_name3 =  "wc2.1_10m_tmin_GFDL-ESM4_ssp126_2061-2080.tif"
    date_name4 =  "wc2.1_10m_tmin_GFDL-ESM4_ssp126_2081-2100.tif"
    date_names = [date_name, date_name2, date_name3, date_name4]

    @test rastername(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res= "10m") == date_name

    climate_path = joinpath(ENV["RASTERDATASOURCES_PATH"], "WorldClim", "Future", "Climate", "ssp126", "GFDL-ESM4")
    @test rasterpath(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}) == climate_path
    date_path = joinpath(climate_path, date_name)
    date_paths = joinpath.(climate_path, date_names)
    @test rasterpath(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res = "10m") == date_path
    @test rasterpath(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res = "10m") == date_path
    date_url = "https://geodata.ucdavis.edu/cmip6/10m/GFDL-ESM4/ssp126/wc2.1_10m_tmin_GFDL-ESM4_ssp126_2021-2040.tif"
    @test rasterurl(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res = "10m") |> string == date_url
    @test getraster(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res = "10m") == date_path
    @test getraster(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, (:tmin,); date=Date(2030), res = "10m") == (tmin=date_path,)
    @test getraster(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, (:tmin,); date=(Date(2030), Date(2090)), res = "10m") == 
                [(tmin=date_path,) for date_path in date_paths]
    @test getraster(WorldClim{Future{Climate,CMIP6,GFDL_ESM4,SSP126}}, :tmin; date=Date(2030), res = "10m") == date_path

    @test isfile(date_path)
end
