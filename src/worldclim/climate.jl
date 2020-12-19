layers(::Type{WorldClim{Climate}}) = (:tmin, :tmax, :tavg, :prec, :srad, :wind, :vapr)

"""
    getraster(T::Type{WorldClim{Climate}}, [layer::Symbol]; resolution::String="10m", month=1:12) => Vector{String}

Download WorldClim weather data, choosing `layer` from $(layers(WorldClim{Climate})),
and `resolution` from $(resolutions(WorldClim{Climate})), and months from `1:12`.

Without a layer argument, all layers will be getrastered, and a tuple of paths is returned. 
By default all months are getrastered, but can also be getrastered individually.
If the data is already getrastered the path will be returned.
"""
function getraster(T::Type{WorldClim{Climate}}, layer; resolution::String="10m", month=1:12)
    _getraster(T, layer, resolution, month)
end

function _getraster(T::Type{WorldClim{Climate}}, layers, resolution, months)
    map(l -> _getraster(T, l, resolution, months), layers)
end
function _getraster(T::Type{WorldClim{Climate}}, layer::Symbol, resolution, months)
    map(m -> _getraster(T, layer, resolution, m), months)
end
function _getraster(T::Type{WorldClim{Climate}}, layer::Symbol, resolution, month::Integer)
    _check_layer(T, layer)
    _check_resolution(T, resolution)
    raster_path = rasterpath(T, layer; resolution, month)
    if !isfile(raster_path)
        zip_path = zippath(T, layer; resolution, month)
        _maybe_download(zipurl(T, layer; resolution, month), zip_path)
        zf = ZipFile.Reader(zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer; resolution, month)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

# Climate layers don't get their own folder
rasterpath(T::Type{<:WorldClim{Climate}}, layer; resolution, month) = 
    joinpath(_rasterpath(T, layer), rastername(T, layer; resolution, month))
_rasterpath(T::Type{<:WorldClim{Climate}}, layer) = joinpath(rasterpath(T), string(layer))
rastername(T::Type{<:WorldClim{Climate}}, layer; resolution, month) = 
    "wc2.1_$(resolution)_$(layer)_$(_pad2(month)).tif"
zipname(T::Type{<:WorldClim{Climate}}, layer; resolution, month=1) = 
    "wc2.1_$(resolution)_$(layer).zip"
zipurl(T::Type{<:WorldClim{Climate}}, layer; resolution, month=1) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, layer; resolution, month))
zippath(T::Type{<:WorldClim{Climate}}, layer; resolution, month=1) =
    joinpath(rasterpath(T), "zips", zipname(T, layer; resolution, month))

_pad2(month) = lpad(month, 2, '0')
