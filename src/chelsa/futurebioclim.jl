"""
    getraster(T::Type{CHELSA{Future{BioClim}}}, [layer::Integer]) => String

Download CHELSA BioClim data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned. 
If the data is already downloaded the path will be returned.
"""
function getraster(T::Type{CHELSA{Future{BioClim}}}, layer::Integer; model=CCSM4, rcp=RCP45, date=Year(2050))
    @info T
    @info model
    @assert date ∈ [Year(2050), Year(2070)]
    # Prepare the string for URL / storage
    date_string = date == Year(2050) ? "2041-2060" : "2060-2080"
    model_string = _format_model(CHELSA, model)
    rcp_string = _format_rcp(CHELSA, rcp)
    #_check_layer(T, layer)
    #path = rasterpath(T, layer)
    #url = rasterurl(T, layer)
    #return _maybe_download(url, path)
end

rastername(::Type{CHELSA{Future{BioClim}}}, layer::Integer) = "CHELSA_bio_mon_$(MODEL)_$(RCP)_r1i1p1_g025.nc_$(layer)_$(YR)_V1.2.tif "

rasterpath(::Type{CHELSA{Future{BioClim}}}) = joinpath(rasterpath(CHELSA), "Future", "BioClim", RCP, MODEL)
rasterpath(T::Type{CHELSA{Future{BioClim}}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(::Type{CHELSA{Future{BioClim}}}) = joinpath(rasterurl(CHELSA), "climatologies/bio/")
rasterurl(T::Type{CHELSA{Future{BioClim}}}, layer::Integer) = joinpath(rasterurl(T), rastername(T, layer))


#https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V1/cmip5/2041-2060/bio/CHELSA_bio_mon_GFDL-ESM2M_rcp26_r1i1p1_g025.nc_14_2041-2060_V1.2.tif 