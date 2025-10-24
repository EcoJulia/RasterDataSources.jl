
using URIs

abstract type TerraClimateCategory end
struct Historical <: TerraClimateCategory end
struct Plus2C <: TerraClimateCategory end
struct Plus4C <: TerraClimateCategory end

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

"""
    TerraClimate{<:TerraClimateCategory} <: RasterDataSource

Data from the TerraClimate dataset.

See: https://www.climatologylab.org/terraclimate.html

# Type Parameters
- `C`: The category of data to download. One of `Historical`, `Plus2C`, or `Plus4C`.

# Usage with `getraster`
    getraster(TerraClimate{<category>}, layer; date)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` for `layer`s.

# Keywords
- `date`: A `Date` or `DateTime` object. The year of the date is used to select the file to download.

# Layers
| Layer Symbol | Description                      | Units     |
| :----------- | :------------------------------- | :-------- |
| `:aet`       | Actual Evapotranspiration        | mm        |
| `:def`       | Climate Water Deficit            | mm        |
| `:pet`       | Potential Evapotranspiration     | mm        |
| `:ppt`       | Precipitation                    | mm        |
| `:q`         | Runoff                           | mm        |
| `:soil`      | Soil Moisture                    | mm        |
| `:srad`      | Downward surface shortwave radiation | W/m²      |
| `:swe`       | Snow water equivalent            | mm        |
| `:tmax`      | Maximum Temperature              | °C        |
| `:tmin`      | Minimum Temperature              | °C        |
| `:vap`       | Vapor pressure                   | kPa       |
| `:vpd`       | Vapor Pressure Deficit           | kPa       |
| `:ws`        | Wind speed                       | m/s       |
| `:PDSI`      | Palmer Drought Severity Index    | unitless  |

# Example
```julia
# Get the path to the 2001 historical data for the 'tmax' layer
getraster(TerraClimate{Historical}, :tmax; date=Date(2001))
```
"""
struct TerraClimate{C<:TerraClimateCategory} <: RasterDataSource end

layers(::Type{<:TerraClimate}) = keys(TERRACLIMATE_MAP)

# Data is in yearly files
date_step(::Type{<:TerraClimate}) = Year(1)

getraster(T::Type{<:TerraClimate}, layer::Union{Tuple,Symbol}; date) =
    _getraster(T, layer, date)

getraster_keywords(::Type{<:TerraClimate}) = (:date,)

function _getraster(T::Type{<:TerraClimate}, layer::Union{Tuple,Symbol}, dates::Tuple{<:Any,<:Any})
    _getraster(T, layer, date_sequence(T, dates))
end
function _getraster(T::Type{<:TerraClimate}, layers::Union{Tuple,Symbol}, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{<:TerraClimate{C}}, layers::Tuple, date::Dates.TimeType) where {C}
    _map_layers(T, layers, date)
end
function _getraster(T::Type{<:TerraClimate{C}}, layer::Symbol, date::Dates.TimeType) where {C}
    _check_layer(T, layer)
    raster_path = rasterpath(T, layer; date=date)
    mkpath(dirname(raster_path))
    if !isfile(raster_path)
        filename_part = _get_filename_part(T, layer)
        url = rasterurl(T, filename_part, date)
        _maybe_download(url, raster_path)
    end
    return raster_path
end

_get_filename_part(::Type{<:TerraClimate}, layer) = TERRACLIMATE_MAP[layer]

rasterpath(T::Type{<:TerraClimate}) = joinpath(rasterpath(), "TerraClimate")
function rasterpath(T::Type{<:TerraClimate{C}}, layer; date) where {C}
    filename_part = _get_filename_part(T, layer)
    joinpath(_rasterpath(T), rastername(T, filename_part; date=date))
end

_rasterpath(T::Type{<:TerraClimate{C}}) where {C} = joinpath(rasterpath(T), _category_path(C))

rastername(::Type{<:TerraClimate{Historical}}, filename_part; date) = "TerraClimate_$(filename_part)_$(year(date)).nc"
rastername(::Type{<:TerraClimate{Plus2C}}, filename_part; date) = "TerraClimate_2c_$(filename_part)_$(year(date)).nc"
rastername(::Type{<:TerraClimate{Plus4C}}, filename_part; date) = "TerraClimate_4c_$(filename_part)_$(year(date)).nc"

function rasterurl(T::Type{<:TerraClimate{C}}, filename_part, date) where {C}
    base_url = "http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/"
    path = _url_path(C)
    name = rastername(T, filename_part; date=date)
    uri = URI(base_url)
    return URI(string(uri, path, "/", name))
end

_category_path(::Type{Historical}) = "Historical"
_category_path(::Type{Plus2C}) = "Plus2C"
_category_path(::Type{Plus4C}) = "Plus4C"

_url_path(::Type{Historical}) = "data"
_url_path(::Type{Plus2C}) = "data_plus2C"
_url_path(::Type{Plus4C}) = "data_plus4C"

_dateformat(::Type{<:TerraClimate}) = DateFormat("yyyymmdd")
