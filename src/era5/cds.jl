@doc """
    CDS <: ERA5Source

[`ERA5`](@ref) via the Copernicus Climate Data Store (CDS) API: downloads a
regional monthly NetCDF subset rather than streaming from a global Zarr store
like [`GoogleARCO`](@ref). Requests are queued server-side, so `getraster`
submits a job and polls until done (seconds to hours). Both products:
`ERA5{CDS}` (~31 km) and `ERA5{CDS,Land}` (~9 km, land only).

Needs your CDS API token in `ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]`.
`extent` is WGS84 lon/lat; antimeridian-crossing extents are not supported.

# Usage with `getraster`
    getraster(T::Type{<:ERA5{CDS}}, [layer]; date, extent)

# Arguments
- `layer`: `Symbol` or `Tuple` of `Symbol` from `layers(T)`, e.g. `:t2m`.
    Each layer is a separate NetCDF file.

# Keywords
- `date`: a `Date`, `AbstractVector` of `Date`, or a `Tuple` of start and end dates.
    One file is downloaded per month.
- `extent`: an `Extents.Extent` bounding box, e.g. `Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))`.
    It is expanded outward to the grid: 0.25° for `SingleLevels`, 0.1° for `Land`.
- `update`: `Bool`, defaults to `false`. If `true`, re-download files even when a local
    copy already exists. Recent months are preliminary (ERA5T) and are later replaced.

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(ERA5{CDS}, (:t2m, :tp);
    date=(Date(2020,1,1), Date(2020,12,31)), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
getraster(ERA5{CDS,Land}, :t2m;
    date=Date(2020,7,1), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
```
""" CDS

const CDS_API_URL = "https://cds.climate.copernicus.eu/api/retrieve/v1"

function _cds_token()
    haskey(ENV, "RASTERDATASOURCES_ERA5_CDS_TOKEN") ||
        error("You must set `ENV[\"RASTERDATASOURCES_ERA5_CDS_TOKEN\"]` to your CDS API token")
    ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]
end

function _cds_json_request(method, url; body = nothing)
    headers = ["PRIVATE-TOKEN" => _cds_token()]
    r = if body === nothing
        HTTP.request(method, url, headers)
    else
        HTTP.request(method, url, [headers; "Content-Type" => "application/json"], JSON.json(body))
    end
    JSON.parse(String(r.body))
end

_cds_dataset_id(::Type{<:ERA5{CDS}}) = "reanalysis-era5-single-levels"
_cds_dataset_id(::Type{<:ERA5{CDS,Land}}) = "reanalysis-era5-land"

# ERA5-Land has only one product_type and omits it.
_cds_extra_inputs(::Type{<:ERA5{CDS}}) = Dict{String,Any}("product_type" => "reanalysis")
_cds_extra_inputs(::Type{<:ERA5{CDS,Land}}) = Dict{String,Any}()

# N/W/S/E.
function _cds_area(extent::Extents.Extent)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    [ymax, xmin, ymin, xmax]
end

# Builds the `{"inputs": {...}}` body for one layer and calendar month, all hours of all days.
function _cds_request_body(T::Type{<:ERA5{CDS}}, layer::Symbol, date::TimeType, extent::Extents.Extent)
    days = [lpad(d, 2, '0') for d in 1:daysinmonth(date)]
    times = [lpad(h, 2, '0') * ":00" for h in 0:23]
    inputs = Dict(
        "variable" => [layername(T, layer)],
        "year" => [Dates.format(date, "yyyy")],
        "month" => [Dates.format(date, "mm")],
        "day" => days,
        "time" => times,
        "area" => _cds_area(_cds_snap(T, extent)),
        "data_format" => "netcdf",
        "download_format" => "unarchived",
    )
    merge!(inputs, _cds_extra_inputs(T))
    Dict("inputs" => inputs)
end

function _cds_submit(T::Type{<:ERA5{CDS}}, body::Dict)
    url = "$CDS_API_URL/processes/$(_cds_dataset_id(T))/execution"
    response = _cds_json_request("POST", url; body)
    get(response, "jobID") do
        error("CDS job submission response missing \"jobID\". Response keys: $(collect(keys(response)))")
    end
end

const CDS_PENDING_STATUSES = ("accepted", "running")
const CDS_FAILED_STATUSES = ("failed", "dismissed", "rejected")

_cds_max_wait_minutes() = parse(Float64, get(ENV, "RASTERDATASOURCES_CDS_MAX_WAIT_MINUTES", "360"))

function _cds_poll(job_id::AbstractString;
    sleep_seconds = 2.0, max_sleep = 60.0, max_wait_minutes = _cds_max_wait_minutes(), report_seconds = 300.0,
)
    url = "$CDS_API_URL/jobs/$job_id"
    start = time()
    last_status, last_report = "", start
    while true
        response = _cds_json_request("GET", url)
        status = get(response, "status") do
            error("CDS job $job_id status response missing \"status\". Response keys: $(collect(keys(response)))")
        end
        status == "successful" && return nothing
        status in CDS_FAILED_STATUSES && error("CDS job $job_id ended with status \"$status\"")
        status in CDS_PENDING_STATUSES ||
            error("CDS job $job_id returned an unrecognized status \"$status\"")
        waited = (time() - start) / 60
        if status != last_status || time() - last_report >= report_seconds
            @info "CDS job $job_id: $(status == "accepted" ? "queued" : status), waited $(round(Int, waited)) min"
            last_status, last_report = status, time()
        end
        waited >= max_wait_minutes && error(
            "CDS job $job_id still \"$status\" after $(round(Int, waited)) min. " *
            "Check its status at https://cds.climate.copernicus.eu/requests; " *
            "set ENV[\"RASTERDATASOURCES_CDS_MAX_WAIT_MINUTES\"] to wait longer.")
        sleep(sleep_seconds)
        sleep_seconds = min(sleep_seconds * 1.5, max_sleep)
    end
