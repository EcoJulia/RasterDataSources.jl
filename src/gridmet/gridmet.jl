const GRIDMET_URI = URI(scheme="https", host="www.northwestknowledge.net", path="/metdata/data")
const GRIDMET_ELEV_URI = URI("http://thredds.northwestknowledge.net:8080/thredds/fileServer/MET/elev/metdata_elevationdata.nc")

const GRIDMET_LAYERS = (
    tmmx = (description="Maximum near-surface air temperature",                    units="K"),
    tmmn = (description="Minimum near-surface air temperature",                    units="K"),
    pr   = (description="Precipitation accumulation",                              units="mm"),
    rmax = (description="Maximum near-surface relative humidity",                  units="%"),
    rmin = (description="Minimum near-surface relative humidity",                  units="%"),
    sph  = (description="Mean near-surface specific humidity",                     units="kg/kg"),
    srad = (description="Surface downward shortwave radiation",                    units="W m-2"),
    th   = (description="Wind direction",                                          units="Degrees clockwise from North"),
    vs   = (description="Mean near-surface wind speed",                            units="m/s"),
    etr  = (description="ASCE Penman-Montieth reference evapotranspiration",       units="mm"),
    pet  = (description="Reference evapotranspiration (Hargreaves)",               units="mm"),
    vpd  = (description="Mean vapor pressure deficit",                             units="kPa"),
    erc  = (description="NFDRS fire danger rating energy release component",       units="unitless"),
    bi   = (description="NFDRS fire danger rating burning index",                  units="unitless"),
    fm1  = (description="1-hour dead fuel moisture",                               units="%"),
    fm100= (description="100-hour dead fuel moisture",                             units="%"),
    pdsi = (description="Palmer Drought Severity Index",                           units="unitless"),
    z    = (description="Palmer Z-Index",                                          units="unitless"),
    spi  = (description="Standardized Precipitation Index",                       units="unitless"),
    spei = (description="Standardized Precipitation-Evapotranspiration Index",    units="unitless"),
    eddi = (description="Evaporative Demand Drought Index",                        units="unitless"),
)

@doc """
    GRIDMET{X} <: RasterDataSource

Data from the gridMET dataset (also known as METDATA), a high-resolution (~4 km)
daily gridded surface meteorological dataset covering the contiguous United States.

See: [climatologylab.org/gridmet](https://www.climatologylab.org/gridmet.html)

Two products are available:

**Daily meteorology** — `GRIDMET` (default):
Annual NetCDF files, one per variable per year, each containing daily layers for the
full calendar year. Coverage is from 1979 to present.

The available layers are: `$(keys(GRIDMET_LAYERS))`.

**Static elevation** — `GRIDMET{Elevation}`:
A single NetCDF file giving the ~4 km elevation grid used by gridMET. No `date` keyword.

# Usage with `getraster`
    getraster(source::Type{GRIDMET}, [layer]; date)
    getraster(source::Type{GRIDMET{Elevation}}, [layer])

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(keys(GRIDMET_LAYERS))` for `GRIDMET`,
    or `:elev` for `GRIDMET{Elevation}`. Without a `layer` argument all layers are
    downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    Only the year component is used. For multiple dates, a `Vector` of paths is returned.
    Applies only to `GRIDMET`, not `GRIDMET{Elevation}`.

# Example
```julia
julia> getraster(GRIDMET, :tmmx; date=Date(2020))
"/path/to/storage/GRIDMET/tmmx/tmmx_2020.nc"

julia> getraster(GRIDMET, (:tmmx, :pr); date=Date(2020))
(tmmx="/path/.../tmmx_2020.nc", pr="/path/.../pr_2020.nc")

julia> getraster(GRIDMET, :tmmx; date=(Date(2018), Date(2020)))
[".../tmmx_2018.nc", ".../tmmx_2019.nc", ".../tmmx_2020.nc"]

julia> getraster(GRIDMET{Elevation}, :elev)
"/path/to/storage/GRIDMET/elev/metdata_elevationdata.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
""" GRIDMET
struct GRIDMET{X} <: RasterDataSource end

