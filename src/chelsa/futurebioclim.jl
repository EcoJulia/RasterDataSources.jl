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
    date_string = date == Year(2050) ? "2041-2060" : "2061-2080"
    model_string = _format_model(CHELSA, model)
    rcp_string = _format_rcp(CHELSA, rcp)
    # TODO check that the model has the RCP
    _check_layer(T, layer)
    path = rasterpath(T, layer, model_string, rcp_string, date_string)
    url = rasterurl(T, layer, model_string, rcp_string, date_string)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{Future{BioClim}}}, layer::Integer, model, rcp, date) = "CHELSA_bio_mon_$(model)_$(rcp)_r1i1p1_g025.nc_$(layer)_$(date)_V1.2.tif"

rasterpath(::Type{CHELSA{Future{BioClim}}}, model, rcp, date) = joinpath(rasterpath(CHELSA), "Future", "BioClim", rcp, model, date)
rasterpath(T::Type{CHELSA{Future{BioClim}}}, layer::Integer, model, rcp, date) = joinpath(rasterpath(T, model, rcp, date), rastername(T, layer, model, rcp, date))

rasterurl(::Type{CHELSA{Future{BioClim}}}, model, rcp, date) = joinpath(rasterurl(CHELSA), "cmip5/$(date)/bio/")
rasterurl(T::Type{CHELSA{Future{BioClim}}}, layer::Integer, model, rcp, date) = joinpath(rasterurl(T, model, rcp, date), rastername(T, layer, model, rcp, date))