
download_raster(T::Type{WorldClim{Climate}}, layer; resolution::String="10m", month=1:12) =
    _download_raster(T, layer, resolution, month)

function _download_raster(T::Type{WorldClim{Climate}}, layers, resolution, months)
    map(l -> _download_raster(T, l, resolution, months), layers)
end
function _download_raster(T::Type{WorldClim{Climate}}, layer::Symbol, resolution, months)
    map(m -> _download_raster(T, layer, resolution, m), months)
end
function _download_raster(T::Type{WorldClim{Climate}}, layer::Symbol, resolution, month::Integer)
    _check_layer(T, layer)
    _check_resolution(T, resolution)
    raster_path = rasterpath(T, layer, resolution, month)
    if !isfile(raster_path)
        zip_path = zippath(T, layer, resolution, month)
        _maybe_download(zipurl(T, layer, resolution, month), zip_path)
        zf = ZipFile.Reader(zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer, resolution, month)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

layers(::Type{WorldClim{Climate}}) = (:tmin, :tmax, :tave, :prec, :srad, :wind, :vapr)
# Climate layers don't get their own folder
rasterpath(T::Type{<:WorldClim{Climate}}, layer) = joinpath(rasterpath(T), string(layer))
rasterpath(T::Type{<:WorldClim{Climate}}, layer, res, month) = 
    joinpath(rasterpath(T, layer), rastername(T, layer, res, month))
rastername(T::Type{<:WorldClim{Climate}}, layer, res, month) = "wc2.1_$(res)_$(layer)_$(_pad2(month)).tif"
zipname(T::Type{<:WorldClim{Climate}}, layer, res, month=1) = "wc2.1_$(res)_$(layer).zip"
zipurl(T::Type{<:WorldClim{Climate}}, layer, res, month=1) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, layer, res, month))
zippath(T::Type{<:WorldClim{Climate}}, layer, res, month=1) =
    joinpath(rasterpath(T), "zips", zipname(T, layer, res, month))

_pad2(month) = lpad(month, 2, '0')
