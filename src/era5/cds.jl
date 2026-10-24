
# CDS REST API (OGC API - Processes) client shared by ERA5CDS and
# ERA5CDSLand. Unlike other sources, a request is async: submit -> poll ->
# download a result URL, so there's no static per-file URL for `_maybe_download`.

abstract type AbstractERA5CDS <: RasterDataSource end

@doc """
    ERA5CDS <: RasterDataSource

ERA5 reanalysis via the Copernicus Climate Data Store (CDS) API: downloads a
regional monthly NetCDF subset (~31 km) rather than streaming from a global
Zarr store like [`ERA5`](@ref). Requests are queued server-side, so
`getraster` submits a job and polls until done (seconds to tens of minutes).
See [`ERA5CDSLand`](@ref) for the ~9 km land-only dataset.

Needs a CDS API key -- see `RasterDataSources._cds_credentials`.
`extent` is WGS84 lon/lat; antimeridian-crossing extents are not supported.

# Usage with `getraster`
    getraster(T::Type{ERA5CDS}, variables; date, extent)

# Arguments
- `variables`: a CDS variable name `String` (e.g. `"2m_temperature"`), or a
    `Tuple`/`Vector` of them, all downloaded into one NetCDF file. A
    `String`, not this package's usual `Symbol` layer -- see the
    [CDS ERA5 single-levels variable list](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels).

# Keywords
- `date`: a `Date`, or a `Tuple` of start/end dates covering whole months.
- `extent`: an `Extents.Extent` bounding box, e.g.
    `Extent(X=(143.0, 149.0), Y=(-44.0, -40.0))`.

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(ERA5CDS, ("2m_temperature", "total_precipitation");
    date=(Date(2020,1,1), Date(2020,12,31)), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
```
""" ERA5CDS
struct ERA5CDS <: AbstractERA5CDS end

@doc """
    ERA5CDSLand <: RasterDataSource

ERA5-Land, the land-only, higher-resolution (~9 km) companion to ERA5, via
the CDS API. See [`ERA5CDS`](@ref) for setup and usage.

# Example
```julia
using RasterDataSources, Extents, Dates
getraster(ERA5CDSLand, "2m_temperature";
    date=Date(2020,7,1), extent=Extent(X=(143.0,149.0), Y=(-44.0,-40.0)))
```
""" ERA5CDSLand
struct ERA5CDSLand <: AbstractERA5CDS end

# `_cds_credentials`/`CDS_API_URL` live in shared.jl -- also used by the
# ERA5ECMWF/ERA5ECMWFLand Zarr extension.

# OGC API - Processes endpoints (processes/jobs) live under `/retrieve/v1`.
_cds_api_base(creds) = "$(creds.url)/retrieve/v1"
_cds_headers(creds) = ["PRIVATE-TOKEN" => creds.key]

function _cds_json_request(method, url, creds; body = nothing)
    r = if body === nothing
        HTTP.request(method, url, _cds_headers(creds))
    else
        HTTP.request(method, url, [_cds_headers(creds); "Content-Type" => "application/json"], JSON.json(body))
    end
    JSON.parse(String(r.body))
end

_cds_dataset_id(::Type{ERA5CDS}) = "reanalysis-era5-single-levels"
_cds_dataset_id(::Type{ERA5CDSLand}) = "reanalysis-era5-land"

# ERA5-Land has only one product_type and omits it.
_cds_extra_inputs(::Type{ERA5CDS}) = Dict{String,Any}("product_type" => "reanalysis")
_cds_extra_inputs(::Type{ERA5CDSLand}) = Dict{String,Any}()

# N/W/S/E.
function _cds_area(extent::Extents.Extent)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    [ymax, xmin, ymin, xmax]
end

# Builds the `{"inputs": {...}}` body for one calendar month, all hours of
# all days, for all `variables` in one job.
function _cds_request_body(
    T::Type{<:AbstractERA5CDS}, variables::Tuple{Vararg{AbstractString}},
    date::Date, extent::Extents.Extent,
)
    days = [lpad(d, 2, '0') for d in 1:daysinmonth(date)]
    times = [lpad(h, 2, '0') * ":00" for h in 0:23]
    inputs = Dict(
        "variable" => collect(String, variables),
        "year" => [Dates.format(date, "yyyy")],
        "month" => [Dates.format(date, "mm")],
        "day" => days,
        "time" => times,
        "area" => _cds_area(extent),
        "data_format" => "netcdf",
        "download_format" => "unarchived",
    )
    merge!(inputs, _cds_extra_inputs(T))
    Dict("inputs" => inputs)
