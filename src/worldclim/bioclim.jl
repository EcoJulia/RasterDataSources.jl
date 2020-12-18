layers(::Type{WorldClim{BioClim}}) = 1:19

"""
    getraster(T::Type{WorldClim{BioClim}}, [layer::Integer]; resolution::String="10m") => String

Download WorldClim weather data, choosing `layer` from $(layers(WorldClim{BioClim})),
and `resolution` from $(resolutions(WorldClim{BioClim})).

Without a layer argument, all layers will be getrastered, and a tuple of paths is returned. 
If the data is already getrastered the path will be returned.
"""
function getraster(T::Type{WorldClim{BioClim}}, layer::Integer; resolution::String="10m")
    _check_layer(T, layer)
    _check_resolution(T, resolution)

    raster_path = rasterpath(T, layer; resolution)
    zip_path = zippath(T, layer; resolution)

    if !isfile(raster_path)
        _maybe_download(zipurl(T, layer; resolution), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer; resolution)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

# BioClim layers don't get their own folder
rasterpath(T::Type{<:WorldClim{BioClim}}, layer; kw...) =
    joinpath(rasterpath(T), rastername(T, layer; kw...))
rastername(T::Type{<:WorldClim{BioClim}}, key; resolution) = "wc2.1_$(resolution)_bio_$key.tif"
zipname(T::Type{<:WorldClim{BioClim}}, key; resolution) = "wc2.1_$(resolution)_bio.zip"
zipurl(T::Type{<:WorldClim{BioClim}}, key; resolution) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, key; resolution))
zippath(T::Type{<:WorldClim{BioClim}}, key; resolution) =
    joinpath(rasterpath(T), "zips", zipname(T, key; resolution))
