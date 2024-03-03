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
    patch::Int = latest_patch(T, version)) = _getraster(T, layer, version, patch)

_getraster(T::Type{CHELSA{BioClim}}, layers::Tuple, version, patch) = _map_layers(T, layers, version, patch)
_getraster(T::Type{CHELSA{BioClim}}, layer::Symbol, version, patch) = _getraster(T, bioclim_int(layer), version, patch)
function _getraster(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch)
    _check_layer(T, layer)
    path = rasterpath(T, layer, version, patch)
    url = rasterurl(T, layer, version, patch)
    CHELSA_warn_version(T, layer, version, patch, path)
    return _maybe_download(url, path)
end
getraster_keywords(::Type{<:CHELSA{BioClim}}) = (:version,:patch)

function rastername(::Type{CHELSA{BioClim}}, layer::Integer, version::Int, patch)
    if version == 1
        "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"
    elseif version == 2
        "CHELSA_bio$(layer)_1981-2010_V.2.$patch.tif"
    else
        CHELSA_invalid_version(version)
    end
end

rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch) = joinpath(rasterpath(T), rastername(T, layer, version, patch))

function rasterurl(::Type{CHELSA{BioClim}}, v::Int)
    if v == 1
        joinpath(rasterurl(CHELSA, v), "climatologies/bio/")
    elseif v == 2
        joinpath(rasterurl(CHELSA, v), "climatologies/1981-2010/bio/")
    else
        CHELSA_invalid_version(v)
    end
end

rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer, version, patch) = joinpath(rasterurl(T, version), rastername(T, layer, version, patch))

### Bioclim+
"""
    getraster(source::Type{CHELSA{BioClim}}, [layer]; version = 2, [patch]) => Union{Tuple,String}

Download [`CHELSA`](@ref) [`BioClim`](@ref) data from [chelsa-climate.org](https://chelsa-climate.org/).

# Arguments
- `layer`: iterable of `Symbol`s from `$(layerkeys(BioClimPlus))`. Without a `layer` argument, all layers
    will be downloaded, and a `NamedTuple` of paths returned.

# Keyword arguments
$CHELSA_KEYWORDS

Returns the filepath/s of the downloaded or pre-existing files.
"""
layers(::Type{CHELSA{BioClimPlus}}) = layers(BioClimPlus)

getraster(
    T::Type{CHELSA{BioClimPlus}}, 
    layer::Union{Tuple,Int,Symbol}; 
    version::Int = 2, 
    patch::Int = latest_patch(T, version)) = _getraster(T, layer, version, patch)

_getraster(T::Type{CHELSA{BioClimPlus}}, layers::Tuple, version, patch) = _map_layers(T, layers, version, patch)
function _getraster(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch)
    version == 2 || CHELSA_invalid_version(version, 2)
    _check_layer(T, layer)
    path = rasterpath(T, layer, version, patch)
    url = rasterurl(T, layer, version, patch)
    return _maybe_download(url, path)
end
getraster_keywords(::Type{<:CHELSA{BioClimPlus}}) = (:version,:patch)


rastername(::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch) = "CHELSA_$(layer)_1981-2010_V.2.$patch.tif"
rasterpath(::Type{CHELSA{BioClimPlus}}) = rasterpath(CHELSA{BioClim})
rasterpath(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch) = joinpath(rasterpath(T), rastername(T, layer, version, patch))
rasterurl(T::Type{CHELSA{BioClimPlus}}, layer::Symbol, version, patch) = joinpath(rasterurl(CHELSA{BioClim}, version), rastername(T, layer, version, patch))
