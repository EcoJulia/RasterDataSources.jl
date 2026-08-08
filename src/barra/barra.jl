
abstract type BARRAProduct end
struct BARRAR2 <: BARRAProduct end
struct BARRAC2 <: BARRAProduct end

abstract type BARRADomain end
struct AUS11 <: BARRADomain end # ~11 km (BARRA-R2)
struct AUST11 <: BARRADomain end # ~11 km (BARRA-R2)
struct AUST04 <: BARRADomain end # ~4 km (BARRA-C2)

# Marker for the third (frequency) parameter, selecting the time-invariant
# "fx" layers instead of a temporal frequency.
struct Static end

_product_name(::Type{BARRAR2}) = "BARRA-R2"
_product_name(::Type{BARRAC2}) = "BARRA-C2"

_domain_name(::Type{AUS11}) = "AUS-11"
_domain_name(::Type{AUST11}) = "AUST-11"
_domain_name(::Type{AUST04}) = "AUST-04"

_valid_domains(::Type{BARRAR2}) = (AUS11, AUST11)
_valid_domains(::Type{BARRAC2}) = (AUST04,)

const BARRA_LAYERS = (
    tas = (description="Near-surface (2 m) air temperature", units="K"),
    tasmax = (description="Maximum near-surface air temperature", units="K"),
    tasmin = (description="Minimum near-surface air temperature", units="K"),
    hurs = (description="Near-surface relative humidity", units="%"),
    sfcWind = (description="Near-surface (10 m) wind speed", units="m/s"),
    uas = (description="Near-surface (10 m) eastward wind component", units="m/s"),
    vas = (description="Near-surface (10 m) northward wind component", units="m/s"),
    rsds = (description="Surface downwelling shortwave radiation", units="W/m^2"),
    rlds = (description="Surface downwelling longwave radiation", units="W/m^2"),
    ps = (description="Surface air pressure", units="Pa"),
    psl = (description="Mean sea level pressure", units="Pa"),
    pr = (description="Precipitation flux", units="kg/m^2/s"),
    clt = (description="Total cloud area fraction", units="%"),
    mrsos = (description="Surface soil moisture content", units="kg/m^2"),
    mrso = (description="Total column soil moisture content", units="kg/m^2"),
    mrsol = (description="Soil moisture content (4 depth layers)", units="kg/m^2"),
    tsl = (description="Soil temperature (4 depth layers)", units="K"),
)

const BARRA_STATIC_LAYERS = (
    orog = (description="Surface altitude", units="m"),
    sftlf = (description="Land area fraction", units="%"),
)

@doc """
    BARRA{Product<:BARRAProduct, Domain<:BARRADomain, Frequency} <: RasterDataSource

Near-surface data from BARRA2 (Bureau of Meteorology Atmospheric high-resolution
Regional Reanalysis for Australia, v2), Australia's regional analog to ERA5.

See: [BARRA2 on NCI](https://opus.nci.org.au/pages/viewpage.action?pageId=264241166)

Monthly NetCDF files (one per variable per month), from NCI's public THREDDS server.

# Type Parameters
- `Product`: `BARRAR2` (regional reanalysis) or `BARRAC2` (convection-permitting).
- `Domain`: `AUS11`/`AUST11` (`BARRAR2` only) or `AUST04` (`BARRAC2` only).
    Invalid combinations throw an `ArgumentError`.
- `Frequency`: `Hour` (default), `Day`, or `Month` for the time-varying layers
    `$(keys(BARRA_LAYERS))`; or `Static` for the time-invariant layers
    `$(keys(BARRA_STATIC_LAYERS))`.

`mrso`, `mrsol`, `tsl`, and `tasmax` (for `BARRAR2`) are unavailable at `Hour`
frequency. Pressure layers are not yet available.

# Usage with `getraster`
    getraster(source::Type{<:BARRA{Product,Domain,Frequency}}, [layer]; date)

The `date` keyword is required, except for `BARRA{Product,Domain,Static}` which
takes no `date`.

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol`s. If omitted, all layers are
    downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `Vector` of `Date`s, or `(start, end)` `Tuple`. Only year
    and month are used. Returns a `Vector` of paths for multiple dates.

# Example
```julia
julia> getraster(BARRA{BARRAC2, AUST04}, :tas; date=Date(1979, 1))
"/path/to/storage/BARRA/BARRA-C2/AUST-04/1hr/tas/tas_AUST-04_ERA5_historical_hres_BOM_BARRA-C2_v1_1hr_197901-197901.nc"

julia> getraster(BARRA{BARRAR2, AUS11, Static}, :orog)
"/path/to/storage/BARRA/BARRA-R2/AUS-11/fx/orog/orog_AUS-11_ERA5_historical_hres_BOM_BARRA-R2_v1.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
""" BARRA
struct BARRA{P<:BARRAProduct, D<:BARRADomain, F} <: RasterDataSource end

