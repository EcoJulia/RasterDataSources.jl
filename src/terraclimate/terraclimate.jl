using URIs

abstract type TerraClimateCategory end
struct Historical <: TerraClimateCategory end
struct Plus2C <: TerraClimateCategory end
struct Plus4C <: TerraClimateCategory end
struct Climatology <: TerraClimateCategory end
struct Aggregated <: TerraClimateCategory end

const TERRACLIMATE_MAP = (
    aet = "aet",
    def = "def",
    pet = "pet",
    ppt = "ppt",
    q = "q",
    soil = "soil",
    srad = "srad",
    swe = "swe",
    tmax = "tmax",
    tmin = "tmin",
    vap = "vap",
    vpd = "vpd",
    ws = "ws",
    PDSI = "PDSI",
)

const CLIMATOLOGY_MAP = (
    aet = "aet",
    def = "def",
    pet = "pet",
    ppt = "ppt",
    q = "q",
    soil = "soil",
    srad = "srad",
    swe = "swe",
    tmax = "tmax",
    tmin = "tmin",
    vap = "vap",
    vpd = "vpd",
    ws = "ws",
    absmin = "absmin",
)

const AGGREGATED_MAP = (
    aet = "aet",
    def = "def",
    PDSI = "pdsi",
    pet = "pet",
    ppt = "ppt",
    q = "q",
    soil = "soil",
    srad = "srad",
    swe = "swe",
    tmax = "tmax",
    tmin = "tmin",
    vap = "vap",
    vpd = "vpd",
    ws = "ws",
)

"""
    TerraClimate{<:TerraClimateCategory} <: RasterDataSource

`TerraClimate` is a dataset of monthly climate and climatic water balance for global 
terrestrial surfaces at ~4-km spatial resolution, covering 1958-Present.

See: https://www.climatologylab.org/terraclimate.html

# Type Parameters
- `C`: The category of data to download. One of `Historical`, `Plus2C`, `Plus4C`, `Climatology`, or `Aggregated`.

# Usage
    getraster(TerraClimate{<category>}, layer; date=nothing, period=nothing)

# Keywords
- `date`: A `Date` or `DateTime` object. The year is used to select the file for `Historical`, `Plus2C`, and `Plus4C` data.
- `period`: A `String` representing the time period for `Climatology` and `Aggregated` data (e.g., "19611990", "1958_2021").

# Layers
| Layer Symbol | Description | Units | Categories |
| :--- | :--- | :--- | :--- |
| `:aet` | Actual Evapotranspiration | mm | All |
| `:def` | Climate Water Deficit | mm | All |
| `:pet` | Potential Evapotranspiration | mm | All |
| `:ppt` | Precipitation | mm | All |
| `:q` | Runoff | mm | All |
| `:soil` | Soil Moisture | mm | All |
| `:srad` | Downward shortwave radiation | W/m² | All |
| `:swe` | Snow water equivalent | mm | All |
| `:tmax` | Max Temperature | °C | All |
| `:tmin` | Min Temperature | °C | All |
| `:vap` | Vapor pressure | kPa | All |
| `:vpd` | Vapor Pressure Deficit | kPa | All |
| `:ws` | Wind speed | m/s | All |
| `:PDSI` | Palmer Drought Severity Index | unitless | `Historical`, `Plus2C`, `Plus4C`, `Aggregated` |
| `:absmin` | Absolute Min Temperature | °C | `Climatology` |

# Example
```julia
# Get the path to the 2001 historical data for the 'tmax' layer
getraster(TerraClimate{Historical}, :tmax; date=Date(2001))

# Get the path to the 1961-1990 climatology for the 'tmax' layer
getraster(TerraClimate{Climatology}, :tmax; period="19611990")
```
"""
struct TerraClimate{C<:TerraClimateCategory} <: RasterDataSource end

layers(::Type{<:TerraClimate{<:Union{Historical, Plus2C, Plus4C}}}) = keys(TERRACLIMATE_MAP)
layers(::Type{<:TerraClimate{Climatology}}) = keys(CLIMATOLOGY_MAP)
layers(::Type{<:TerraClimate{Aggregated}}) = keys(AGGREGATED_MAP)

