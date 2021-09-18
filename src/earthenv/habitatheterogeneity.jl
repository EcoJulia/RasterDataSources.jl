resolutions(::Type{EarthEnv{HabitatHeterogeneity}}) = ("1km", "5km", "25km")
defres(::Type{EarthEnv{HabitatHeterogeneity}}) = "25km"
layers(::Type{EarthEnv{HabitatHeterogeneity}}) = values(heterogeneity_lookup)
layerkeys(::Type{EarthEnv{HabitatHeterogeneity}}) = keys(heterogeneity_lookup)
layerkeys(T::Type{EarthEnv{HabitatHeterogeneity}}, layers) = map(l -> layerkeys(T, l), layers)
function layerkeys(::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol)
    Symbol(lowercase(string(layer)))
end

# Yes, they randomly chose cases
const heterogeneity_lookup = (
    cv = :cv,
    evenness = :evenness,
    range = :range,
    shannon = :shannon,
    simpson = :simpson,
    std = :std,
    contrast = :Contrast,
    correlation = :Correlation,
    dissimilarity = :Dissimilarity,
    entropy = :Entropy,
    homogeneity = :Homogeneity,
    maximum = :Maximum,
    uniformity = :Uniformity,
    variance = :Variance,
)

heterogeneity_layer(x::Symbol) = heterogeneity_lookup[Symbol(lowercase(string(x)))]

"""
    getraster(source::Type{EarthEnv{HabitatHeterogeneity}}, [layer]; res="25km")

Download [`EarthEnv`](@ref) habitat heterogeneity data.

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(layers(EarthEnv{HabitatHeterogeneity}))`.
    Without a `layer` argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

# Keywords
- `res`: `String` chosen from `$(resolutions(EarthEnv{HabitatHeterogeneity}))`, defaulting to "25km".

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layers::Union{Tuple,Symbol};
    res::String=defres(T)
)
    _getraster(T, layers, res)
end

function _getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layers::Tuple, res::String)
    return _map_layers(T, layers, res)
end
function _getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol, res::String)
    layer = heterogeneity_layer(layer)
    _check_layer(T, layer)
    _check_res(T, res)
    path = rasterpath(T, layer; res)
    url = rasterurl(T, layer; res)
    return _maybe_download(url, path)
end

function rastername(::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res::String=defres(T))
    "$(layer)_$(res).tif"
end
function rasterpath(::Type{EarthEnv{HabitatHeterogeneity}})
    joinpath(rasterpath(EarthEnv), "HabitatHeterogeneity")
end
function rasterpath(T::Type{<:EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res::String=defres(T))
    joinpath(rasterpath(T), string(res), rastername(T, layer; res))
end
function rasterurl(::Type{EarthEnv{HabitatHeterogeneity}})
    joinpath(rasterurl(EarthEnv), "habitat_heterogeneity")
end
function rasterurl(T::Type{EarthEnv{HabitatHeterogeneity}}, layer; res::String=defres(T))
    prec = _getprecision(layer, res)
    layerpath = "$res/$(layer)_01_05_$(res)_$prec.tif"
    joinpath(rasterurl(T), layerpath)
end

# See http://www.earthenv.org/texture
function _getprecision(layer, res)
    if ((res in ("1km", "5km")) && (layer == :Correlation))
        "int16"
    elseif ((res == "5km") && (layer == :cv)) ||
           ((res == "25km") && (layer == :Entropy)) ||
           layer in (:Contrast, :Dissimilarity, :Variance)
        "uint32"
    else
        "uint16"
    end
end
