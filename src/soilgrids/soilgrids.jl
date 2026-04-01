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

layers(::Type{SoilGrids}) = keys(SOILGRIDS_LAYERS)

depths(::Type{SoilGrids})               = SOILGRIDS_DEPTHS
depths(::Type{SoilGrids}, ::Val{:ocs})  = SOILGRIDS_OCS_DEPTHS
depths(::Type{SoilGrids}, ::Val)        = SOILGRIDS_DEPTHS  # fallback for all other layers
depths(T::Type{SoilGrids}, layer::Symbol) = depths(T, Val(layer))

getraster_keywords(::Type{SoilGrids}) = (:depth, :quantile)

_defdepth(::Type{SoilGrids}, ::Val)        = "0-5cm"
_defdepth(::Type{SoilGrids}, ::Val{:ocs})  = "0-30cm"

rasterpath(::Type{SoilGrids}) = joinpath(rasterpath(), "SoilGrids")
rasterpath(T::Type{SoilGrids}, layer::Symbol; depth, quantile) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; depth, quantile))

rastername(::Type{SoilGrids}, layer::Symbol; depth, quantile) =
    "$(layer)_$(depth)_$(quantile).vrt"

rasterurl(::Type{SoilGrids}) = SOILGRIDS_URI
rasterurl(T::Type{SoilGrids}, layer::Symbol; depth, quantile) =
    joinpath(SOILGRIDS_URI, string(layer), rastername(T, layer; depth, quantile))

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

# Public API — single layer
function getraster(T::Type{SoilGrids}, layer::Symbol;
        depth=_defdepth(T, Val(layer)), quantile="mean")
    _getraster(T, layer, depth, quantile)
end

# Public API — multiple layers as Tuple
function getraster(T::Type{SoilGrids}, ls::Tuple;
        depth=_defdepth(T, Val(:clay)), quantile="mean")
    _getraster(T, ls, depth, quantile)
end

# Array of depths → Vector (mirrors CHELSA{Climate} month-array pattern)
function _getraster(T::Type{SoilGrids}, layer_or_layers, depth::AbstractArray, quantile)
    _getraster.(T, Ref(layer_or_layers), depth, Ref(quantile))
end

# Tuple of layers, single depth → NamedTuple
function _getraster(T::Type{SoilGrids}, ls::Tuple, depth::AbstractString, quantile)
    _map_layers(T, ls, depth, quantile)
end

# Single layer, single depth → String (file path)
function _getraster(T::Type{SoilGrids}, layer::Symbol, depth::AbstractString, quantile)
    _check_layer(T, layer)
    _check_depth(T, layer, depth)
    _check_quantile(quantile)
    path = rasterpath(T, layer; depth, quantile)
    url  = rasterurl(T, layer; depth, quantile)
    _maybe_download(url, path)
end
