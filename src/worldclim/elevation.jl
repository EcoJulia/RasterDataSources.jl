layers(::Type{WorldClim{Elevation}}) = (:elev,)

getraster(T::Type{WorldClim{Elevation}}; kw...) = getraster(T, :elev; kw...)
function getraster(T::Type{WorldClim{Elevation}}, layers::Union{Tuple,Symbol}; 
    res::String=defres(T)
)
    _getraster(T, layers, res)
end

getraster_keywords(::Type{WorldClim{Elevation}}) = (:res,)

_getraster(T::Type{WorldClim{Elevation}}, layers::Tuple, res) = _map_layers(T, layers, res)
function _getraster(T::Type{WorldClim{Elevation}}, layer::Symbol, res)
    _check_layer(T, layer)
    _check_res(T, res)
    raster_path = rasterpath(T, layer; res)
    if !isfile(raster_path)
		zip_path = zippath(T, layer; res)
        _maybe_download(zipurl(T, layer; res), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer; res)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

rasterpath(T::Type{<:WorldClim{Elevation}}, layer; kw...) =
    joinpath(rasterpath(T), rastername(T, layer; kw...))
rastername(T::Type{<:WorldClim{Elevation}}, key; res) = "wc2.1_$(res)_elev.tif"
zipname(T::Type{<:WorldClim{Elevation}}, key; res) = "wc2.1_$(res)_elev.zip"
zipurl(T::Type{<:WorldClim{Elevation}}, key; res) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, key; res))
zippath(T::Type{<:WorldClim{Elevation}}, key; res) =
    joinpath(rasterpath(T), "zips", zipname(T, key; res))
