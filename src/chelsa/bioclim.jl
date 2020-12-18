"""
CHELSA{BioClim} <: RasterDataSource

Data from CHELSA, currently only the `BioClim` layer is implemented.

See: [chelsa-climate.org](https://chelsa-climate.org/)
"""
struct CHELSA{X} <: RasterDataSource end

layers(::Type{CHELSA{BioClim}}) = 1:19

"""
    getraster(T::Type{CHELSA{BioClim}}, [layer::Integer]) => String

Download CHELSA BioClim data, choosing layers from: $(layers(CHELSA{BioClim})).

Without a layer argument, all layers will be getrastered, and a tuple of paths is returned. 
If the data is already getrastered the path will be returned.
"""
function getraster(T::Type{CHELSA{BioClim}}, layer::Integer)
    _check_layer(T, layer)
    path = rasterpath(T, layer)
    url = rasterurl(T, layer)
    return _maybe_download(url, path)
end

rastername(::Type{CHELSA{BioClim}}, layer::Integer) = "CHELSA_bio10_$(lpad(layer, 2, "0")).tif"

rasterpath(::Type{CHELSA}) = joinpath(rasterpath(), "CHELSA")
rasterpath(::Type{CHELSA{BioClim}}) = joinpath(rasterpath(CHELSA), "BioClim")
rasterpath(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterpath(T), rastername(T, layer))

rasterurl(::Type{CHELSA}) = URI(scheme="ftp", host="envidatrepo.wsl.ch", path="/uploads/chelsa/")
rasterurl(::Type{CHELSA{BioClim}}) = joinpath(rasterurl(CHELSA), "chelsa_V1/climatologies/bio/")
rasterurl(T::Type{CHELSA{BioClim}}, layer::Integer) = joinpath(rasterurl(T), rastername(T, layer))
