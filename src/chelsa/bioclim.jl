"""
    CHELSA <: RasterDataSource

Data from CHELSA, at [chelsa-climate.org](https://chelsa-climate.org/).
Currently only the `BioClim` dataset is implemented.
"""
struct CHELSA{X} <: RasterDataSource end

layers(::Type{CHELSA{BioClim}}) = 1:19

"""
    getraster(source::Type{CHELSA{BioClim}}, [layer::Union{Tuple,Integer}]) => Union{Tuple,String}

Download [`CHELSA`](@ref) [`BioClim`](@ref) data from [chelsa-climate.org](https://chelsa-climate.org/).

# Arguments
- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(CHELSA{BioClim}))`. 
    Without a `layer` argument, all layers will be downloaded, and a `Vector` of paths returned.

Returns the filepath/s of the downloaded or pre-existing files.
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
