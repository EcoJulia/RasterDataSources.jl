
struct SRTM <: RasterDataSource end

# SRTM Mirror with 5x5 degree tiles
const SRTM_URI = URI(scheme = "https", host = "srtm.csi.cgiar.org", path = "/wp-content/uploads/files/srtm_5x5/TIFF")

resolutions(::Type{SRTM}) = ("30m",)
defres(::Type{SRTM}) = "30m"

function _raster_tile_stem(tile_index::CartesianIndex)
    y, x = tile_index.I
    "srtm_$(lpad(x, 2, '0'))_$(lpad(y, 2, '0'))"
end

rastername(::Type{SRTM}, tile_index::CartesianIndex) = _raster_tile_stem(tile_index) * ".tif"
rasterpath(::Type{SRTM}) = joinpath(rasterpath(), "SRTM")
rasterpath(T::Type{SRTM}, tile_index::CartesianIndex) = joinpath(rasterpath(T), rastername(T, tile_index))

zipname(::Type{SRTM}, tile_index) = _raster_tile_stem(tile_index) * ".zip"
zipurl(T::Type{SRTM}, tile_index) = joinpath(SRTM_URI, zipname(T, tile_index))
zippath(T::Type{SRTM}, tile_index) = joinpath(rasterpath(T), "zips", zipname(T, tile_index))


function getraster(T::Type{SRTM}, tile_index)
    raster_path = rasterpath(T, tile_index)
    if !isfile(raster_path)
        zip_path = zippath(T, tile_index)
        _maybe_download(zipurl(T, tile_index), zip_path)
        mkpath(dirname(raster_path))
        raster_name = rastername(T, tile_index)
        zf = ZipFile.Reader(zip_path)
        write(raster_path, read(_zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

getraster(T::Type{SRTM}, tile_indices::CartesianIndices{2}) = getraster.(T, tile_indices)

# Adapted from https://github.com/centreborelli/srtm4/blob/master/src/srtm4.c#L87-L117
function wgs84_to_tile_index(x, y)
    y = clamp(y, -60, 60)
    # tiles longitude indexes go from 1 to 72,
    # covering the range from -180 to +180
    tile_x = (1 + floor(Int, (x + 180) / 5)) % 72
    tile_x = tile_x == 0 ? 72 : tile_x

    tile_y = 1 + floor(Int, (60 - y) / 5)
    tile_y = tile_y == 25 ? 24 : tile_y
    CartesianIndex(tile_y, tile_x)
end


function getraster(T::Type{SRTM}, bounds::NTuple{4,Real})
    minx, miny, maxx, maxy = bounds
    _min = wgs84_to_tile_index(minx, miny)
    _max = wgs84_to_tile_index(maxx, maxy)
    getraster(T, _min:_max)
end