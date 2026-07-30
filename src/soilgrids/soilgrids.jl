const SOILGRIDS_URI = URI(scheme="https", host="files.isric.org", path="/soilgrids/latest/data")

const SOILGRIDS_LAYERS = (
    bdod     = "Bulk density (cg/cm³)",
    cec      = "Cation exchange capacity (mmolc/kg)",
    cfvo     = "Coarse fragments by volume (cm³/dm³)",
    clay     = "Clay content (g/100g)",
    nitrogen = "Total nitrogen (cg/kg)",
    ocd      = "Organic carbon density (hg/m³)",
    ocs      = "Organic carbon stocks (t/ha)",
    phh2o    = "Soil pH in water (pH×10)",
    sand     = "Sand content (g/100g)",
    silt     = "Silt content (g/100g)",
    soc      = "Soil organic carbon (dg/kg)",
)

const SOILGRIDS_DEPTHS     = ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
const SOILGRIDS_OCS_DEPTHS = ("0-30cm",)
const SOILGRIDS_QUANTILES  = ("Q0.05", "mean", "Q0.5", "Q0.95", "uncertainty")

function _soilgrids_layer_table()
    header = """
| Key      | Description                          |
|----------|--------------------------------------|
"""
    rows = [
        "| $(k) | $(v) |"
        for (k, v) in pairs(SOILGRIDS_LAYERS)
    ]
    return header * join(rows, "\n")
end

"""
    SoilGrids <: RasterDataSource

Global gridded soil property data at 250 m resolution from ISRIC World Soil Information,
on an Interrupted Goode Homolosine grid. Tiles intersecting `extent` are downloaded as
GeoTIFFs and cached locally; `getraster` returns a `Vector` of their paths. Combine them
into a single raster with `Rasters.mosaic`.

Requires `Proj` to be loaded (`import Proj`) to work out which tiles intersect `extent`.

## Available layers

$(_soilgrids_layer_table())

## Depths and quantiles

Use `extent`, `depth` and `quantile` keywords with `getraster`:

- `extent`: an `Extents.Extent` in lon/lat degrees, required. SoilGrids is a global
  250 m dataset, so a whole-layer download is not supported.
- `depth`: $(join(SOILGRIDS_DEPTHS, ", "))
  - `:ocs` only supports $(join(SOILGRIDS_OCS_DEPTHS, ", "))

- `quantile`: $(join(SOILGRIDS_QUANTILES, ", "))

# Examples
```julia
import Proj
using RasterDataSources, Extents

extent = Extent(X=(10, 12), Y=(41, 43))
getraster(SoilGrids, :clay; extent, depth="0-5cm", quantile="mean")           # Vector{String}
getraster(SoilGrids, (:clay, :sand); extent, depth="5-15cm", quantile="Q0.05") # NamedTuple of Vectors
getraster(SoilGrids, :clay; extent, depth=["0-5cm", "5-15cm"])                # Vector of Vectors
getraster(SoilGrids; extent, depth="0-5cm")                                   # all layers as NamedTuple

using Rasters
tiles = getraster(SoilGrids, :clay; extent, depth="0-5cm")
clay = mosaic(first, Raster.(tiles))
```
"""
struct SoilGrids <: RasterDataSource end

layers(::Type{SoilGrids}) = keys(SOILGRIDS_LAYERS)

depths(::Type{SoilGrids})               = SOILGRIDS_DEPTHS
depths(::Type{SoilGrids}, ::Val{:ocs})  = SOILGRIDS_OCS_DEPTHS
depths(::Type{SoilGrids}, ::Val)        = SOILGRIDS_DEPTHS  # other layers
depths(T::Type{SoilGrids}, layer::Symbol) = depths(T, Val(layer))

getraster_keywords(::Type{SoilGrids}) = (:extent, :depth, :quantile)

_defdepth(::Type{SoilGrids}, ::Val)        = "0-5cm"
_defdepth(::Type{SoilGrids}, ::Val{:ocs})  = "0-30cm"

rasterpath(::Type{SoilGrids}) = joinpath(rasterpath(), "SoilGrids")

