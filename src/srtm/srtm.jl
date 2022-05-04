
struct SRTM <: RasterDataSource end

# SRTM Mirror with 5x5 degree tiles
const SRTM_URI = URI(scheme = "https", host = "srtm.csi.cgiar.org", path = "/wp-content/uploads/files/srtm_5x5/TIFF")

const HAS_SRTM_TILE = BitArray([
    0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  1  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0
    0  1  1  1  1  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  1  1  1  1  1
    0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0
    0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0
    0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  1  1  1  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0
    0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  1  0  0  0  0  0  0  0  0  1  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0
    1  1  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  0  0  0  0  0  0  0
    0  0  1  1  1  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0
    0  0  1  0  1  1  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  1  0  0  0  1  0  0
    0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  1  1  1  1  1  1  1  1  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  1  1  1  0  1  1  1  1  1  1  1  1  0  1  1  1  0  0  1  1  1  0
    0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  1  1  1  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0
    1  0  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  1  1  0  1  1  1  1  1  1  1  1  1  0  0  0  0  1  0  0  0  0  1  1  1  1  1  1  1  1  0  0  0  1  0  0  1  1  0
    0  1  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  0  1  1  0  0  1  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  1  1
    0  1  0  1  1  1  0  1  1  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  0  0  0  1  0  0  0  0  1  1  1  1  1  1  0  1  1  1  0  0  1  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1
    1  1  1  1  0  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  1  0  1  0  1  1  1  1  1  1  1  1  1  1  1  1  1
    1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  0  0  0  0  0  1  0  0  0  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1
    1  1  0  0  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  0  0  1  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  0  1  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  0
    1  0  0  0  0  0  0  1  0  1  0  0  0  0  1  0  0  0  0  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  0  0  1  0  0
    1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  1  0
    0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  1  0  0  0  1  1  1  1  0  0  0  1  1
    1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0  0  0  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  0  0  1  1  1
    0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  1  0  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1
    0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  0  0  0  1  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  1  0  0
    0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0
])

function _raster_tile_stem(tile_index::CartesianIndex)
    y, x = tile_index.I
    "srtm_$(lpad(x, 2, '0'))_$(lpad(y, 2, '0'))"
end

_rastername(::Type{SRTM}, tile_index::CartesianIndex{2}) = _raster_tile_stem(tile_index) * ".tif"
_rasterpath(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(rasterpath(), "SRTM", _rastername(T, tile_index))

_zipname(::Type{SRTM}, tile_index::CartesianIndex{2}) = _raster_tile_stem(tile_index) * ".zip"
_zipurl(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(SRTM_URI, _zipname(T, tile_index))
_zippath(T::Type{SRTM}, tile_index::CartesianIndex{2}) = joinpath(rasterpath(), "SRTM", "zips", _zipname(T, tile_index))


function _getraster(T::Type{SRTM}, tile_index::CartesianIndex{2})
    raster_path = _rasterpath(T, tile_index)
    if !isfile(raster_path)
        @info "Note: not all oceanic tiles exist in the SRTM dataset."
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
function _wgs84_to_tile_x(x)
    # tiles longitude indexes go from 1 to 72,
    # covering the range from -180 to +180
    tile_x = (1 + floor(Int, (x + 180) / 5)) % 72
    return tile_x == 0 ? 72 : tile_x
end

function _wgs84_to_tile_y(y)
    y = clamp(y, -60, 60)
    tile_y = 1 + floor(Int, (60 - y) / 5)
    return tile_y == 25 ? 24 : tile_y
end

function bounds_to_tile_indices(::Type{SRTM}, bounds::NTuple{4,Real})
    bounds_to_tile_indices(SRTM, ((bounds[1], bounds[3]), (bounds[2], bounds[4])))
end
function bounds_to_tile_indices(::Type{SRTM}, (xs, ys)::NTuple{2,NTuple{2,Real}})
    _check_order(xs)
    _check_order(ys)
    t_xs = _wgs84_to_tile_x.(xs)
    t_ys = reverse(_wgs84_to_tile_y.(ys))
    @show t_xs t_ys
    return CartesianIndices((t_ys[1]:(t_ys[2]), t_xs[1]:(t_xs[2])))
end

_check_order((a, b)) = a > b && throw(ArgumentError("Upper bound $b less than lower bound $a"))

for op in (:getraster, :rastername, :rasterpath, :zipname, :zipurl, :zippath)
    _op = Symbol('_', op) # Name of internal function
    @eval begin
        # Broadcasting function dispatch
        function $_op(T::Type{SRTM}, tile_index::CartesianIndices) 
            broadcast(tile_index) do I
                HAS_SRTM_TILE[I] ? $_op(T, I) : missing
            end
        end
        # Bounds to tile indices dispatch
        $_op(T::Type{SRTM}, bounds::Tuple) = $_op(T, bounds_to_tile_indices(T, bounds))

        # Public function definition with key-word arguments
        function $op(T::Type{SRTM}; bounds=nothing, tile_index=nothing)
            if isnothing(bounds) & isnothing(tile_index)
                :op === :getraster || return joinpath(rasterpath(), "SRTM")
                throw(ArgumentError("One of `bounds` or `tile_index` kwarg must be specified"))
            elseif !isnothing(bounds) & !isnothing(tile_index)
                throw(ArgumentError("Only one of `bounds` or `tile_index` should be specified. " *
                                    "found `bounds`=$bounds and `tile_index`=$tile_index"))
            else
                # Call the internal function without key-word arguments
                return $_op(T, isnothing(tile_index) ? bounds : tile_index)
            end
        end
    end
end