# --- Daily meteorology (bare GRIDMET) --------------------------------------

layers(::Type{GRIDMET}) = keys(GRIDMET_LAYERS)

# The NetCDF variable name inside each file differs from the product code used in
# the filename/URL, so map every layer to its internal variable name (verified
# against the file headers on northwestknowledge.net). The Palmer/drought layers
# (pdsi, z, spi, spei, eddi) are intentionally absent: their annual files 404 at
# the download URL, so they can't be fetched by the per-year scheme regardless.
const GRIDMET_VARNAMES = (
    tmmx = :air_temperature,
    tmmn = :air_temperature,
    pr = :precipitation_amount,
    rmax = :relative_humidity,
    rmin = :relative_humidity,
    sph = :specific_humidity,
    srad = :surface_downwelling_shortwave_flux_in_air,
    th = :wind_from_direction,
    vs = :wind_speed,
    etr = :potential_evapotranspiration,
    pet = :potential_evapotranspiration,
    vpd = :mean_vapor_pressure_deficit,
    erc = Symbol("energy_release_component-g"),
    bi = :burning_index_g,
    fm1 = :dead_fuel_moisture_1hr,
    fm100 = :dead_fuel_moisture_100hr,
)
layerkeys(::Type{GRIDMET}, layer::Symbol) = get(GRIDMET_VARNAMES, layer, layer)

date_step(::Type{GRIDMET}) = Year(1)
date_range(::Type{GRIDMET}) = (Date(1979, 1, 1), Date(2025, 12, 31))
getraster_keywords(::Type{GRIDMET}) = (:date,)

rastername(::Type{GRIDMET}, layer::Symbol; date) = "$(layer)_$(year(date)).nc"

rasterpath(::Type{GRIDMET}) = joinpath(rasterpath(), "GRIDMET")
rasterpath(T::Type{GRIDMET}, layer::Symbol; date) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; date))

rasterurl(T::Type{GRIDMET}, layer::Symbol; date) =
    joinpath(GRIDMET_URI, rastername(T, layer; date))

function getraster(T::Type{GRIDMET}, layers::Union{Tuple,Symbol}; date)
    _getraster(T, layers, date)
end

function _getraster(T::Type{GRIDMET}, layers, dates::Tuple{<:Any,<:Any})
    _getraster(T, layers, date_sequence(T, dates))
end
function _getraster(T::Type{GRIDMET}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{GRIDMET}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{GRIDMET}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    path = rasterpath(T, layer; date)
    url  = rasterurl(T, layer; date)
    _maybe_download(url, path)
end

# --- Static elevation (GRIDMET{Elevation}) ---------------------------------

layers(::Type{GRIDMET{Elevation}}) = (:elev,)
layerkeys(::Type{GRIDMET{Elevation}}, layer::Symbol) = layer === :elev ? :elevation : layer
getraster_keywords(::Type{GRIDMET{Elevation}}) = ()

rastername(::Type{GRIDMET{Elevation}}, layer::Symbol) = "metdata_elevationdata.nc"
rasterpath(T::Type{GRIDMET{Elevation}}, layer::Symbol) =
    joinpath(rasterpath(GRIDMET), string(layer), rastername(T, layer))
rasterurl(::Type{GRIDMET{Elevation}}, layer::Symbol) = GRIDMET_ELEV_URI

getraster(T::Type{GRIDMET{Elevation}}, layers::Union{Tuple,Symbol}) =
    _getraster(T, layers)

_getraster(T::Type{GRIDMET{Elevation}}, layers::Tuple) = _map_layers(T, layers)
function _getraster(T::Type{GRIDMET{Elevation}}, layer::Symbol)
    _check_layer(T, layer)
    _maybe_download(rasterurl(T, layer), rasterpath(T, layer))
end
