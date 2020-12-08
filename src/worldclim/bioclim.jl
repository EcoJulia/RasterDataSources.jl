
function download_raster(T::Type{WorldClim{BioClim}}; layer::Integer=1, resolution::String="10m")
    _check_layer(T, layer)
    _check_resolution(T, resolution)

    raster_path = rasterpath(T, layer, resolution)
    zip_path = zippath(T, layer, resolution)

    if !isfile(raster_path)
        _maybe_download(zipurl(T, layer, resolution), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, layer, resolution)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

layers(::Type{WorldClim{BioClim}}) = 1:19
# BioClim layers don't get their own folder
rasterpath(T::Type{<:WorldClim{BioClim}}, layer) = rasterpath(T)
rastername(T::Type{<:WorldClim{BioClim}}, key, res) = "wc2.1_$(res)_bio_$key.tif"
zipname(T::Type{<:WorldClim{BioClim}}, key, res) = "wc2.1_$(res)_bio.zip"
zipurl(T::Type{<:WorldClim{BioClim}}, key, res) =
    joinpath(WORLDCLIM_URI, "base", zipname(T, key, res))
zippath(T::Type{<:WorldClim{BioClim}}, key, res) =
    joinpath(rasterpath(T), "zips", zipname(T, key, res))
