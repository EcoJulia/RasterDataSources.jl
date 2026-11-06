@doc """
    CDS <: ERA5Store

The Copernicus Climate Data Store (CDS) API: downloads a regional monthly NetCDF
subset rather than reading remotely from an [`ARCO`](@ref) Zarr store. Requests are
queued server-side, so `getraster` submits a job and polls until done (seconds to
hours). Served by [`ECMWF`](@ref) for `ERA5{ECMWF,CDS}` and `ERA5{ECMWF,CDS,Land}`.

Needs your CDS API token in `ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]`.
`extent` is WGS84 lon/lat; antimeridian-crossing extents are not supported.

# Usage with `getraster`
    getraster(T::Type{<:ERA5{ECMWF,CDS}}, [layer]; date, extent)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `layers(T)`, listed in [`ERA5`](@ref), e.g. `:total_precipitation`.
    Each layer is a separate NetCDF file, holding the variable `layername(T, layer)`.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    One file is downloaded per month.
- `extent`: an `Extents.Extent` bounding box, e.g. `Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))`.
    It is expanded outward to the grid: 0.25° for ERA5, 0.1° for `Land`.
- `update`: `Bool`, defaults to `false`. If `true`, re-download files even when a local
    copy already exists. Recent months are preliminary (ERA5T) and are later replaced.

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(ERA5{ECMWF,CDS}, (:temperature_2m, :total_precipitation);
    date=(Date(2020,1,1), Date(2020,12,31)), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
getraster(ERA5{ECMWF,CDS,Land}, :snow_depth;
    date=Date(2020,7,1), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
```
""" CDS

layers(T::Type{<:ERA5{ECMWF,CDS}}) = keys(_era5_layers(T))

date_step(::Type{<:ERA5{ECMWF,CDS}}) = Month(1)
date_range(::Type{<:ERA5{ECMWF,CDS}}) = (Date(1940, 1, 1), Date(year(today()), 12, 31))
date_range(::Type{<:ERA5{ECMWF,CDS,Land}}) = (Date(1950, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:ERA5{ECMWF,CDS}}) = (:date, :extent, :update)

rasterpath(::Type{<:ERA5{ECMWF,CDS}}) = joinpath(rasterpath(), "ERA5", "ECMWF", "CDS")
rasterpath(::Type{<:ERA5{ECMWF,CDS,Land}}) = joinpath(rasterpath(), "ERA5", "ECMWF", "CDS", "Land")

rastername(T::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol; date, extent) = _cds_rastername(T, date, extent)
rasterpath(T::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol; date, extent) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; date, extent))

getraster(T::Type{<:ERA5{ECMWF,CDS}}, layers::Union{Tuple,Symbol}; date, extent, update::Bool=false) =
    _getraster(T, layers, date, extent; update)

_getraster(T::Type{<:ERA5{ECMWF,CDS}}, layers, dates::Tuple{<:Any,<:Any}, extent; update) =
    _getraster(T, layers, date_sequence(T, dates), extent; update)
_getraster(T::Type{<:ERA5{ECMWF,CDS}}, layers, dates::AbstractArray, extent; update) =
    map(d -> _getraster(T, layers, d, extent; update), dates)
_getraster(T::Type{<:ERA5{ECMWF,CDS}}, layers::Tuple, date::TimeType, extent; update) =
    _map_layers(T, layers, date, extent; update)
function _getraster(T::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol, date::TimeType, extent::Extents.Extent; update)
    _check_layer(T, layer)
    path = rasterpath(T, layer; date, extent)
    (update || !isfile(path)) || return path
    _cds_retrieve(T, layer, date, extent, path)
end