end

function _cds_download_result(job_id::AbstractString, path; update)
    results = _cds_json_request("GET", "$CDS_API_URL/jobs/$job_id/results")
    _maybe_download(URI(results["asset"]["value"]["href"]), path; update)
end

function _validate_cds_extent(extent::Extents.Extent)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    all(isfinite, (xmin, xmax, ymin, ymax)) ||
        throw(ArgumentError("`extent` coordinates must be finite: $extent"))
    (xmin > xmax || ymin > ymax) &&
        throw(ArgumentError("`extent` has an upper bound below its lower bound: $extent"))
    (-180 <= xmin && xmax <= 180) ||
        throw(ArgumentError("`extent` longitude must lie within [-180, 180]: $extent"))
    (-90 <= ymin && ymax <= 90) ||
        throw(ArgumentError("`extent` latitude must lie within [-90, 90]: $extent"))
    extent
end

# Grid cells per degree of the regular lat/lon grid CDS serves.
_cds_cells_per_degree(::Type{<:ERA5{CDS}}) = 4
_cds_cells_per_degree(::Type{<:ERA5{CDS,Land}}) = 10

# Expand `extent` outward to the grid, so the file name matches the returned data.
function _cds_snap(T::Type{<:ERA5{CDS}}, extent::Extents.Extent)
    _validate_cds_extent(extent)
    n = _cds_cells_per_degree(T)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    Extents.Extent(X=(floor(Int, xmin * n) / n, ceil(Int, xmax * n) / n),
        Y=(floor(Int, ymin * n) / n, ceil(Int, ymax * n) / n))
end

# ERA5-Land variables shared with `ERA5_LAYERS`, plus its own `total_evaporation`.
const ERA5_LAND_LAYERS = (;
    (k => ERA5_LAYERS[k] for k in (:t2m, :d2m, :u10, :v10, :sp, :skt, :stl1, :stl2, :stl3, :stl4,
        :swvl1, :swvl2, :swvl3, :swvl4, :tp, :ssrd, :ssr, :str, :strd, :slhf, :sshf, :ro))...,
    e = "total_evaporation",
)

_cds_layers(::Type{<:ERA5{CDS}}) = ERA5_LAYERS
_cds_layers(::Type{<:ERA5{CDS,Land}}) = ERA5_LAND_LAYERS
layers(T::Type{<:ERA5{CDS}}) = keys(_cds_layers(T))
layername(T::Type{<:ERA5{CDS}}, layer::Symbol) = _cds_layers(T)[layer]

date_step(::Type{<:ERA5{CDS}}) = Month(1)
date_range(::Type{<:ERA5{CDS}}) = (Date(1940, 1, 1), Date(year(today()), 12, 31))
date_range(::Type{<:ERA5{CDS,Land}}) = (Date(1950, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:ERA5{CDS}}) = (:date, :extent)

rasterpath(::Type{<:ERA5{CDS}}) = joinpath(rasterpath(), "CDS-ERA5")
rasterpath(::Type{<:ERA5{CDS,Land}}) = joinpath(rasterpath(), "CDS-ERA5-Land")

function rastername(T::Type{<:ERA5{CDS}}, layer::Symbol; date, extent)
    e = _cds_snap(T, extent)
    "$(join((e.X..., e.Y...), "_"))_$(Dates.format(date, "yyyymm")).nc"
end
rasterpath(T::Type{<:ERA5{CDS}}, layer::Symbol; date, extent) =
    joinpath(rasterpath(T), string(layer), rastername(T, layer; date, extent))

getraster(T::Type{<:ERA5{CDS}}, layers::Union{Tuple,Symbol}; date, extent, update::Bool=false) =
    _getraster(T, layers, date, extent; update)

_getraster(T::Type{<:ERA5{CDS}}, layers, dates::Tuple{<:Any,<:Any}, extent; update) =
    _getraster(T, layers, date_sequence(T, dates), extent; update)
_getraster(T::Type{<:ERA5{CDS}}, layers, dates::AbstractArray, extent; update) =
    map(d -> _getraster(T, layers, d, extent; update), dates)
_getraster(T::Type{<:ERA5{CDS}}, layers::Tuple, date::TimeType, extent; update) =
    _map_layers(T, layers, date, extent; update)
function _getraster(T::Type{<:ERA5{CDS}}, layer::Symbol, date::TimeType, extent::Extents.Extent; update)
    _check_layer(T, layer)
    path = rasterpath(T, layer; date, extent)
    (update || !isfile(path)) || return path
    job_id = _cds_submit(T, _cds_request_body(T, layer, date, extent))
    @info "Submitted CDS job $job_id for $(_cds_dataset_id(T)) $layer $(Dates.format(date, "yyyy-mm"))"
    _cds_poll(job_id)
    _cds_download_result(job_id, path; update)
end
