"""
    getraster(T::Type{CHELSA{BioClim}}, [layer::Integer]) => String

Download CHELSA BioClim data, choosing layers from: `$(layers(CHELSA{BioClim}))`.

Without a layer argument, all layers will be downloaded, and a tuple of paths is returned. 
If the data is already downloaded the path will be returned.
"""
function getraster(T::Type{CHELSA{BioClim}}, layer::Integer)
    _check_layer(T, layer)
    path = rasterpath(T, layer)
    url = rasterurl(T, layer)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer::Integer) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(::Type{CHELSA{BioClim}}) = joinpath(rasterurl(CHELSA), "climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterurl(T), rastername(T, layer))
