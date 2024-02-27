layers(::Type{CHELSA{BioClim}}) = layers(BioClim)
layerkeys(::Type{CHELSA{BioClim}}, args...) = layerkeys(BioClim, args...)
layerkeys(::Type{CHELSA{BioClimPlus}}, args...) = layerkeys(BioClimPlus, args...)

"""
    getraster(source::Type{CHELSA{BioClim}}, [layer]; version = 2, [patch]) => Union{Tuple,String}

Download [`CHELSA`](@ref) [`BioClim`](@ref) data from [chelsa-climate.org](https://chelsa-climate.org/).

# Arguments
- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(BioClim))`, 
    or `Symbol`s form `$(layerkeys(BioClim))`. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned.

# Keyword arguments
$CHELSA_KEYWORDS

Returns the filepath/s of the downloaded or pre-existing files.
"""
getraster(
    T::Type{CHELSA{BioClim}}, 
    layer::Union{Tuple,Int,Symbol}; 
    version::Int = 2, 
    patch::Int = latest_patch(T, Val(version))) = _getraster(T, layer, Val(version), patch)

_getraster(T::Type{CHELSA{BioClim}}, layers::Tuple, version, patch) = _map_layers(T, layers, version, patch)
_getraster(T::Type{CHELSA{BioClim}}, layer::Symbol, version, patch) = _getraster(T, bioclim_int(layer), version, patch)
function _getraster(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch)
    _check_layer(T, layer)
    path = rasterpath(T, layer, version, patch)
    url = rasterurl(T, layer, version, patch)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer::Integer, version::Val{2}, patch) = "CHELSA_bio$(layer)_1981-2010_V.2.$patch.tif"
rastername(::Type{CHELSA{BioClim}}, layer::Integer, version::Val{1}, patch) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch) = joinpath(rasterpath(T), rastername(T, layer, version, patch))

rasterurl(::Type{CHELSA{BioClim}}, v::Val{2}) = joinpath(rasterurl(CHELSA, v), "climatologies/1981-2010/bio/")
rasterurl(::Type{CHELSA{BioClim}}, v::Val{1}) = joinpath(rasterurl(CHELSA, v), "climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch) = joinpath(rasterurl(T, version), rastername(T, layer, version, patch))

rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

### Bioclim+
layers(::Type{CHELSA{BioClimPlus}}) = layers(BioClimPlus)

getraster(
    T::Type{CHELSA{BioClimPlus}}, 
    layer::Union{Tuple,Int,Symbol}; 
    version::Int = 2, 
    patch::Int = latest_patch(T, Val(version))) = _getraster(T, layer, Val(version), patch)

_getraster(T::Type{CHELSA{BioClimPlus}}, layers::Tuple, version, patch) = _map_layers(T, layers, version, patch)
function _getraster(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version::Val{2}, patch)
    _check_layer(T, layer)
    path = rasterpath(T, layer, version, patch)
    url = rasterurl(T, layer, version, patch)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClimPlus}}, layer::Symbol, version::Val{2}, patch) = "CHELSA_$(layer)_1981-2010_V.2.$patch.tif"
rasterpath(::Type{CHELSA{BioClimPlus}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch) = joinpath(rasterpath(T), rastername(T, layer, version, patch))
rasterurl(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch) = joinpath(rasterurl(CHELSA{BioClim}, version), rastername(T, layer, version, patch))
