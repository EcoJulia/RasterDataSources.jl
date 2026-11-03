const SOILGRIDS_URI = URI(scheme="https", host="files.isric.org", path="/soilgrids/latest/data")

# Units are as stored, from https://docs.isric.org/globaldata/soilgrids/SoilGrids_faqs_01.html
const SOILGRIDS_LAYERS = (
    bdod     = (description="Bulk density",           units="cg/cm³"),
    cec      = (description="CEC buffered at pH 7",   units="mmol(c)/kg"),
    cfvo     = (description="Coarse fragments",       units="cm³/dm³"),
    clay     = (description="Clay",                   units="g/kg"),
    nitrogen = (description="Nitrogen",               units="cg/kg"),
    ocd      = (description="Organic carbon density", units="hg/m³"),
    ocs      = (description="Organic carbon stock",   units="t/ha"),
    phh2o    = (description="pH in water",            units="pH × 10"),
    sand     = (description="Sand",                   units="g/kg"),
    silt     = (description="Silt",                   units="g/kg"),
    soc      = (description="Soil organic carbon",    units="dg/kg"),
)

const SOILGRIDS_DEPTHS = ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
const SOILGRIDS_COMPONENTS = ("mean", "Q0.05", "Q0.5", "Q0.95", "uncertainty")

# Layers with a single depth, which ignore `depth`, and their depths
const SOILGRIDS_SINGLE_DEPTHS = (ocs="0-30cm",)

# The Interrupted Goode Homolosine projection of the SoilGrids tiles.
const GOODE_PROJ = "+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs"

function _soilgrids_layer_table()
    header = """
| Key | Description | Units |
|-----|-------------|-------|
"""
    rows = ["| $k | $(v.description) | $(v.units) |" for (k, v) in pairs(SOILGRIDS_LAYERS)]
    return header * join(rows, "\n")
end

"""
    SoilGrids <: RasterDataSource

Global soil properties at 250 m resolution from ISRIC World Soil Information, as
GeoTIFF tiles in the Interrupted Goode Homolosine projection. `getraster` downloads the
tiles intersecting `extent` and returns a `Vector` of their paths, which can be combined
with `Rasters.mosaic`. Finding the tiles needs Proj: run `import Proj` first.

See: [SoilGrids](https://www.isric.org/explore/soilgrids)

## Available layers

$(_soilgrids_layer_table())

Soil classes (`wrb`) and the land mask are not included.

Use `extent`, `depth` and `component` keywords with `getraster`:
- `extent`: an `Extents.Extent` in degrees of longitude and latitude. It is required.
- `depth`: $(join(SOILGRIDS_DEPTHS, ", ")), "$(first(SOILGRIDS_DEPTHS))" by default.
  `:ocs` is the stock over $(SOILGRIDS_SINGLE_DEPTHS.ocs), and ignores `depth`.
- `component`: $(join(SOILGRIDS_COMPONENTS, ", ")), "$(first(SOILGRIDS_COMPONENTS))" by default.

# Examples
```julia
import Proj
using RasterDataSources, Extents
extent = Extent(X=(10, 12), Y=(41, 43))
getraster(SoilGrids, :clay; extent, depth="0-5cm", component="mean")
getraster(SoilGrids, (:clay, :sand); extent, depth="5-15cm", component="Q0.05")
getraster(SoilGrids, :clay; extent, depth=["0-5cm", "5-15cm"]) # returns Vector
getraster(SoilGrids, :ocs; extent) # single-depth layer
```
"""
struct SoilGrids <: RasterDataSource end

layers(::Type{SoilGrids}) = keys(SOILGRIDS_LAYERS)
depths(::Type{SoilGrids}) = SOILGRIDS_DEPTHS
components(::Type{SoilGrids}) = SOILGRIDS_COMPONENTS
getraster_keywords(::Type{SoilGrids}) = (:extent, :depth, :component)

rasterpath(::Type{SoilGrids}) = joinpath(rasterpath(), "SoilGrids")

# The server holds one folder of tiles and one VRT index per layer, depth and component.
_dataset(layer, depth, component) = "$(layer)_$(get(SOILGRIDS_SINGLE_DEPTHS, layer, depth))_$(component)"
_rasterpath(T::Type{SoilGrids}, layer::Symbol; depth, component) =
    joinpath(rasterpath(T), string(layer), _dataset(layer, depth, component))
_rasterurl(::Type{SoilGrids}, layer::Symbol; depth, component) =
    joinpath(SOILGRIDS_URI, string(layer), _dataset(layer, depth, component))
_vrtpath(T::Type{SoilGrids}, layer::Symbol; depth, component) =
    joinpath(rasterpath(T), string(layer), _dataset(layer, depth, component) * ".vrt")
_vrturl(::Type{SoilGrids}, layer::Symbol; depth, component) =
    joinpath(SOILGRIDS_URI, string(layer), _dataset(layer, depth, component) * ".vrt")