end

# Untyped beyond `RasterDataSource`: also used by the SEAS5 sources (seas5.jl),
# which only need their own `_cds_dataset_id` and request body.
function _cds_submit(T::Type{<:RasterDataSource}, creds, body::Dict)
    url = "$(_cds_api_base(creds))/processes/$(_cds_dataset_id(T))/execution"
    response = _cds_json_request("POST", url, creds; body)
    get(response, "jobID") do
        error("CDS job submission response missing \"jobID\". Response keys: $(collect(keys(response)))")
    end
end

const CDS_PENDING_STATUSES = ("accepted", "running")
const CDS_FAILED_STATUSES = ("failed", "dismissed", "rejected")

# Longest wait for one CDS job, in minutes; `ENV["RASTERDATASOURCES_CDS_MAX_WAIT_MINUTES"]` overrides.
_cds_max_wait_minutes() = parse(Float64, get(ENV, "RASTERDATASOURCES_CDS_MAX_WAIT_MINUTES", "360"))

# Polls for job completion; not a retry loop -- CDS requests are async and queue
# from seconds to hours. Logs status changes, and every `report_seconds` while pending.
function _cds_poll(creds, job_id::AbstractString;
    sleep_seconds = 2.0, max_sleep = 60.0, max_wait_minutes = _cds_max_wait_minutes(), report_seconds = 300.0,
)
    url = "$(_cds_api_base(creds))/jobs/$job_id"
    start = time()
    last_status, last_report = "", start
    while true
        response = _cds_json_request("GET", url, creds)
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

# `JSON.parse` returns a `JSON.Object`, an `AbstractDict` but not a `Base.Dict`.
# Tries the OGC API - Processes `asset`/`value`/`href` shape, then `location`.
function _cds_result_href(body)
    haskey(body, "location") && return body["location"]
    asset = get(body, "asset", nothing)
    if asset !== nothing
        href = get(get(asset, "value", asset), "href", nothing)
        href === nothing || return href
    end
    error("Could not find a download link in the CDS job results. Response keys: $(collect(keys(body)))")
end

# NetCDF classic magic bytes; NetCDF4 is HDF5, whose signature is 8 bytes.
const NETCDF_CLASSIC_MAGIC = UInt8[0x43, 0x44, 0x46]
const HDF5_MAGIC = UInt8[0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a]

# Guards against caching a ZIP/error document as a `.nc` result.
function _check_netcdf(path)
    magic = open(io -> read(io, 8), path)
    is_netcdf = magic == HDF5_MAGIC || (length(magic) >= 3 && magic[1:3] == NETCDF_CLASSIC_MAGIC)
    is_netcdf || error(
        "Downloaded file at $path does not look like NetCDF (magic bytes $(magic)). " *
        "CDS may have returned a ZIP archive or an error document instead of a single NetCDF file."
    )
end

function _cds_download_result(creds, job_id::AbstractString, target_path)
    body = _cds_json_request("GET", "$(_cds_api_base(creds))/jobs/$job_id/results", creds)
    href = _cds_result_href(body)
    try
        _maybe_download(URI(href), target_path)
        _check_netcdf(target_path)
    catch e
        isfile(target_path) && rm(target_path)
        rethrow(e)
    end
    target_path
end

# An antimeridian crossing (e.g. `X=(170, -170)`) always has xmin > xmax,
# so the ordering check below already rejects it.
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

# Readable rounded prefix (~11 m) plus a digest of the exact coordinates,
# so near-identical bboxes still get distinct cache entries.
function _extent_tag(extent::Extents.Extent)
    _validate_cds_extent(extent)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    prefix = replace(join(round.((xmin, xmax, ymin, ymax); digits = 4), "_"), "-" => "m", "." => "p")
    digest = string(crc32c(join((xmin, xmax, ymin, ymax), ",")); base = 16, pad = 8)
    "$(prefix)-$digest"
end

# CRC32c, not `hash`: a digest stable across Julia versions. Callers always
# pass an already-sorted tuple, so equal sets share a tag regardless of order.
_variables_tag(variables::Tuple{Vararg{AbstractString}}) =
    string(crc32c(join(variables, '\0')); base = 16, pad = 8)

