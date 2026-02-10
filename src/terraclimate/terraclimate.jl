
const TERRACLIMATE_URI = URI(scheme="https", host="climate.northwestknowledge.net", path="/TERRACLIMATE-DATA")
const TERRACLIMATE_FUTURE_URI = URI(scheme="https", host="thredds.northwestknowledge.net", path="/thredds/fileServer/TERRACLIMATE_ALL")

abstract type WarmingScenario end

"""
    Historical <: WarmingScenario

Historical climate data period.
"""
struct Historical <: WarmingScenario end

"""
    Plus2C <: WarmingScenario

Climate projections for a +2°C warming scenario above pre-industrial levels.
"""
struct Plus2C <: WarmingScenario end

"""
    Plus4C <: WarmingScenario

Climate projections for a +4°C warming scenario above pre-industrial levels.
"""
struct Plus4C <: WarmingScenario end

# Docs below
struct TerraClimate{S<:WarmingScenario} <: RasterDataSource end

layers(::Type{<:TerraClimate}) = (
    :aet, :def, :PDSI, :pet, :ppt, :q, :soil, :srad, :swe, :tmax, :tmin, :vap, :vpd, :ws
)

date_step(::Type{<:TerraClimate}) = Year(1)

@doc """
    TerraClimate{<:WarmingScenario} <: RasterDataSource

Data from the TerraClimate dataset, a high-resolution global dataset of monthly
climate and climatic water balance.

See: [climatologylab.org/terraclimate](https://www.climatologylab.org/terraclimate.html)

The dataset contains NetCDF files with monthly data. Each file covers one year
and contains 12 monthly layers.

The available layers are: `$(layers(TerraClimate{Historical}))`.

Available scenarios:
- `TerraClimate{Historical}` or just `TerraClimate`: Historical data (1958-2024)
- `TerraClimate{Plus2C}`: +2°C warming scenario (1985-2015)
- `TerraClimate{Plus4C}`: +4°C warming scenario (1985-2015)

`getraster` for `TerraClimate` must use a `date` keyword to specify the year to download.

# Usage with `getraster`
    getraster(source::Type{<:TerraClimate}, [layer]; date)

Download TerraClimate data for the specified scenario.

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `$(layers(TerraClimate{Historical}))`.
    Without a `layer` argument, all layers will be downloaded, and a `NamedTuple` of paths returned.

# Keywords
- `date`: a `DateTime`, `AbstractVector` of `DateTime` or a `Tuple` of start and end dates.
    For multiple dates, a `Vector` of multiple filenames will be returned.

# Example
```julia
julia> getraster(TerraClimate, :tmax; date=Date(2020))
"/path/to/storage/TerraClimate/Historical/TerraClimate_tmax_2020.nc"

julia> getraster(TerraClimate{Plus2C}, :tmax; date=Date(2000))
"/path/to/storage/TerraClimate/Plus2C/TerraClimate_2c_tmax_2000.nc"
```

Returns the filepath/s of the downloaded or pre-existing files.
""" TerraClimate

# Convenience: TerraClimate without parameters dispatches to Historical
getraster(::Type{TerraClimate}, layers::Union{Tuple,Symbol}; date) =
    getraster(TerraClimate{Historical}, layers; date)

function getraster(T::Type{<:TerraClimate}, layers::Union{Tuple,Symbol}; date)
    _getraster(T, layers, date)
end

getraster_keywords(::Type{<:TerraClimate}) = (:date,)

function _getraster(T::Type{<:TerraClimate}, layers, dates::Tuple)
    _getraster(T, layers, date_sequence(T, dates))
end
function _getraster(T::Type{<:TerraClimate}, layers, dates::AbstractArray)
    _getraster.(T, Ref(layers), dates)
end
function _getraster(T::Type{<:TerraClimate}, layers::Tuple, date::Dates.TimeType)
    _map_layers(T, layers, date)
end
function _getraster(T::Type{<:TerraClimate}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    mkpath(rasterpath(T))
    url = rasterurl(T, layer; date=date)
    path = rasterpath(T, layer; date=date)
    _maybe_download(url, path)
    path
end

# File naming
rastername(::Type{TerraClimate{Historical}}, layer; date) =
    "TerraClimate_$(layer)_$(year(date)).nc"
rastername(::Type{TerraClimate{Plus2C}}, layer; date) =
    "TerraClimate_2c_$(layer)_$(year(date)).nc"
rastername(::Type{TerraClimate{Plus4C}}, layer; date) =
    "TerraClimate_4c_$(layer)_$(year(date)).nc"

# Paths
rasterpath(::Type{TerraClimate}) = joinpath(rasterpath(), "TerraClimate")
rasterpath(::Type{TerraClimate{S}}) where S = joinpath(rasterpath(TerraClimate), string(S))
rasterpath(T::Type{<:TerraClimate}, layer; date) =
    joinpath(rasterpath(T), rastername(T, layer; date))

# URLs
rasterurl(T::Type{TerraClimate{Historical}}, layer; date) =
    joinpath(TERRACLIMATE_URI, rastername(T, layer; date))
rasterurl(T::Type{TerraClimate{Plus2C}}, layer; date) =
    joinpath(TERRACLIMATE_FUTURE_URI, "data_plus2C", rastername(T, layer; date))
rasterurl(T::Type{TerraClimate{Plus4C}}, layer; date) =
    joinpath(TERRACLIMATE_FUTURE_URI, "data_plus4C", rastername(T, layer; date))
