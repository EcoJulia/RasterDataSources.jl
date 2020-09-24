function download_raster(::Type{EarthEnv}, ::Type{HabitatHeterogeneity}; layer::Symbol=:cv, resolution::Integer=25)
    
    resolution in [1,5,25] || throw(ArgumentError("The resolution must be 1km, 5km, or 25km"))

    available_layers = [:cv, :evenness, :range, :shannon, :simpson, :std,
        :Contrast, :Correlation, :Dissimilarity, :Entropy, :Homogeneity, :Maximum,
        :Uniformity, :Variance]

    path = SimpleSDMDataSources._raster_assets_folder(EarthEnv, HabitatHeterogeneity)

    root = "https://data.earthenv.org/habitat_heterogeneity/$(string(resolution))km/"
    precision = "uint16"

    # WELLCOME TO HELL
    precision = ((resolution == 10) && (layer == :cv)) ? "uint32" : precision
    precision = (layer == :Contrast) ? "uint32" : precision
    precision = (layer == :Dissimilarity) ? "uint32" : precision
    precision = (layer == :Variance) ? "uint32" : precision
    precision = ((resolution == 25) && (layer == :Entropy)) ? "uint32" : precision
    # /HELL

    stem = "$(layer)_01_05_$(string(resolution))km_$(precision).tif"
    filename = "$(layer)_$(resolution)km.tif"

    return _maybe_download(root * stem, joinpath(path, filename))
end
