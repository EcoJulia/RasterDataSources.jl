resolutions(::Type{EarthEnv{HabitatHeterogeneity}}) = ("1km", "5km", "25km")
defres(::Type{EarthEnv{HabitatHeterogeneity}}) = "25km"
layers(::Type{EarthEnv{HabitatHeterogeneity}}) = 
    (:cv, :evenness, :range, :shannon, :simpson, :std, :Contrast, :Correlation, 
     :Dissimilarity, :Entropy, :Homogeneity, :Maximum, :Uniformity, :Variance)

"""
    getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, [layer::Integer]; res::Int=25) => String
    getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layer::Integer, res::Int=25) => String

Download EarthEnv habitat heterogeneity data, choosing layers from: 
$(layers(EarthEnv{HabitatHeterogeneity})) and res from 
$(resolutions(EarthEnv{HabitatHeterogeneity})).

Without a layer argument, all layers will be getrastered and a tuple of paths returned. 
If the data is already getrastered the path will be returned without the getraster.
"""
function getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res::String=defres(T))
    getraster(T, layer, res)
end
function getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol, res::String)
    _check_layer(T, layer)
    _check_res(T, res)
    path = rasterpath(T, layer; res)
    url = rasterurl(T, layer; res) 
    return _maybe_download(url, path)
end

rastername(::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res::String=defres(T)) =
    "$(layer)_$(res).tif"
rasterpath(T::Type{<:EarthEnv{HabitatHeterogeneity}}, layer::Symbol; res::String=defres(T)) =
    joinpath(rasterpath(T), string(res), rastername(T, layer; res))
rasterurl(T::Type{EarthEnv{HabitatHeterogeneity}}, layer; res::String=defres(T)) =
    joinpath(rasterurl(T), "$(res)/$(layer)_01_05_$(res)_$(_getprecision(layer, res)).tif")

_pathsegment(::Type{HabitatHeterogeneity}) = "habitat_heterogeneity"

function _getprecision(layer, res)
    precision = "uint16"
    # WELLCOME TO HELL
    precision = ((res == 10) && (layer == :cv)) ? "uint32" : precision
    precision = (layer == :Contrast) ? "uint32" : precision
    precision = (layer == :Dissimilarity) ? "uint32" : precision
    precision = (layer == :Variance) ? "uint32" : precision
    precision = ((res == 25) && (layer == :Entropy)) ? "uint32" : precision
    # /HELL
end
