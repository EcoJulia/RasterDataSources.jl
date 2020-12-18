resolutions(::Type{EarthEnv{HabitatHeterogeneity}}) = (1, 5, 25)
layers(::Type{EarthEnv{HabitatHeterogeneity}}) = 
    (:cv, :evenness, :range, :shannon, :simpson, :std, :Contrast, :Correlation, 
     :Dissimilarity, :Entropy, :Homogeneity, :Maximum, :Uniformity, :Variance)

"""
    getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, [layer::Integer]; resolution::Int=25) => String

Download EarthEnv habitat heterogeneity data, choosing layers from: 
$(layers(EarthEnv{HabitatHeterogeneity})) and resolution from 
$(resolutions(EarthEnv{HabitatHeterogeneity})).

Without a layer argument, all layers will be getrastered and a tuple of paths returned. 
If the data is already getrastered the path will be returned without the getraster.
"""
function getraster(T::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol; resolution=25)
    _check_layer(T, layer)
    _check_resolution(T, resolution)
    path = rasterpath(T, layer; resolution)
    url = rasterurl(T, layer; resolution) 
    return _maybe_download(url, path)
end

rastername(::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol; resolution::Integer=25) =
    "$(layer)_$(resolution)km.tif"
rasterpath(T::Type{<:EarthEnv{HabitatHeterogeneity}}, layer::Symbol; resolution::Integer=25) =
    joinpath(rasterpath(T), string(resolution) * "km", rastername(T, layer; resolution))
rasterurl(T::Type{EarthEnv{HabitatHeterogeneity}}, layer; resolution::Integer=25) =
    joinpath(rasterurl(T), "$(resolution)km/$(layer)_01_05_$(resolution)km_$(_getprecision(layer, resolution)).tif")

_pathsegment(::Type{HabitatHeterogeneity}) = "habitat_heterogeneity"

function _getprecision(layer, resolution)
    precision = "uint16"
    # WELLCOME TO HELL
    precision = ((resolution == 10) && (layer == :cv)) ? "uint32" : precision
    precision = (layer == :Contrast) ? "uint32" : precision
    precision = (layer == :Dissimilarity) ? "uint32" : precision
    precision = (layer == :Variance) ? "uint32" : precision
    precision = ((resolution == 25) && (layer == :Entropy)) ? "uint32" : precision
    # /HELL
end
