layers(::Type{<:EarthEnv{<:LandCover}}) = ntuple(identity, Val{12}())

layerkeys(::Type{<:EarthEnv{<:LandCover}}) = keys(landcover_lookup)
layerkeys(T::Type{<:EarthEnv{<:LandCover}}, layers) = map(l -> layerkeys(T, l), layers)
layerkeys(T::Type{<:EarthEnv{<:LandCover}}, layer::Int) = layerkeys(T)[layer]
layerkeys(T::Type{<:EarthEnv{<:LandCover}}, layer::Symbol) = layer

const landcover_lookup = (
    needleleaf_trees = 1,
    evergreen_broadleaf_trees = 2,
    deciduous_broadleaf_trees = 3,
    other_trees = 4,
    shrubs = 5,
    herbaceous = 6,
    cultivated_and_managed = 7,
    regularly_flooded = 8,
    urban_builtup = 9,
    snow_ice = 10,
    barren = 11,
    open_water = 12,
)

"""
    getraster(T::Type{EarthEnv{LandCover}}, [layer]; discover=false) => Union{Tuple,String}

Download [`EarthEnv`](@ref) landcover data.

# Arguments

- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(EarthEnv{LandCover}))`,
    or `Symbol`s from `$(layerkeys(EarthEnv{LandCover}))`. Without a `layer` argument,
    all layers will be downloaded, and a `NamedTuple` of paths returned.

# Keywords

- `discover::Bool`: whether to download the dataset that integrates the DISCover model.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{<:EarthEnv{<:LandCover}}, layers::Union{Tuple,Int,Symbol})
    _getraster(T, layers)
end

_getraster(T::Type{<:EarthEnv{<:LandCover}}, layers::Tuple) = _map_layers(T, layers)
_getraster(T::Type{<:EarthEnv{<:LandCover}}, layer::Symbol) = _getraster(T, landcover_lookup[layer])
function _getraster(T::Type{<:EarthEnv{<:LandCover}}, layer::Integer)
    _check_layer(T, layer)
    url = rasterurl(T, layer)
    path = rasterpath(T, layer)
    return _maybe_download(url, path)
end

function rastername(T::Type{<:EarthEnv{<:LandCover}}, layer::Integer)
    class = _discover(T) ? "consensus_full" : "Consensus_reduced"
    "$(class)_class_" * string(layer) * ".tif"
end
function rasterpath(T::Type{<:EarthEnv{<:LandCover}})
    joinpath(rasterpath(EarthEnv), "LandCover", _discover_segment(T))
end
function rasterpath(T::Type{<:EarthEnv{<:LandCover}}, layer::Integer)
    joinpath(rasterpath(T), rastername(T, layer))
end
function rasterurl(T::Type{<:EarthEnv{<:LandCover}})
    joinpath(rasterurl(EarthEnv), "consensus_landcover", _discover_segment(T))
end
function rasterurl(T::Type{<:EarthEnv{<:LandCover}}, layer::Integer)
    joinpath(rasterurl(T), rastername(T, layer))
end

_discover(T::Type{EarthEnv{LandCover{:DISCover}}}) = true
_discover(T::Type{<:EarthEnv{<:LandCover}}) = false

_discover_segment(T) = _discover(T) ? "with_DISCover" : "without_DISCover"