product(::Type{<:BARRA{P}}) where {P} = P
domain(::Type{<:BARRA{P,D}}) where {P,D} = D
frequency(::Type{<:BARRA{P,D,F}}) where {P,D,F} = F
frequency(::Type{BARRA{P,D}}) where {P,D} = Hour # omittable trailing param → default

_is_static(::Type{BARRA{P,D,Static}}) where {P<:BARRAProduct,D<:BARRADomain} = true
_is_static(::Type{<:BARRA}) = false

_without(nt::NamedTuple, keys_to_drop::Symbol...) =
    NamedTuple{filter(k -> !(k in keys_to_drop), keys(nt))}(nt)

# Confirmed empty on the server (not a guess): mrso/mrsol/tsl are day/mon
# only for both products; tasmax is additionally missing hourly for BARRA-R2.
function _layer_map(T::Type{<:BARRA})
    layers = BARRA_LAYERS
    if frequency(T) === Hour
        layers = _without(layers, :mrso, :mrsol, :tsl)
        product(T) === BARRAR2 && (layers = _without(layers, :tasmax))
    end
    layers
end

_check_domain(T::Type{<:BARRA}) = _check_domain(product(T), domain(T))
_check_domain(P::Type{<:BARRAProduct}, D::Type{<:BARRADomain}) =
    D in _valid_domains(P) || throw(ArgumentError(
        "BARRA domain $(_domain_name(D)) is not valid for product $(_product_name(P)); " *
        "valid domains are $(map(_domain_name, _valid_domains(P)))"
    ))

layers(T::Type{BARRA{P,D,Static}}) where {P<:BARRAProduct,D<:BARRADomain} =
    (_check_domain(T); keys(BARRA_STATIC_LAYERS))
layers(T::Type{<:BARRA}) = (_check_domain(T); keys(_layer_map(T)))

date_step(::Type{<:BARRA}) = Month(1)
date_range(::Type{<:BARRA}) = (Date(1979, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:BARRA}) = (:date,)
getraster_keywords(::Type{BARRA{P,D,Static}}) where {P<:BARRAProduct,D<:BARRADomain} = ()

_freq_token(::Type{Hour}) = "1hr"
_freq_token(::Type{Day}) = "day"
_freq_token(::Type{Month}) = "mon"

const BARRA_BASE_URI = URI(scheme="https", host="thredds.nci.org.au",
    path="/thredds/fileServer/ob53/output/reanalysis")

_layer_tag(P, D, layer) =
    "$(layer)_$(_domain_name(D))_ERA5_historical_hres_BOM_$(_product_name(P))_v1"

# Directory segment carrying the frequency ("1hr"/"day"/"mon"), or "fx" for Static.
_freq_dir(T::Type{<:BARRA}) = _is_static(T) ? "fx" : _freq_token(frequency(T))

function rastername(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D}
    _check_domain(T); _check_layer(T, layer)
    tag = _layer_tag(P, D, layer)
    _is_static(T) && return "$tag.nc"
    date === nothing && throw(ArgumentError("`date` keyword is required for BARRA layer `$layer`"))
    yyyymm = Dates.format(date, "yyyymm")
    "$(tag)_$(_freq_token(frequency(T)))_$(yyyymm)-$(yyyymm).nc"
end

rasterpath(::Type{<:BARRA}) = joinpath(rasterpath(), "BARRA")
rasterpath(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D} =
    joinpath(rasterpath(T), _product_name(P), _domain_name(D), _freq_dir(T),
        string(layer), rastername(T, layer; date))

rasterurl(T::Type{<:BARRA{P,D}}, layer::Symbol; date=nothing) where {P,D} =
    (_check_domain(T); _check_layer(T, layer);
     joinpath(BARRA_BASE_URI, _domain_name(D), "BOM", "ERA5", "historical", "hres",
        _product_name(P), "v1", _freq_dir(T), string(layer), "latest",
        rastername(T, layer; date)))

# --- Static layers (BARRA{P,D,Static}) — no date ---------------------------

getraster(T::Type{BARRA{P,D,Static}}, layers::Union{Tuple,Symbol}) where {P<:BARRAProduct,D<:BARRADomain} =
    _getraster(T, layers, nothing)

# --- Temporal layers — date required ---------------------------------------

getraster(T::Type{<:BARRA}, layers::Union{Tuple,Symbol}; date=nothing) = _getraster(T, layers, date)

_getraster(T::Type{<:BARRA}, layers, dates::Tuple{<:Any,<:Any}) =
    _getraster(T, layers, date_sequence(T, dates))
_getraster(T::Type{<:BARRA}, layers, dates::AbstractArray) =
    _getraster.(T, Ref(layers), dates)
_getraster(T::Type{<:BARRA}, layers::Tuple, date::Union{Dates.TimeType,Nothing}) =
    _map_layers(T, layers, date)
function _getraster(T::Type{<:BARRA}, layer::Symbol, date::Union{Dates.TimeType,Nothing})
    _check_domain(T); _check_layer(T, layer)
    _maybe_download(rasterurl(T, layer; date), rasterpath(T, layer; date))
end
