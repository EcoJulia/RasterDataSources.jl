
# ECMWF SEAS5 seasonal forecasts via the CDS API. Reuses the job-queue client
# in era5/cds.jl (submit/poll/download, extent and variable handling) -- only
# the dataset ids, request bodies and cache paths differ.

abstract type AbstractSEAS5 <: RasterDataSource end

const SEAS5_SYSTEMS = ("5", "51")
const SEAS5_MONTHLY_PRODUCT_TYPES = (
    "monthly_mean", "monthly_minimum", "monthly_maximum",
    "monthly_standard_deviation", "ensemble_mean", "hindcast_climate_mean",
)

@doc """
    SEAS5 <: RasterDataSource

ECMWF SEAS5 seasonal forecasts (~1° regridded on CDS) via the Copernicus
Climate Data Store (CDS) API, as the original sub-daily ensemble output: all
ensemble members (51 for forecasts from 2017, 25 for the 1981-2016
hindcasts), out to 215 days (5160 hours) from each forecast's
initialisation on the 1st of the month. Downloads a regional NetCDF subset;
see [`SEAS5Monthly`](@ref) for monthly statistics.

Requests are queued server-side like [`ERA5CDS`](@ref), so `getraster`
submits a job and polls until done. Needs a CDS API key -- see
`RasterDataSources._cds_credentials` -- and the dataset's Terms of Use
accepted once on its CDS page.
`extent` is WGS84 lon/lat; antimeridian-crossing extents are not supported.

# Usage with `getraster`
    getraster(T::Type{SEAS5}, variables; date, extent, leadtime=24:24:5160, system="51")

# Arguments
- `variables`: a CDS variable name `String` (e.g. `"2m_temperature"`), or a
    `Tuple`/`Vector` of them, all downloaded into one NetCDF file -- see the
    [CDS variable list](https://cds.climate.copernicus.eu/datasets/seasonal-original-single-levels).

# Keywords
- `date`: a `Date` giving the initialisation month, or a `Tuple` of
    start/end dates for one file per month.
- `extent`: an `Extents.Extent` bounding box, e.g.
    `Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))`.
- `leadtime`: forecast lead times in hours, multiples of 6 from 0 to 5160.
    The default, daily steps, is valid for every variable; instantaneous
    variables such as `"2m_temperature"` are also available 6-hourly
    (`6:6:5160`), but accumulated and 24-hour max/min variables such as
    `"total_precipitation"` only at multiples of 24, and CDS rejects a
    request for lead times a variable doesn't have.
- `system`: the ECMWF system, `"51"` (SEAS5.1, 1981 onwards, the default)
    or `"5"` (the original SEAS5, until 2022).

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(SEAS5, ("2m_temperature", "total_precipitation");
    date=Date(2026, 9, 1), extent=Extent(X=(143.0, 149.0), Y=(-44.0, -40.0)))
```
""" SEAS5
struct SEAS5 <: AbstractSEAS5 end

@doc """
    SEAS5Monthly <: RasterDataSource

Monthly statistics of the ECMWF SEAS5 seasonal forecasts via the CDS API,
for lead months 1-6 after each forecast's initialisation. See [`SEAS5`](@ref)
for setup and the shared keywords.

# Usage with `getraster`
    getraster(T::Type{SEAS5Monthly}, variables; date, extent, leadtime=1:6, product_type="monthly_mean", system="51")

# Keywords
- `leadtime`: lead months, from 1 (the initialisation month) to 6.
- `product_type`: one of `$(SEAS5_MONTHLY_PRODUCT_TYPES)`. Per-member
    products (`"monthly_mean"` etc.) include every ensemble member;
    `"ensemble_mean"` and `"hindcast_climate_mean"` are single fields.
- `date`, `extent`, `system`: as for [`SEAS5`](@ref).

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(SEAS5Monthly, "2m_temperature";
    date=Date(2026, 9, 1), extent=Extent(X=(143.0, 149.0), Y=(-44.0, -40.0)),
    product_type="ensemble_mean")
```
""" SEAS5Monthly
struct SEAS5Monthly <: AbstractSEAS5 end

_cds_dataset_id(::Type{SEAS5}) = "seasonal-original-single-levels"
_cds_dataset_id(::Type{SEAS5Monthly}) = "seasonal-monthly-single-levels"

_seas5_leadtime_key(::Type{SEAS5}) = "leadtime_hour"
_seas5_leadtime_key(::Type{SEAS5Monthly}) = "leadtime_month"
_seas5_leadtimes(::Type{SEAS5}) = 0:6:5160
_seas5_leadtimes(::Type{SEAS5Monthly}) = 1:6
# Default `leadtime` keyword: daily steps for SEAS5, valid for every variable
# (see the `SEAS5` docstring). Shared with PointDataSources.jl.
_seas5_default_leadtime(::Type{SEAS5}) = 24:24:5160
_seas5_default_leadtime(::Type{SEAS5Monthly}) = 1:6

# An `Integer` or collection of them; de-duplicates and sorts so input order
# doesn't affect the cache path or CDS request.
_check_seas5_leadtime(T, leadtime::Integer) = _check_seas5_leadtime(T, (leadtime,))
function _check_seas5_leadtime(T, leadtime)
    valid = _seas5_leadtimes(T)
    items = collect(leadtime)
    isempty(items) && throw(ArgumentError("at least one `leadtime` must be specified"))
    for l in items
        l isa Integer && l in valid || throw(ArgumentError(
            "`leadtime` values for $T must be integers in $valid, got $l"
        ))
    end
    sort!(unique(Int.(items)))
