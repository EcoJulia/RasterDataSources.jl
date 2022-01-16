
struct SRTM <: RasterDataSource end

# SRTM Mirror with 5x5 degree tiles
const SRTM_URI = URI(scheme = "https", host = "srtm.csi.cgiar.org", path = "/wp-content/uploads/files/srtm_5x5/TIFF")

function _raster_tile_stem(tile_index::CartesianIndex)
    y, x = tile_index.I
    "srtm_$(lpad(x, 2, '0'))_$(lpad(y, 2, '0'))"
end

_rastername(::Type{SRTM}, tile_index::CartesianIndex{2}) = _raster_tile_stem(tile_index) * ".tif"
_rasterpath(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(rasterpath(), "SRTM", _rastername(T, tile_index))

_zipname(::Type{SRTM}, tile_index::CartesianIndex{2}) = _raster_tile_stem(tile_index) * ".zip"
_zipurl(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(SRTM_URI, _zipname(T, tile_index))
_zippath(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(rasterpath(), "SRTM", "zips", zipname(T, tile_index))


function _getraster(T::Type{SRTM}, tile_index::CartesianIndex{2})
    raster_path = _rasterpath(T, tile_index)
    if !isfile(raster_path)
        zip_path = _zippath(T, tile_index)
        _maybe_download(_zipurl(T, tile_index), zip_path)
        mkpath(dirname(raster_path))
        raster_name = _rastername(T, tile_index)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end


# Adapted from https://github.com/centreborelli/srtm4/blob/master/src/srtm4.c#L87-L117
function _wgs84_to_tile_index(x, y)
    y = clamp(y, -60, 60)
    # tiles longitude indexes go from 1 to 72,
    # covering the range from -180 to +180
    tile_x = (1 + floor(Int, (x + 180) / 5)) % 72
    tile_x = tile_x == 0 ? 72 : tile_x

    tile_y = 1 + floor(Int, (60 - y) / 5)
    tile_y = tile_y == 25 ? 24 : tile_y
    CartesianIndex(tile_y, tile_x)
end


function bounds_to_tile_indices(::Type{SRTM}, bounds::NTuple{4,Real})
    minx, miny, maxx, maxy = bounds
    _min = _wgs84_to_tile_index(minx, miny)
    _max = _wgs84_to_tile_index(maxx, maxy)
    _min:_max
end


for op in (:getraster, :rastername, :rasterpath, :zipname, :zipurl, :zippath)
    _op = Symbol('_', op) # Name of internal function
    @eval begin
        # Broadcasting function dispatch
        $_op(T::Type{SRTM}, tile_index::CartesianIndices) = $(_op).(T, tile_index)
        # Bounds to tile indices dispatch
        $_op(T::Type{SRTM}, bounds::NTuple{4,Real}) = $_op(T, bounds_to_tile_indices(T, bounds))

        # Public function definition with key-word arguments
        function $op(T::Type{SRTM}; bounds=nothing, tile_index=nothing)
            if isnothing(bounds) & isnothing(tile_index)
                :op === :getraster || return joinpath(rasterpath(), "SRTM")
                throw(ArgumentError("One of `bounds` or `tile_index` kwarg must be specified"))
            elseif !isnothing(bounds) & !isnothing(tile_index)
                throw(ArgumentError("Only on of `bounds` or `tile_index` should be specified. " *
                                    "found `bounds`=$bounds and `tile_index`=$tile_index"))
            else
                # Call the internal function without key-word arguments
                return $_op(T, isnothing(tile_index) ? bounds : tile_index)
            end
        end
    end
end