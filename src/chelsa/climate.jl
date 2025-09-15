layers(::Type{CHELSA{Climate}}) = (:clt, :cmi, :hurs, :ncdf, :pet, :pr, :rsds, :sfcWind, :tas, :tasmax, :tasmin, :vpd)

function getraster(T::Type{CHELSA{Climate}}, layers::Union{Tuple,Symbol}; month)
    _getraster(T, layers, month)
end

getraster_keywords(::Type{CHELSA{Climate}}) = (:month,)

function _getraster(T::Type{CHELSA{Climate}}, layers, month::AbstractArray)
    _getraster.(T, Ref(layers), month)
end
function _getraster(T::Type{CHELSA{Climate}}, layers::Tuple, month::Integer)
    _map_layers(T, layers, month)
end
function _getraster(T::Type{CHELSA{Climate}}, layer::Symbol, month::Integer)
    _check_layer(T, layer)
    path = rasterpath(T, layer; month)
    url = rasterurl(T, layer; month)
    return _maybe_download(url, path)
end

# Climate layers don't get their own folder
rasterpath(T::Type{<:CHELSA{Climate}}, layer; month) =
    joinpath(_rasterpath(T, layer), rastername(T, layer; month))
_rasterpath(T::Type{<:CHELSA{Climate}}, layer) = joinpath(rasterpath(T), string(layer))
rasterpath(T::Type{<:CHELSA{Climate}}) = joinpath(rasterpath(CHELSA), "Climate")
function rastername(T::Type{<:CHELSA{Climate}}, layer; month)
    _layer = layer == :pet ? :pet_penman : layer
    "CHELSA_$(_layer)_$(_pad2(month))_1981-2010_V.2.1.tif"
end
rasterurl(T::Type{CHELSA{Climate}}, layer::Symbol; month) = joinpath(rasterurl(CHELSA, 2), "climatologies/1981-2010", string(layer), rastername(T, layer; month))