end

function _check_seas5_system(system)
    s = string(system)
    s in SEAS5_SYSTEMS || throw(ArgumentError("`system` must be one of $SEAS5_SYSTEMS, got $system"))
    s
end

function _check_seas5_product_type(product_type)
    p = string(product_type)
    p in SEAS5_MONTHLY_PRODUCT_TYPES || throw(ArgumentError(
        "`product_type` must be one of $SEAS5_MONTHLY_PRODUCT_TYPES, got $product_type"
    ))
    p
end

# `options` is the validated NamedTuple of source-specific keywords.
_seas5_extra_inputs(::Type{SEAS5}, options) = Dict{String,Any}("day" => ["01"])
_seas5_extra_inputs(::Type{SEAS5Monthly}, options) =
    Dict{String,Any}("product_type" => [options.product_type])

function _cds_request_body(
    T::Type{<:AbstractSEAS5}, variables::Tuple{Vararg{AbstractString}},
    date::Date, extent::Extents.Extent, options::NamedTuple,
)
    inputs = Dict{String,Any}(
        "originating_centre" => "ecmwf",
        "system" => options.system,
        "variable" => collect(String, variables),
        "year" => [Dates.format(date, "yyyy")],
        "month" => [Dates.format(date, "mm")],
        _seas5_leadtime_key(T) => string.(options.leadtime),
        "area" => _cds_area(extent),
        "data_format" => "netcdf",
    )
    merge!(inputs, _seas5_extra_inputs(T, options))
    Dict("inputs" => inputs)
end

date_step(::Type{<:AbstractSEAS5}) = Month(1)
date_range(::Type{<:AbstractSEAS5}) = (Date(1981, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{SEAS5}) = (:date, :extent, :leadtime, :system)
getraster_keywords(::Type{SEAS5Monthly}) = (:date, :extent, :leadtime, :product_type, :system)

rasterpath(::Type{SEAS5}) = joinpath(rasterpath(), "SEAS5")
rasterpath(::Type{SEAS5Monthly}) = joinpath(rasterpath(), "SEAS5-Monthly")

# Readable first/last lead time plus a digest of the full set, so e.g.
# 6-hourly and daily requests over the same span get distinct files.
function _leadtime_tag(leadtime::AbstractVector{Int})
    digest = string(crc32c(join(leadtime, ",")); base = 16, pad = 8)
    "lt$(first(leadtime))-$(last(leadtime))-$digest"
end

_product_tag(::Nothing) = ""
_product_tag(product_type) = "_$product_type"

function rastername(
    ::Type{<:AbstractSEAS5}, variables::Tuple{Vararg{AbstractString}};
    date, extent, leadtime, system, product_type = nothing,
)
    vars = "$(length(variables))vars-$(_variables_tag(variables))"
    "$(Dates.format(date, "yyyymm"))_sys$(system)_$(vars)_$(_leadtime_tag(leadtime))$(_product_tag(product_type)).nc"
end

function rasterpath(
    T::Type{<:AbstractSEAS5}, variables::Tuple{Vararg{AbstractString}}; date, extent::Extents.Extent, options...
)
    joinpath(rasterpath(T), _extent_tag(extent), rastername(T, variables; date, extent, options...))
end

const SEAS5Variables = Union{AbstractString,Symbol,Tuple,AbstractVector}

# Overrides the generic layers(T)-based fallback: layers(T) is undefined here
# (open-ended catalog, as for ERA5CDS).
getraster(T::Type{<:AbstractSEAS5}; kw...) = throw(ArgumentError(
    "variables must be specified, e.g. getraster($T, \"2m_temperature\"; date, extent)"
))
function getraster(T::Type{SEAS5}, variables::SEAS5Variables;
    date, extent, leadtime = _seas5_default_leadtime(T), system = "51",
)
    options = (; leadtime = _check_seas5_leadtime(T, leadtime), system = _check_seas5_system(system))
    _getraster(T, _normalize_cds_variables(variables), date, extent, options)
end
function getraster(T::Type{SEAS5Monthly}, variables::SEAS5Variables;
    date, extent, leadtime = _seas5_default_leadtime(T), product_type = "monthly_mean", system = "51",
)
    options = (;
        leadtime = _check_seas5_leadtime(T, leadtime),
        product_type = _check_seas5_product_type(product_type),
        system = _check_seas5_system(system),
    )
    _getraster(T, _normalize_cds_variables(variables), date, extent, options)
end

function _getraster(T::Type{<:AbstractSEAS5}, variables::Tuple, dates::Tuple{<:Any,<:Any}, extent, options)
    _getraster(T, variables, date_sequence(T, dates), extent, options)
end
function _getraster(T::Type{<:AbstractSEAS5}, variables::Tuple, dates::AbstractArray, extent, options)
    _getraster.(T, Ref(variables), dates, Ref(extent), Ref(options))
end
function _getraster(
    T::Type{<:AbstractSEAS5}, variables::Tuple{Vararg{AbstractString}},
    date::Date, extent::Extents.Extent, options::NamedTuple,
)
    path = rasterpath(T, variables; date, extent, options...)
    _cds_retrieve(T, path, date) do
        _cds_request_body(T, variables, date, extent, options)
    end
end
