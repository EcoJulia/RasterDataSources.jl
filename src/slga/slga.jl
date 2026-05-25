const SLGA_URI = URI(scheme="https", host="esoil.io",
    path="/TERNLandscapes/Public/Products/TERN/SLGA")

# Per-attribute metadata: (code, description, units, date, middle-suffix-after-component)
const SLGA_ATTRS = (
    clay = (code="CLY", description="Clay content",                             units="%",        date="20210902", suffix="_N_P_AU_TRN_N"),
    silt = (code="SLT", description="Silt content",                             units="%",        date="20210902", suffix="_N_P_AU_TRN_N"),
    sand = (code="SND", description="Sand content",                             units="%",        date="20210902", suffix="_N_P_AU_TRN_N"),
    bdod = (code="BDW", description="Bulk density (whole soil)",                units="g/cm³",    date="20230607", suffix="_N_P_AU_TRN_N"),
    soc  = (code="SOC", description="Soil organic carbon",                      units="%",        date="20220727", suffix="_N_P_AU_TRN_N"),
    phc  = (code="PHC", description="pH (CaCl\u2082)",                          units="\u2014",   date="20210913", suffix="_N_P_AU_NAT_C"),
    phw  = (code="PHW", description="pH (water)",                               units="\u2014",   date="20220520", suffix="_N_P_AU_TRN_N"),
    awc  = (code="AWC", description="Available water capacity",                 units="% vol",    date="20210614", suffix="_N_P_AU_TRN_N"),
    ece  = (code="ECE", description="Effective cation exchange capacity",       units="meq/100g", date="20140801", suffix="_N_P_AU_NAT_C"),
    cec  = (code="CEC", description="Cation exchange capacity",                 units="meq/100g", date="20220826", suffix="_N_P_AU_TRN_N"),
    nto  = (code="NTO", description="Total nitrogen",                           units="%",        date="20231101", suffix="_N_P_AU_NAT_C"),
    pto  = (code="PTO", description="Total phosphorus",                         units="%",        date="20231101", suffix="_N_P_AU_NAT_C"),
    avp  = (code="AVP", description="Available phosphorus (Colwell)",           units="mg/kg",    date="20220826", suffix="_N_P_AU_TRN_N"),
    dul  = (code="DUL", description="Drained upper limit (field capacity)",     units="% vol",    date="20210614", suffix="_N_P_AU_TRN_N"),
    l15  = (code="L15", description="Lower limit (wilting point, -1500 kPa)",   units="% vol",    date="20210614", suffix="_N_P_AU_TRN_N"),
    der  = (code="DER", description="Depth to a restricting layer",             units="m",        date="20150601", suffix="_N_P_AU_NAT_C"),
    des  = (code="DES", description="Depth of soil (regolith)",                 units="m",        date="20190901", suffix="_N_P_AU_TRN_C"),
)

const SLGA_DEPTH_CODES = Dict(  # human-readable → SLGA internal underscore format
    "0-5cm"     => "000_005",
    "5-15cm"    => "005_015",
    "15-30cm"   => "015_030",
    "30-60cm"   => "030_060",
    "60-100cm"  => "060_100",
    "100-200cm" => "100_200",
    "0-999cm"   => "000_999",
    "0-200cm"   => "000_200",
)

const SLGA_DEPTHS     = ("0-5cm", "5-15cm", "15-30cm", "30-60cm", "60-100cm", "100-200cm")
const SLGA_COMPONENTS = ("EV", "05", "95")

# Single-depth layers and their fixed depths
const SLGA_SINGLE_DEPTHS = (der="0-999cm", des="0-200cm")

function _slga_attr_table()
    header = """
| Key  | Code | Description                                      | Units      | Date Created     |
|------|------|--------------------------------------------------|------------|------------------|
"""
    rows = [
        "| $(k) | $(v.code) | $(v.description) | $(v.units) | $(v.date) |"
        for (k, v) in pairs(SLGA_ATTRS)
    ]
    return header * join(rows, "\n")
end