# Data is in yearly files for time series data
date_step(::Type{<:TerraClimate{<:Union{Historical, Plus2C, Plus4C}}}) = Year(1)
# Climatology and Aggregated data is in single files, so date step is irrelevant
date_step(::Type{<:TerraClimate{<:Union{Climatology, Aggregated}}}) = Year(100) # Effectively a single step

getraster(T::Type{<:TerraClimate}, layer::Union{Tuple,Symbol}; date=nothing, period=nothing) =
    _getraster(T, layer, date, period)

getraster_keywords(::Type{<:TerraClimate}) = (:date, :period)

function _getraster(T::Type{<:TerraClimate}, layer::Union{Tuple,Symbol}, date, period)
    _getraster(T, layer, date_sequence(T, date), period)
end
function _getraster(T::Type{<:TerraClimate}, layers::Union{Tuple,Symbol}, dates::AbstractArray, period)
    _getraster.(T, Ref(layers), dates, Ref(period))
end
function _getraster(T::Type{<:TerraClimate{C}}, layers::Tuple, date::Union{Dates.TimeType, Nothing}, period) where {C}
    _map_layers(T, layers, date, period)
end
function _getraster(T::Type{<:TerraClimate{C}}, layer::Symbol, date::Union{Dates.TimeType, Nothing}, period) where {C}
    _check_layer(T, layer)
    raster_path = rasterpath(T, layer; date=date, period=period)
    mkpath(dirname(raster_path))
    if !isfile(raster_path)
        filename_part = _get_filename_part(T, layer)
        url = rasterurl(T, filename_part, date, period)
        _maybe_download(url, raster_path)
    end
    return raster_path
end

_get_filename_part(::Type{<:TerraClimate{<:Union{Historical, Plus2C, Plus4C}}}, layer) = TERRACLIMATE_MAP[layer]
_get_filename_part(::Type{<:TerraClimate{Climatology}}, layer) = CLIMATOLOGY_MAP[layer]
_get_filename_part(::Type{<:TerraClimate{Aggregated}}, layer) = AGGREGATED_MAP[layer]

rasterpath(T::Type{<:TerraClimate}) = joinpath(rasterpath(), "TerraClimate")
function rasterpath(T::Type{<:TerraClimate{C}}, layer; date, period) where {C}
    filename_part = _get_filename_part(T, layer)
    joinpath(_rasterpath(T), rastername(T, filename_part; date=date, period=period))
end

_rasterpath(T::Type{<:TerraClimate{C}}) where {C} = joinpath(rasterpath(T), _category_path(C))

rastername(::Type{<:TerraClimate{Historical}}, filename_part; date, period) = "TerraClimate_$(filename_part)_$(year(date)).nc"
rastername(::Type{<:TerraClimate{Plus2C}}, filename_part; date, period) = "TerraClimate_2c_$(filename_part)_$(year(date)).nc"
rastername(::Type{<:TerraClimate{Plus4C}}, filename_part; date, period) = "TerraClimate_4c_$(filename_part)_$(year(date)).nc"
rastername(::Type{<:TerraClimate{Climatology}}, filename_part; date, period) = "TerraClimate$(period)_$(filename_part).nc"
rastername(::Type{<:TerraClimate{Aggregated}}, filename_part; date, period) = "TerraClimate_$(filename_part)_$(period).nc"


function rasterurl(T::Type{<:TerraClimate{C}}, filename_part, date, period) where {C}
    base_url = "http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/"
    path = _url_path(C)
    name = rastername(T, filename_part; date=date, period=period)
    uri = URI(base_url)
    return URI(string(uri, path, "/", name))
end

_category_path(::Type{Historical}) = "Historical"
_category_path(::Type{Plus2C}) = "Plus2C"
_category_path(::Type{Plus4C}) = "Plus4C"
_category_path(::Type{Climatology}) = "Climatology"
_category_path(::Type{Aggregated}) = "Aggregated"

_url_path(::Type{Historical}) = "data"
_url_path(::Type{Plus2C}) = "data_plus2C"
_url_path(::Type{Plus4C}) = "data_plus4C"
_url_path(::Type{Climatology}) = "summaries"
_url_path(::Type{Aggregated}) = "aggregated"

_dateformat(::Type{<:TerraClimate}) = DateFormat("yyyymmdd")