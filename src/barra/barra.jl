
abstract type BARRAProduct end
struct BARRAR2 <: BARRAProduct end
struct BARRAC2 <: BARRAProduct end

abstract type BARRADomain end
struct AUS11  <: BARRADomain end   # ~11 km (BARRA-R2)
struct AUST11 <: BARRADomain end   # ~11 km (BARRA-R2)
struct AUST04 <: BARRADomain end   # ~4 km  (BARRA-C2)

_product_name(::Type{BARRAR2}) = "BARRA-R2"
_product_name(::Type{BARRAC2}) = "BARRA-C2"

_domain_name(::Type{AUS11})  = "AUS-11"
_domain_name(::Type{AUST11}) = "AUST-11"
_domain_name(::Type{AUST04}) = "AUST-04"

_valid_domains(::Type{BARRAR2}) = (AUS11, AUST11)
_valid_domains(::Type{BARRAC2}) = (AUST04,)

const BARRA_SURFACE_LAYERS = (
    tas     = (description="Near-surface (2 m) air temperature",           units="K"),
    tasmax  = (description="Maximum near-surface air temperature",         units="K"),
    tasmin  = (description="Minimum near-surface air temperature",         units="K"),
    hurs    = (description="Near-surface relative humidity",               units="%"),
    sfcWind = (description="Near-surface (10 m) wind speed",               units="m/s"),
    uas     = (description="Near-surface (10 m) eastward wind component",  units="m/s"),
    vas     = (description="Near-surface (10 m) northward wind component", units="m/s"),
    rsds    = (description="Surface downwelling shortwave radiation",      units="W/m^2"),
    rlds    = (description="Surface downwelling longwave radiation",       units="W/m^2"),
    ps      = (description="Surface air pressure",                        units="Pa"),
    psl     = (description="Mean sea level pressure",                     units="Pa"),
    pr      = (description="Precipitation flux",                         units="kg/m^2/s"),
    clt     = (description="Total cloud area fraction",                  units="%"),
    mrsos   = (description="Surface soil moisture content",              units="kg/m^2"),
    mrso    = (description="Total column soil moisture content",         units="kg/m^2"),
    mrsol   = (description="Soil moisture content (4 depth layers)",     units="kg/m^2"),
    tsl     = (description="Soil temperature (4 depth layers)",          units="K"),
)

const BARRA_STATIC_LAYERS = (
    orog  = (description="Surface altitude",  units="m"),
    sftlf = (description="Land area fraction", units="%"),
)

@doc """
    BARRA{Product<:BARRAProduct, Domain<:BARRADomain, Frequency} <: RasterDataSource

Data from BARRA2 (Bureau of Meteorology Atmospheric high-resolution Regional
Reanalysis for Australia, v2), Australia's regional analog to ERA5.

See: [BARRA2 on NCI](https://opus.nci.org.au/pages/viewpage.action?pageId=264241166)

Data are served as monthly NetCDF files, one per variable per calendar month,
from NCI's public THREDDS server (no authentication required).

# Type Parameters
- `Product`: `BARRAR2` (coarser regional reanalysis) or `BARRAC2`
    (convection-permitting downscale).
- `Domain`: `AUS11`, `AUST11` (both `BARRAR2` only), or `AUST04` (`BARRAC2`
    only). An invalid `Product`/`Domain` combination throws an `ArgumentError`.
- `Frequency`: `Hour` ("1hr", the default), `Day` ("day"), or `Month` ("mon").

The available layers are: `$(keys(merge(BARRA_SURFACE_LAYERS, BARRA_STATIC_LAYERS)))`.
`orog` and `sftlf` are static (time-invariant) and never require `date`,
regardless of `Frequency`.

This is a near-surface/single-level subset of BARRA2's full output. It
excludes pressure-level variables (e.g. `hus850`, `ta500`, `zg700` — over
200 symbols across dozens of pressure levels) and severe-weather diagnostics
(e.g. `CAPE`, `MLCIN`), which are not currently supported.

Some layers are unavailable at `Hour` frequency (confirmed absent on the
server, not published at all) and are excluded from `layers(...)`/throw an
`ArgumentError` if requested at `Hour`, though they're available at `Day`
and `Month`: `mrso`, `mrsol`, and `tsl` (for both products), and
additionally `tasmax` for `BARRAR2` only.

`getraster` for `BARRA` requires a `date` keyword to specify the month to
download, except for the static layers `orog`/`sftlf`.

# Usage with `getraster`
    getraster(source::Type{<:BARRA{Product,Domain,Frequency}}, [layer]; date)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(keys(merge(BARRA_SURFACE_LAYERS, BARRA_STATIC_LAYERS)))`.
    Without a `layer` argument all layers are downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    Only the year and month components are used. For multiple dates, a
    `Vector` of paths is returned. Not required when `layer` is `:orog` or `:sftlf`.

# Example
```julia
julia> getraster(BARRA{BARRAC2, AUST04}, :tas; date=Date(1979, 1))
"/path/to/storage/BARRA/BARRA-C2/AUST-04/1hr/tas/tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_1hr_197901-197901.nc"

julia> getraster(BARRA{BARRAC2, AUST04, Day}, :tas; date=Date(1979, 1))
"/path/to/storage/BARRA/BARRA-C2/AUST-04/day/tas/tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_day_197901-197901.nc"

julia> getraster(BARRA{BARRAR2, AUS11}, :orog)
"/path/to/storage/BARRA/BARRA-R2/AUS-11/fx/orog/orog_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
""" BARRA
struct BARRA{P<:BARRAProduct, D<:BARRADomain, F} <: RasterDataSource end

