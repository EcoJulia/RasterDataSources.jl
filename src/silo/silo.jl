const SILO_URI = URI(scheme="https", host="s3-ap-southeast-2.amazonaws.com", path="/silo-open-data/Official/annual")

const SILO_LAYERS = (
    :daily_rain, :et_morton_actual, :et_morton_potential, :et_morton_wet,
    :et_short_crop, :et_tall_crop, :evap_morton_lake, :evap_pan, :evap_syn,
    :max_temp, :min_temp, :monthly_rain, :mslp, :radiation,
    :rh_tmax, :rh_tmin, :vp, :vp_deficit,
)

# Some variables have shorter coverage than the general 1889-present range.
const SILO_MIN_YEAR = (mslp=1957, evap_pan=1970)
_silo_min_year(layer::Symbol) = get(SILO_MIN_YEAR, layer, 1889)

@doc """
    SILO <: RasterDataSource

Data from the SILO (Scientific Information for Land Owners) gridded climate
datasets for Australia, at approximately 5 km resolution.

See: [longpaddock.qld.gov.au/silo](https://www.longpaddock.qld.gov.au/silo/about/overview/)

Data are served as annual NetCDF files, one per variable per year, hosted on
AWS S3 under the AWS Public Data Program. Each file contains daily grids for
the full calendar year, except `monthly_rain` which contains 12 monthly grids.
Coverage is from 1889 to present for most variables, 1957 for `mslp`, and
1970 for `evap_pan`.

# Usage with `getraster`
    getraster(source::Type{SILO}, [layer]; date)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(SILO_LAYERS)`.
    Without a `layer` argument all layers are downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    Only the year component is used. For multiple dates, a `Vector` of paths is returned.
- `update`: `Bool`, defaults to `false`. If `true`, re-download files even when a local
    copy already exists. Useful for the current year, which SILO updates in place.

# Example
```julia
julia> getraster(SILO, :daily_rain; date=Date(2020))
"/path/to/storage/SILO/daily_rain/2020.daily_rain.nc"

julia> getraster(SILO, (:daily_rain, :max_temp); date=Date(2020))
(daily_rain="/path/.../2020.daily_rain.nc", max_temp="/path/.../2020.max_temp.nc")

julia> getraster(SILO, :daily_rain; date=(Date(2018), Date(2020)))
[".../2018.daily_rain.nc", ".../2019.daily_rain.nc", ".../2020.daily_rain.nc"]
```

Returns the filepath/s of the downloaded or pre-existing files.

!!! note
    By default `getraster` will not re-download an existing local file, so the
    current year's data will go stale as SILO updates it. Pass `update=true`
    to force a refresh.
""" SILO
struct SILO <: RasterDataSource end

layers(::Type{SILO}) = SILO_LAYERS
date_step(::Type{SILO}) = Year(1)
date_range(::Type{SILO}) = (Date(1889, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{SILO}) = (:date,)

rastername(::Type{SILO}, layer::Symbol; date) = "$(year(date)).$(layer).nc"

rasterpath(::Type{SILO}) = joinpath(rasterpath(), "SILO")
rasterpath(T::Type{SILO}, layer::Symbol; date) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; date))

rasterurl(T::Type{SILO}, layer::Symbol; date) =
    joinpath(SILO_URI, string(layer), rastername(T, layer; date))

function getraster(T::Type{SILO}, layers::Union{Tuple,Symbol}; date, update::Bool=false)
    _getraster(T, layers, date; update)
end

function _getraster(T::Type{SILO}, layers, dates::Tuple{<:Any,<:Any}; update::Bool=false)
    _getraster(T, layers, date_sequence(T, dates); update)
end
function _getraster(T::Type{SILO}, layers, dates::AbstractArray; update::Bool=false)
    map(d -> _getraster(T, layers, d; update), dates)
end
function _getraster(T::Type{SILO}, layers::Tuple, date::Dates.TimeType; update::Bool=false)
    _map_layers(T, layers, date; update)
end
function _getraster(T::Type{SILO}, layer::Symbol, date::Dates.TimeType; update::Bool=false)
    _check_layer(T, layer)
    minyear = _silo_min_year(layer)
    year(date) >= minyear || throw(ArgumentError(
        "SILO layer `$layer` is only available from $minyear, got $(year(date))"
    ))
    path = rasterpath(T, layer; date)
    url = rasterurl(T, layer; date)
    _maybe_download(url, path; update)
end
