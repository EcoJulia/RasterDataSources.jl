layers(::Type{CRU{Climate}}) = (:pre, :rd0, :tmp, :dtr, :reh, :sunp, :frs, :wnd, :elv)

function getraster(T::Type{CRU{Climate}}, layers::Union{Tuple,Symbol})
        _getraster(T, layers)
end

function _getraster(T::Type{CRU{Climate}}, layer::Symbol)
    _check_layer(T, layer)
    raster_path = rasterpath(T, layer)
    if !isfile(raster_path)
        zip_path = zippath(T, layer)
        _maybe_download(zipurl(T, layer), zip_path)
        mkpath(dirname(raster_path))
        open(zip_path) do io
            gz = GzipDecompressorStream(io)
            open(raster_path, "w") do out
                write(out, read(gz))
            end
            close(gz)
        end
    end
    return raster_path
end

# Climate layers don't get their own folder
rasterpath(T::Type{<:CRU{Climate}}, layer) = joinpath(_rasterpath(T), rastername(T, layer))
_rasterpath(T::Type{<:CRU{Climate}}) = rasterpath(T)
rastername(T::Type{<:CRU{Climate}}, layer) = "grid_10min_$(layer).dat"
zipname(T::Type{<:CRU{Climate}}, layer) = "grid_10min_$(layer).dat.gz"
zipurl(T::Type{<:CRU{Climate}}, layer) = joinpath(CRU_URI, zipname(T, layer))
zippath(T::Type{<:CRU{Climate}}, layer) = joinpath(rasterpath(T), "zips", zipname(T, layer))
datpath(T::Type{<:CRU{Climate}}, layer) = rasterpath(T, layer)