product(::Type{<:BARRA{P}})       where {P}     = P
domain(::Type{<:BARRA{P,D}})      where {P,D}   = D
frequency(::Type{<:BARRA{P,D,F}}) where {P,D,F} = F
frequency(::Type{BARRA{P,D}})     where {P,D}   = Hour   # omittable trailing param → default

_without(nt::NamedTuple, keys_to_drop::Symbol...) =
    NamedTuple{filter(k -> !(k in keys_to_drop), keys(nt))}(nt)

# Confirmed empty on the server (not a guess): mrso/mrsol/tsl are day/mon
# only for both products; tasmax is additionally missing hourly for BARRA-R2.
function _layer_map(T::Type{<:BARRA})
    surface = BARRA_SURFACE_LAYERS
    if frequency(T) === Hour
        surface = _without(surface, :mrso, :mrsol, :tsl)
        product(T) === BARRAR2 && (surface = _without(surface, :tasmax))
    end
    merge(surface, BARRA_STATIC_LAYERS)
end

_check_domain(T::Type{<:BARRA}) = _check_domain(product(T), domain(T))
_check_domain(P::Type{<:BARRAProduct}, D::Type{<:BARRADomain}) =
    D in _valid_domains(P) || throw(ArgumentError(
        "BARRA domain $(_domain_name(D)) is not valid for product $(_product_name(P)); " *
        "valid domains are $(map(_domain_name, _valid_domains(P)))"
    ))

layers(T::Type{<:BARRA}) = (_check_domain(T); keys(_layer_map(T)))
date_step(::Type{<:BARRA}) = Month(1)
date_range(::Type{<:BARRA}) = (Date(1979, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:BARRA}) = (:date,)

_is_static(layer::Symbol) = layer in keys(BARRA_STATIC_LAYERS)

_freq_token(::Type{Hour})  = "1hr"
_freq_token(::Type{Day})   = "day"
_freq_token(::Type{Month}) = "mon"

const BARRA_BASE_URI = URI(scheme="https", host="thredds.nci.org.au",
    path="/thredds/fileServer/ob53/output/reanalysis")

function rastername(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D}
    _check_domain(T); _check_layer(T, layer)
    tag = "$(layer)_$(_domain_name(D))_ERA5_historical_hres_BOM_$(_product_name(P))_v1"
    if _is_static(layer)
        return "$tag.nc"
    end
    date === nothing && throw(ArgumentError("`date` keyword is required for BARRA layer `$layer`"))
    yyyymm = Dates.format(date, "yyyymm")
    "$(tag)_$(_freq_token(frequency(T)))_$(yyyymm)-$(yyyymm).nc"
end

rasterpath(::Type{<:BARRA}) = joinpath(rasterpath(), "BARRA")
function rasterpath(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D}
    freqdir = _is_static(layer) ? "fx" : _freq_token(frequency(T))
    joinpath(rasterpath(T), _product_name(P), _domain_name(D), freqdir, string(layer),
        rastername(T, layer; date))
end

function rasterurl(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D}
    _check_domain(T); _check_layer(T, layer)
    freqdir = _is_static(layer) ? "fx" : _freq_token(frequency(T))
    joinpath(BARRA_BASE_URI, _domain_name(D), "BOM", "ERA5", "historical", "hres",
        _product_name(P), "v1", freqdir, string(layer), "latest", rastername(T, layer; date))
end

function getraster(T::Type{<:BARRA}, layers::Union{Tuple,Symbol}; date=nothing)
    _getraster(T, layers, date)
end

function _getraster(T::Type{<:BARRA}, layers, dates::Tuple{<:Any,<:Any})
    _getraster(T, layers, date_sequence(T, dates))
end
function _getraster(T::Type{<:BARRA}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{<:BARRA}, layers::Tuple, date::Union{Dates.TimeType,Nothing})
    _map_layers(T, layers, date)
end
function _getraster(T::Type{<:BARRA}, layer::Symbol, date::Union{Dates.TimeType,Nothing})
    _check_domain(T); _check_layer(T, layer)
    path = rasterpath(T, layer; date)
    url  = rasterurl(T, layer; date)
    _maybe_download(url, path)
end
