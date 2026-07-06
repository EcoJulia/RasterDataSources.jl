const SILO_URI = URI(scheme="https", host="s3-ap-southeast-2.amazonaws.com", path="/silo-open-data/Official/annual")

const SILO_LAYERS = (
    daily_rain          = (description="Daily rainfall",                                                          units="mm"),
    et_morton_actual    = (description="Morton's areal actual evapotranspiration",                                units="mm"),
    et_morton_potential = (description="Morton's point potential evapotranspiration",                             units="mm"),
    et_morton_wet       = (description="Morton's wet-environment areal potential evapotranspiration over land",   units="mm"),
    et_short_crop       = (description="FAO56 short crop",                                                        units="mm"),
    et_tall_crop        = (description="ASCE tall crop",                                                         units="mm"),
    evap_morton_lake    = (description="Morton's shallow lake evaporation",                                      units="mm"),
    evap_pan            = (description="Class A pan evaporation",                                                units="mm"),
    evap_syn            = (description="Synthetic estimate",                                                     units="mm"),
    max_temp            = (description="Maximum temperature",                                                    units="°C"),
    min_temp            = (description="Minimum temperature",                                                    units="°C"),
    monthly_rain        = (description="Monthly rainfall",                                                       units="mm"),
    mslp                = (description="Mean sea level pressure",                                                units="hPa"),
    radiation           = (description="Solar exposure, consisting of both direct and diffuse components",       units="MJ/m^2"),
    rh_tmax             = (description="Relative humidity at the time of maximum temperature",                   units="%"),
    rh_tmin             = (description="Relative humidity at the time of minimum temperature",                   units="%"),
    vp                  = (description="Vapour pressure",                                                        units="hPa"),
    vp_deficit          = (description="Vapour pressure deficit",                                                units="hPa"),
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
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(keys(SILO_LAYERS))`.
    Without a `layer` argument all layers are downloaded and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    Only the year component is used. For multiple dates, a `Vector` of paths is returned.

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
    `getraster` never re-downloads an existing local file, so the current
    year's data will go stale as SILO updates it. Delete the local file to
    force a refresh.
""" SILO
struct SILO <: RasterDataSource end

layers(::Type{SILO}) = keys(SILO_LAYERS)
date_step(::Type{SILO}) = Year(1)
date_range(::Type{SILO}) = (Date(1889, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{SILO}) = (:date,)

rastername(::Type{SILO}, layer::Symbol; date) = "$(year(date)).$(layer).nc"

rasterpath(::Type{SILO}) = joinpath(rasterpath(), "SILO")
rasterpath(T::Type{SILO}, layer::Symbol; date) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; date))

rasterurl(T::Type{SILO}, layer::Symbol; date) =
    joinpath(SILO_URI, string(layer), rastername(T, layer; date))

function getraster(T::Type{SILO}, layers::Union{Tuple,Symbol}; date)
    _getraster(T, layers, date)
end

function _getraster(T::Type{SILO}, layers, dates::Tuple{<:Any,<:Any})
    _getraster(T, layers, date_sequence(T, dates))
end
function _getraster(T::Type{SILO}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{SILO}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{SILO}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    minyear = _silo_min_year(layer)
    year(date) >= minyear || throw(ArgumentError(
        "SILO layer `$layer` is only available from $minyear, got $(year(date))"
    ))
    path = rasterpath(T, layer; date)
    url  = rasterurl(T, layer; date)
    _maybe_download(url, path)
end