# String/Symbol or a collection of them; de-duplicates and sorts so input
# order doesn't affect the cache path or CDS request.
_normalize_cds_variables(variable::Union{AbstractString,Symbol}) = _normalize_cds_variables((variable,))
function _normalize_cds_variables(variables)
    items = collect(variables)
    isempty(items) && throw(ArgumentError("at least one CDS variable must be specified"))
    result = String[]
    for v in items
        v isa Union{AbstractString,Symbol} || throw(ArgumentError(
            "CDS variable names must be `String` or `Symbol`, got a `$(typeof(v))`: $v"
        ))
        s = string(v)
        isempty(strip(s)) && throw(ArgumentError("CDS variable names must not be empty"))
        s in result || push!(result, s)
    end
    Tuple(sort(result))
end

date_step(::Type{<:AbstractERA5CDS}) = Month(1)
date_range(::Type{ERA5CDS}) = (Date(1940, 1, 1), Date(year(today()), 12, 31))
date_range(::Type{ERA5CDSLand}) = (Date(1950, 1, 1), Date(year(today()), 12, 31))
getraster_keywords(::Type{<:AbstractERA5CDS}) = (:date, :extent)

# Not the plain "ERA5" folder -- that's the unrelated `ERA5` Zarr cache (era5.jl).
rasterpath(::Type{ERA5CDS}) = joinpath(rasterpath(), "CDS-ERA5")
rasterpath(::Type{ERA5CDSLand}) = joinpath(rasterpath(), "CDS-ERA5-Land")

rastername(::Type{<:AbstractERA5CDS}, variables::Tuple{Vararg{AbstractString}}; date, extent) =
    "$(Dates.format(date, "yyyymm"))_$(length(variables))vars-$(_variables_tag(variables)).nc"

function rasterpath(
    T::Type{<:AbstractERA5CDS}, variables::Tuple{Vararg{AbstractString}}; date, extent::Extents.Extent,
)
    joinpath(rasterpath(T), _extent_tag(extent), rastername(T, variables; date, extent))
end

# Overrides the generic layers(T)-based fallback: layers(T) is undefined here
# (open-ended catalog, see docstrings above).
getraster(T::Type{<:AbstractERA5CDS}; kw...) = throw(ArgumentError(
    "variables must be specified, e.g. getraster($T, \"2m_temperature\"; date, extent)"
))
getraster(T::Type{<:AbstractERA5CDS}, variable::Union{AbstractString,Symbol}; date, extent) =
    _getraster(T, _normalize_cds_variables(variable), date, extent)
getraster(T::Type{<:AbstractERA5CDS}, variables::Tuple; date, extent) =
    _getraster(T, _normalize_cds_variables(variables), date, extent)

function _getraster(T::Type{<:AbstractERA5CDS}, variables::Tuple, dates::Tuple{<:Any,<:Any}, extent)
    _getraster(T, variables, date_sequence(T, dates), extent)
end
function _getraster(T::Type{<:AbstractERA5CDS}, variables::Tuple, dates::AbstractArray, extent)
    _getraster.(T, Ref(variables), dates, Ref(extent))
end
function _getraster(
    T::Type{<:AbstractERA5CDS}, variables::Tuple{Vararg{AbstractString}},
    date::Date, extent::Extents.Extent,
)
    path = rasterpath(T, variables; date, extent)
    _cds_retrieve(T, path, date) do
        _cds_request_body(T, variables, date, extent)
    end
end

# Submit -> poll -> download into `path`, unless a valid cached file is
# already there. `make_body` is only called when a request is needed.
function _cds_retrieve(make_body, T::Type{<:RasterDataSource}, path, date::Date)
    # Re-validate rather than trust a cached file outright: a process killed
    # mid-download can leave a partial/corrupt file behind.
    if isfile(path)
        try
            _check_netcdf(path)
            return path
        catch
            rm(path)
        end
    end
    creds = _cds_credentials()
    job_id = _cds_submit(T, creds, make_body())
    @info "Submitted CDS job $job_id for $(_cds_dataset_id(T)) $(Dates.format(date, "yyyy-mm"))"
    _cds_poll(creds, job_id)
    _cds_download_result(creds, job_id, path)
    path
end
