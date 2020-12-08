# Interface methods

resolutions(::Type{EarthEnv{HabitatHeterogeneity}}) = (1, 5, 25)
layers(::Type{EarthEnv{HabitatHeterogeneity}}) = 
    (:cv, :evenness, :range, :shannon, :simpson, :std, :Contrast, :Correlation, 
     :Dissimilarity, :Entropy, :Homogeneity, :Maximum, :Uniformity, :Variance)
rastername(::Type{EarthEnv{HabitatHeterogeneity}}, layer::Symbol, resolution::Integer) =
    "$(layer)_$(resolution)km.tif"
rasterpath(T::Type{<:EarthEnv{HabitatHeterogeneity}}, layer::Symbol, resolution::Integer) = 
    joinpath(rasterpath(T), string(resolution) * "km", rastername(T, layer, resolution))
rasterurl(T::Type{EarthEnv{HabitatHeterogeneity}}, layer, resolution::Integer) = 
    joinpath(rasterurl(T), "$(resolution)km/$(layer)_01_05_$(resolution)km_$(_getprecision(layer, resolution)).tif")

function download_raster(T::Type{EarthEnv{HabitatHeterogeneity}}; layer::Symbol=:cv, resolution::Integer=25)
    _check_layer(T, layer)
    _check_resolution(T, resolution)
    path = rasterpath(T, layer, resolution)
    url = rasterurl(T, layer, resolution) 
    return _maybe_download(url, path)
end

# Utility methods

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