function _check_depth(T::Type{SoilGrids}, layer::Symbol, depth::AbstractString)
    valid = depths(T, layer)
    depth in valid || throw(ArgumentError(
        "Depth \"$depth\" is not valid for layer :$layer. Valid depths: $(join(valid, ", "))"
    ))
end

function _check_quantile(quantile::AbstractString)
    quantile in SOILGRIDS_QUANTILES || throw(ArgumentError(
        "Quantile \"$quantile\" is not valid. Valid quantiles: $(join(SOILGRIDS_QUANTILES, ", "))"
    ))
end

"""
    latlon_to_projected(wkt::AbstractString, lons, lats)

Forward-transform WGS84 `(lon, lat)` coordinates into the projection described
by `wkt`, returning a collection of `(x, y)` tuples.

This function uses Proj for coordinate conversions. Use `import Proj` to make it available.
"""
latlon_to_projected(args...) =
    error("This function call requires Proj to be loaded. Run `import Proj` to resolve this error")

# Tiles sit on an Interrupted Goode Homolosine grid with irregular, landmass-clipped
# boundaries, so tile coverage is read from ISRIC's small per-layer/depth/quantile VRT
# rather than computed from a regular grid.

_index_vrt_name(layer::Symbol, depth::AbstractString, quantile::AbstractString) =
    "$(layer)_$(depth)_$(quantile).vrt"
_index_vrt_path(T::Type{SoilGrids}, layer::Symbol, depth::AbstractString, quantile::AbstractString) =
    joinpath(rasterpath(T), string(layer), "index", _index_vrt_name(layer, depth, quantile))
_index_vrt_url(layer::Symbol, depth::AbstractString, quantile::AbstractString) =
    joinpath(SOILGRIDS_URI, string(layer), _index_vrt_name(layer, depth, quantile))

function _soilgrids_index(T::Type{SoilGrids}, layer::Symbol, depth::AbstractString, quantile::AbstractString)
    path = _index_vrt_path(T, layer, depth, quantile)
    url  = _index_vrt_url(layer, depth, quantile)
    _maybe_download(url, path)
    _parse_soilgrids_vrt(path)
end

function _parse_soilgrids_vrt(path::AbstractString)
    vrt = read(path, String)
    geotransform = parse.(Float64,
        split(strip(match(r"<GeoTransform>\s*([^<]+)</GeoTransform>", vrt).captures[1]), ","))
    wkt = match(r"<SRS>(.*?)</SRS>"s, vrt).captures[1]
    tiles = map(eachmatch(r"<ComplexSource>(.*?)</ComplexSource>"s, vrt)) do block
        b = block.captures[1]
        relpath = match(r"<SourceFilename[^>]*>\./(.+?)</SourceFilename>", b).captures[1]
        r = match(r"<DstRect xOff=\"([\d.]+)\" yOff=\"([\d.]+)\" xSize=\"([\d.]+)\" ySize=\"([\d.]+)\" />", b)
        (relpath=String(relpath), xOff=parse(Float64, r.captures[1]), yOff=parse(Float64, r.captures[2]),
         xSize=parse(Float64, r.captures[3]), ySize=parse(Float64, r.captures[4]))
    end
    (; geotransform, wkt, tiles)
end

# Sample spacing/cap for `_select_tiles`; fine enough to resolve tiles, capped for speed.
const _SOILGRIDS_SAMPLE_STEP = 0.05
const _SOILGRIDS_MAX_SAMPLES_PER_AXIS = 120

function _sample_range(lo::Real, hi::Real)
    lo == hi && return (lo,)
    n = clamp(ceil(Int, (hi - lo) / _SOILGRIDS_SAMPLE_STEP) + 1, 2, _SOILGRIDS_MAX_SAMPLES_PER_AXIS)
    range(lo, hi; length=n)
end

