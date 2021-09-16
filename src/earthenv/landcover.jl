layers(::Type{<:EarthEnv{<:LandCover}}) = ntuple(identity, Val{12}())

function layerkeys(::Type{<:EarthEnv{<:LandCover}}) 
    (
        :NeedleleafTrees,
        :EvergreenBroadleafTrees,
        :DeciduousBroadleafTrees,
        :OtherTrees,
        :Shrubs,
        :Herbaceous,
        :CultivatedAndManaged,
        :RegularlyFlooded,
        :UrbanBuiltup,
        :SnowIce,
        :Barren,
        :OpenWater,
    )
end
layerkeys(T::Type{<:EarthEnv{<:LandCover}}, layer::Int) = layerkeys(T)[layer]
layerkeys(T::Type{<:EarthEnv{<:LandCover}}, layers) = map(l -> layerkeys(T, l), layers)

"""
    getraster(T::Type{EarthEnv{LandCover}}, [layer::Union{AbstractArray,Tuple,Integer}]; discover::Bool=false) => Union{Tuple,String}
    getraster(T::Type{EarthEnv{LandCover}}, layer::Integer, discover::Bool) => String

Download [`EarthEnv`](@ref) landcover data.

# Arguments
- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(EarthEnv{LandCover}))`.
    Without a `layer` argument, all layers will be downloaded, and a tuple of paths returned.

`LandCover` may also be `LandCover{:DISCover} to download the dataset that integrates the DISCover model.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{<:EarthEnv{<:LandCover}}, layers::Union{Tuple,Int})
    _getraster(T, layers)
end

_getraster(T::Type{<:EarthEnv{<:LandCover}}, layers::Tuple) = _map_layers(T, layers)
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