"""
    SLGA <: RasterDataSource

Soil and Landscape Grid of Australia at ~90 m (3 arcsecond) resolution from CSIRO/TERN.
Files are Cloud Optimised GeoTIFFs in WGS84 (EPSG:4326), covering continental Australia.

## Available layers

$(_slga_attr_table())

Coarse fragments (`cfg`) have a distinct multi-file structure; use [`SLGA{CoarseFragments}`](@ref CoarseFragments) instead.

Use `depth` and `component` keywords with `getraster`:
- `depth`: $(join(SLGA_DEPTHS, ", "))
  - `:der` only supports "$(SLGA_SINGLE_DEPTHS.der)"
  - `:des` only supports "$(SLGA_SINGLE_DEPTHS.des)"

- `component`: $(join(SLGA_COMPONENTS, ", "))

# Examples
```julia
getraster(SLGA, :clay; depth="0-5cm", component="EV")
getraster(SLGA, :clay; component="EV") # returns all depths
getraster(SLGA, (:clay, :sand); depth="5-15cm", component="05")
getraster(SLGA, :clay; depth=["0-5cm", "5-15cm"])   # returns Vector
getraster(SLGA, :der) # single-depth layer
```
"""
struct SLGA{X} <: RasterDataSource end

layers(::Type{SLGA}) = Tuple(keys(SLGA_ATTRS))

depths(::Type{SLGA}) = SLGA_DEPTHS
depths(T::Type{SLGA}, layer::Symbol) = 
    haskey(SLGA_SINGLE_DEPTHS, layer) ? (SLGA_SINGLE_DEPTHS[layer],) : SLGA_DEPTHS

getraster_keywords(::Type{SLGA}) = (:depth, :component)

function rastername(::Type{SLGA}, layer::Symbol; depth, component)
    attr  = SLGA_ATTRS[layer]
    dcode = SLGA_DEPTH_CODES[depth]
    "$(attr.code)_$(dcode)_$(component)$(attr.suffix)_$(attr.date).tif"
end

rasterpath(::Type{SLGA}) = joinpath(rasterpath(), "SLGA")
rasterpath(T::Type{SLGA}, layer::Symbol; depth, component) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; depth, component))

rasterurl(::Type{SLGA}) = SLGA_URI
rasterurl(T::Type{SLGA}, layer::Symbol; depth, component) =
    joinpath(SLGA_URI, SLGA_ATTRS[layer].code, rastername(T, layer; depth, component))

# Public API — single layer
function getraster(T::Type{SLGA}, layer::Symbol;
    depth=_defdepth(T, layer), component="EV"
)
    _getraster(T, layer, depth, component)
end
# Public API — multiple layers as Tuple
function getraster(T::Type{SLGA}, ls::Tuple;
    depth=_defdepth(T, :clay), component="EV"
)
    _getraster(T, ls, depth, component)
end

# Array of depths → Vector (mirrors CHELSA{Climate} month-array and SoilGrids patterns)
function _getraster(T::Type{SLGA}, layer_or_layers, depth::AbstractArray, component)
    _getraster.(T, Ref(layer_or_layers), depth, Ref(component))
end
# Tuple of layers, single depth → NamedTuple
function _getraster(T::Type{SLGA}, ls::Tuple, depth::AbstractString, component)
    _map_layers(T, ls, depth, component)
end
# Single layer, single depth → String (file path)
function _getraster(T::Type{SLGA}, layer::Symbol, depth::AbstractString, component)
    _check_layer(T, layer)
    _check_depth(T, layer, depth)
    _check_component(component)
    path = rasterpath(T, layer; depth, component)
    url  = rasterurl(T, layer; depth, component)
    _maybe_download(url, path)
end

_defdepth(::Type{SLGA}, layer::Symbol) =
    haskey(SLGA_SINGLE_DEPTHS, layer) ? SLGA_SINGLE_DEPTHS[layer] : "0-5cm"

function _check_depth(T::Type{SLGA}, layer::Symbol, depth::AbstractString)
    valid = depths(T, layer)
    depth in valid || throw(ArgumentError(
        "Depth \"$depth\" is not valid for layer :$layer. Valid depths: $(join(valid, ", "))"
    ))
end

function _check_component(component::AbstractString)
    component in SLGA_COMPONENTS || throw(ArgumentError(
        "Component \"$component\" is not valid. Use one of: $(join(SLGA_COMPONENTS, ", "))"
    ))
end