# Point-sample `extent` (not a reprojected bounding box: IGH is interrupted, so a
# rectangular lon/lat extent can map to several disjoint regions) and hit-test each
# sample's pixel coordinate against tile `DstRect`s.
function _select_tiles(index, extent::Extents.Extent)
    xs, ys = extent.X, extent.Y
    _check_order(xs)
    _check_order(ys)
    lons = _sample_range(xs[1], xs[2])
    lats = _sample_range(ys[1], ys[2])
    samples = vec([(lon, lat) for lon in lons, lat in lats])
    xy = latlon_to_projected(index.wkt, first.(samples), last.(samples))

    originX, pixelW, _, originY, _, pixelH = index.geotransform
    cols = [(x - originX) / pixelW for (x, _) in xy]
    rows = [(y - originY) / pixelH for (_, y) in xy]

    # Coarse bbox pre-filter, then exact per-sample containment test.
    xmin, xmax = extrema(cols)
    ymin, ymax = extrema(rows)
    candidates = filter(index.tiles) do t
        t.xOff < xmax && t.xOff + t.xSize > xmin && t.yOff < ymax && t.yOff + t.ySize > ymin
    end

    hits = Set{Int}()
    for (col, row) in zip(cols, rows), (i, t) in enumerate(candidates)
        if t.xOff <= col < t.xOff + t.xSize && t.yOff <= row < t.yOff + t.ySize
            push!(hits, i)
        end
    end
    isempty(hits) && throw(ArgumentError("No SoilGrids tiles intersect extent=$extent"))
    return candidates[sort(collect(hits))]
end

_tile_path(T::Type{SoilGrids}, layer::Symbol, tile) =
    joinpath(rasterpath(T), string(layer), split(tile.relpath, '/')...)
_tile_url(layer::Symbol, tile) = joinpath(SOILGRIDS_URI, string(layer), tile.relpath)

function _resolve_tiles(T::Type{SoilGrids}, layer::Symbol, extent, depth::AbstractString, quantile::AbstractString)
    _check_layer(T, layer)
    _check_depth(T, layer, depth)
    _check_quantile(quantile)
    extent isa Extents.Extent || throw(ArgumentError(
        "`extent` keyword must be specified as an `Extents.Extent`, e.g. " *
        "extent=Extent(X=(10, 12), Y=(41, 43)). SoilGrids is a global 250 m dataset " *
        "so a whole-layer download is not supported."
    ))
    index = _soilgrids_index(T, layer, depth, quantile)
    _select_tiles(index, extent)
end

# Public API — single layer
function getraster(T::Type{SoilGrids}, layer::Symbol;
        extent=nothing, depth=_defdepth(T, Val(layer)), quantile="mean")
    _getraster(T, layer, extent, depth, quantile)
end

# Public API — multiple layers as Tuple
function getraster(T::Type{SoilGrids}, ls::Tuple;
        extent=nothing, depth=_defdepth(T, Val(:clay)), quantile="mean")
    _getraster(T, ls, extent, depth, quantile)
end

# Array of depths → Vector (mirrors CHELSA{Climate} month-array pattern)
function _getraster(T::Type{SoilGrids}, layer_or_layers, extent, depth::AbstractArray, quantile)
    _getraster.(T, Ref(layer_or_layers), Ref(extent), depth, Ref(quantile))
end

# Tuple of layers, single depth → NamedTuple
function _getraster(T::Type{SoilGrids}, ls::Tuple, extent, depth::AbstractString, quantile)
    _map_layers(T, ls, extent, depth, quantile)
end

# Single layer, single depth → Vector{String} of downloaded tile paths
function _getraster(T::Type{SoilGrids}, layer::Symbol, extent, depth::AbstractString, quantile)
    tiles = _resolve_tiles(T, layer, extent, depth, quantile)
    map(tiles) do t
        _maybe_download(_tile_url(layer, t), _tile_path(T, layer, t))
    end
end

rastername(T::Type{SoilGrids}, layer::Symbol; extent=nothing, depth=_defdepth(T, Val(layer)), quantile="mean") =
    [basename(t.relpath) for t in _resolve_tiles(T, layer, extent, depth, quantile)]

rasterpath(T::Type{SoilGrids}, layer::Symbol; extent=nothing, depth=_defdepth(T, Val(layer)), quantile="mean") =
    [_tile_path(T, layer, t) for t in _resolve_tiles(T, layer, extent, depth, quantile)]

rasterurl(::Type{SoilGrids}) = SOILGRIDS_URI
rasterurl(T::Type{SoilGrids}, layer::Symbol; extent=nothing, depth=_defdepth(T, Val(layer)), quantile="mean") =
    [_tile_url(layer, t) for t in _resolve_tiles(T, layer, extent, depth, quantile)]
