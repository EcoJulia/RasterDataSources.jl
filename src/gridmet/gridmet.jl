const GRIDMET_URI = URI(scheme="https", host="www.northwestknowledge.net", path="/metdata/data")

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
    GRIDMET <: RasterDataSource

Data from the gridMET dataset (also known as METDATA), a high-resolution (~4 km)
daily gridded surface meteorological dataset covering the contiguous United States.

See: [climatologylab.org/gridmet](https://www.climatologylab.org/gridmet.html)

Data are served as annual NetCDF files, one per variable per year. Each file
contains daily layers for the full calendar year. Coverage is from 1979 to present.

The available layers are: `$(keys(GRIDMET_LAYERS))`.

`getraster` for `GRIDMET` requires a `date` keyword to specify the year to download.

# Usage with `getraster`
    getraster(source::Type{GRIDMET}, [layer]; date)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(keys(GRIDMET_LAYERS))`.
    Without a `layer` argument all layers are downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    Only the year component is used. For multiple dates, a `Vector` of paths is returned.

# Example
```julia
julia> getraster(GRIDMET, :tmmx; date=Date(2020))
"/path/to/storage/GRIDMET/tmmx/tmmx_2020.nc"

julia> getraster(GRIDMET, (:tmmx, :pr); date=Date(2020))
(tmmx="/path/.../tmmx_2020.nc", pr="/path/.../pr_2020.nc")

julia> getraster(GRIDMET, :tmmx; date=(Date(2018), Date(2020)))
[".../tmmx_2018.nc", ".../tmmx_2019.nc", ".../tmmx_2020.nc"]
```

Returns the filepath/s of the downloaded or pre-existing files.
""" GRIDMET
struct GRIDMET <: RasterDataSource end

layers(::Type{GRIDMET}) = keys(GRIDMET_LAYERS)
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
