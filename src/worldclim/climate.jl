layers(::Type{WorldClim{Climate}}) = (:tmin, :tmax, :tavg, :prec, :srad, :wind, :vapr)

"""
    getraster(T::Type{WorldClim{Climate}}, [layer::Union{Tuple,Symbol}]; month, res::String="10m") => Vector{String}

Download [`WorldClim`](@ref) [`Climate`](@ref) data. 

# Arguments
- `layer` `Symbol` or `Tuple` of `Symbol` from `$(layers(WorldClim{Climate}))`. 
    Without a `layer` argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

# Keywords
- `month`: `Integer` or `AbstractArray` of `Integer`. Chosen from `1:12`.
- `res`: `String` chosen from $(resolutions(WorldClim{Climate})), "10m" by default.

Returns the filepath/s of the downloaded or pre-existing files.
"""
function getraster(T::Type{WorldClim{Climate}}, layers::Union{Tuple,Symbol}; 
    month, res::String=defres(T)
)
    _getraster(T, layers, month, res)
end

function _getraster(T::Type{WorldClim{Climate}}, layers, month::AbstractArray, res::String)
    _getraster.(T, Ref(layers), month, Ref(res))
end
function _getraster(T::Type{WorldClim{Climate}}, layers::Tuple, month::Integer, res::String)
    _map_layers(T, layers, month, res)
end
function _getraster(T::Type{WorldClim{Climate}}, layer::Symbol, month::Integer, res::String)
    _check_layer(T, layer)
    _check_res(T, res)
    raster_path = rasterpath(T, layer; res, month)
    if !isfile(raster_path)
        zip_path = zippath(T, layer; res, month)
        _maybe_download(zipurl(T, layer; res, month), zip_path)
        zf = ZipFile.Reader(zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer; res, month)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

# Climate layers don't get their own folder
rasterpath(T::Type{<:WorldClim{Climate}}, layer; res, month) =
    joinpath(_rasterpath(T, layer), rastername(T, layer; res, month))
_rasterpath(T::Type{<:WorldClim{Climate}}, layer) = joinpath(rasterpath(T), string(layer))
rastername(T::Type{<:WorldClim{Climate}}, layer; res, month) =
    "wc2.1_$(res)_$(layer)_$(_pad2(month)).tif"
zipname(T::Type{<:WorldClim{Climate}}, layer; res, month=1) =
    "wc2.1_$(res)_$(layer).zip"
zipurl(T::Type{<:WorldClim{Climate}}, layer; res, month=1) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, layer; res, month))
zippath(T::Type{<:WorldClim{Climate}}, layer; res, month=1) =
    joinpath(rasterpath(T), "zips", zipname(T, layer; res, month))

_pad2(month) = lpad(month, 2, '0')
