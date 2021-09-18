layers(::Type{CHELSA{BioClim}}) = layers(BioClim)
layerkeys(::Type{CHELSA{BioClim}}, args...) = layerkeys(BioClim, args...)

"""
    getraster(source::Type{CHELSA{BioClim}}, [layer::Union{Tuple,Integer}]) => Union{Tuple,String}

Download [`CHELSA`](@ref) [`BioClim`](@ref) data from [chelsa-climate.org](https://chelsa-climate.org/).

# Arguments
- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(BioClim))`, 
    or `Symbol`s form `$(layerkeys(BioClim))`. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned.

Returns the filepath/s of the downloaded or pre-existing files.
"""
getraster(T::Type{CHELSA{BioClim}}, layer::Union{Tuple,Int,Symbol}) = _getraster(T, layer)

_getraster(T::Type{CHELSA{BioClim}}, layers::Tuple) = _map_layers(T, layers)
_getraster(T::Type{CHELSA{BioClim}}, layer::Symbol) = _getraster(T, bioclim_int(layer))
function _getraster(T::Type{CHELSA{BioClim}}, layer::Integer)
    _check_layer(T, layer)
    path = rasterpath(T, layer)
    url = rasterurl(T, layer)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer::Integer) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(::Type{CHELSA{BioClim}}) = joinpath(rasterurl(CHELSA), "chelsa_V1/climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterurl(T), rastername(T, layer))