# A tile is its file path within the dataset folder, e.g. "tileSG-028-080/tileSG-028-080_2-1.tif"
_has_tile(::Type{SoilGrids}, layer::Symbol, tile::AbstractString; kw...) = true
_rastername(::Type{SoilGrids}, layer::Symbol, tile::AbstractString; kw...) = basename(tile)
_rasterpath(T::Type{SoilGrids}, layer::Symbol, tile::AbstractString; kw...) =
    joinpath(_rasterpath(T, layer; kw...), split(tile, '/')...)
_rasterurl(T::Type{SoilGrids}, layer::Symbol, tile::AbstractString; kw...) =
    joinpath(_rasterurl(T, layer; kw...), tile)
_getraster(T::Type{SoilGrids}, layer::Symbol, tile::AbstractString; kw...) =
    _maybe_download(_rasterurl(T, layer, tile; kw...), _rasterpath(T, layer, tile; kw...))

function _tiles(T::Type{SoilGrids}, layer::Symbol, extent::Extents.Extent; kw...)
    _check_order(extent.X)
    _check_order(extent.Y)
    vrt = read(_maybe_download(_vrturl(T, layer; kw...), _vrtpath(T, layer; kw...)), String)
    [tile for (tile, tile_extent) in _tile_extents(_vrt_tiles(vrt)) if Extents.intersects(tile_extent, extent)]
end

# Each tile in a VRT index, as tile path => (x, y) bounds in metres of `GOODE_PROJ`.
function _vrt_tiles(vrt::AbstractString)
    # Origin and pixel size of the global grid, in metres
    geotransform = match(r"<GeoTransform>(.*?)</GeoTransform>", vrt)[1]
    x0, dx, _, y0, _, dy = parse.(Float64, split(geotransform, ','))
    # One block per tile
    map(eachmatch(r"<ComplexSource>.*?</ComplexSource>"s, vrt)) do source
        # Tile path, without the leading "./<dataset>/"
        tile = String(match(r"<SourceFilename[^>]*>\./[^/]+/(.*?)</SourceFilename>", source.match)[1])
        # Pixel offset and size of the tile in the global grid
        dstrect(name) = parse(Float64, match(Regex("<DstRect[^>]* $name=\"(.*?)\""), source.match)[1])
        col, row = dstrect("xOff"), dstrect("yOff")
        xs = x0 + dx * col, x0 + dx * (col + dstrect("xSize"))
        ys = y0 + dy * row, y0 + dy * (row + dstrect("ySize"))
        tile => (xs, ys)
    end
end

# Longitude/latitude extents of tiles from their bounds in metres of `GOODE_PROJ`.
function _tile_extents(tiles)
    edges = [_edge_points(xs, ys) for (_, (xs, ys)) in tiles]
    # Project all points in one call, so Proj is only set up once
    lonlats = Iterators.partition(goode_to_latlon(reduce(vcat, edges)), length(first(edges)))
    map(tiles, lonlats) do (tile, _), points
        # Points in the gaps between the projection's lobes are not finite
        points = filter(p -> all(isfinite, p), points)
        tile => Extents.Extent(X=extrema(first, points), Y=extrema(last, points))
    end
end

# Points along the edges of a rectangle. Edges are curved in longitude and latitude,
# so the corners alone do not bound it.
function _edge_points((x1, x2), (y1, y2); n=8)
    xs, ys = range(x1, x2; length=n), range(y1, y2; length=n)
    [[(x, y1) for x in xs]; [(x, y2) for x in xs]; [(x1, y) for y in ys]; [(x2, y) for y in ys]]
end

# Converts a `Vector` of `(x, y)` points in `GOODE_PROJ` to `(lon, lat)`, and to `(Inf, Inf)`
# in the gaps between its lobes. Defined in the Proj extension.
goode_to_latlon(args...) =
    error("This function call requires Proj to be loaded. Run `import Proj` to resolve this error")

for op in (:rastername, :rasterpath, :rasterurl)
    @eval function $op(T::Type{SoilGrids}, layer::Symbol; extent=nothing, depth, component)
        _check_dataset(T, layer, depth, component)
        _tiled($(Symbol('_', op)), extent, T, layer; depth, component)
    end
end

function getraster(T::Type{SoilGrids}, layers::Union{Symbol,Tuple};
    extent=nothing, depth=first(SOILGRIDS_DEPTHS), component=first(SOILGRIDS_COMPONENTS),
)
    _getraster(T, layers, extent, depth, component)
end

# Array of depths → Vector
_getraster(T::Type{SoilGrids}, layers, extent, depth::AbstractArray, component) =
    map(d -> _getraster(T, layers, extent, d, component), depth)
# Tuple of layers, single depth → NamedTuple
_getraster(T::Type{SoilGrids}, layers::Tuple, extent, depth::AbstractString, component) =
    _map_layers(T, layers, extent, depth, component)
# Single layer, single depth → Vector of tile paths
function _getraster(T::Type{SoilGrids}, layer::Symbol, extent, depth::AbstractString, component)
    _check_dataset(T, layer, depth, component)
    _tiled(_getraster, extent, T, layer; depth, component)
end

function _check_dataset(T, layer, depth, component)
    _check_layer(T, layer)
    _check_depth(T, depth)
    _check_component(T, component)
end
