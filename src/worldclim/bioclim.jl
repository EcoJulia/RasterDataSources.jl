layers(::Type{WorldClim{BioClim}}) = 1:19

"""
    getraster(T::Type{WorldClim{BioClim}}, [layer::Union{Tuple,AbstractVector,Integer}]; res::String="10m") => Union{Tuple,AbstractVector,String}
    getraster(T::Type{WorldClim{BioClim}}, layer::Integer, res::String)

Download [`WorldClim`](@ref) [`BioClim`](@ref) data.

# Arguments
- `layer`: `Integer` or tuple/range of `Integer` from `$(layers(WorldClim{BioClim}))`. 
    Without a `layer` argument, all layers will be downloaded, and a `Vector` of paths returned.

# Keywords
- `res`: `String` chosen from $(resolutions(WorldClim{BioClim})), "10m" by default.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{WorldClim{BioClim}}, layer::Integer; res::String=defres(T))
    getraster(T, layer, res)
end
function getraster(T::Type{WorldClim{BioClim}}, layer::Integer, res::String)
    _check_layer(T, layer)
    _check_res(T, res)

    raster_path = rasterpath(T, layer; res)
    zip_path = zippath(T, layer; res)

    if !isfile(raster_path)
        _maybe_download(zipurl(T, layer; res), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer; res)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

# BioClim layers don't get their own folder
rasterpath(T::Type{<:WorldClim{BioClim}}, layer; kw...) =
    joinpath(rasterpath(T), rastername(T, layer; kw...))
rastername(T::Type{<:WorldClim{BioClim}}, key; res) = "wc2.1_$(res)_bio_$key.tif"
zipname(T::Type{<:WorldClim{BioClim}}, key; res) = "wc2.1_$(res)_bio.zip"
zipurl(T::Type{<:WorldClim{BioClim}}, key; res) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, key; res))
zippath(T::Type{<:WorldClim{BioClim}}, key; res) =
    joinpath(rasterpath(T), "zips", zipname(T, key; res))
