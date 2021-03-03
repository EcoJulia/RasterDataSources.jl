"""
    getraster(T::Type{CHELSA{BioClim}}, F::FutureClimate, [layer::Integer]) => String

Download CHELSA BioClim data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned. 
If the data is already downloaded the path will be returned.
"""
function getraster(T::Type{CHELSA{BioClim}}, ::Type{F}, layer::Integer, date=Year(2050)) where {F <: FutureClimate}
    _check_layer(T, layer)
    path = rasterpath(T, F, layer, date)
    url = rasterurl(T, F, layer, date)
    return _maybe_download(url, path)
end

function rastername(::Type{CHELSA{BioClim}}, ::Type{F}, layer::Integer, date::Year=Year(2050)) where {F <: FutureClimate}
    @assert date ∈ [Year(2050), Year(2070)]
    date_string = date == Year(2050) ? "2041-2060" : "2061-2080"
    return "CHELSA_bio_mon_$(_format(CHELSA, _model(F)))_$(_format(CHELSA, _scenario(F)))_r1i1p1_g025.nc_$(layer)_$(date_string)_V1.2.tif"
end

rasterpath(::Type{CHELSA{BioClim}}, ::Type{F}) where {F <: FutureClimate} = joinpath(rasterpath(CHELSA), "Future", "BioClim", _format(CHELSA, _scenario(F)), _format(CHELSA, _model(F)))
rasterpath(T::Type{CHELSA{BioClim}}, ::Type{F}, layer::Integer, date::Year) where {F <: FutureClimate} = joinpath(rasterpath(T, F), rastername(T, F, layer, date))

function rasterurl(::Type{CHELSA{BioClim}}, ::Type{F}, date::Year) where {F <: FutureClimate}
    @assert date ∈ [Year(2050), Year(2070)]
    date_string = date == Year(2050) ? "2041-2060" : "2061-2080"
    joinpath(rasterurl(CHELSA), "cmip5/$(date_string)/bio/")
end
rasterurl(T::Type{CHELSA{BioClim}}, ::Type{F}, layer::Integer, date::Year) where {F <: FutureClimate} = joinpath(rasterurl(T, F, date), rastername(T, F, layer, date))