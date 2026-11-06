const CDS_API_URL = "https://cds.climate.copernicus.eu/api/retrieve/v1"

function _cds_token()
    haskey(ENV, "RASTERDATASOURCES_ERA5_CDS_TOKEN") ||
        error("You must set `ENV[\"RASTERDATASOURCES_ERA5_CDS_TOKEN\"]` to your CDS API token")
    ENV["RASTERDATASOURCES_ERA5_CDS_TOKEN"]
end

_cds_headers() = ["PRIVATE-TOKEN" => _cds_token()]
_cds_get(url; kw...) = JSON.parse(String(HTTP.get(url, _cds_headers(); kw...).body))
_cds_delete(url) = HTTP.delete(url, _cds_headers(); status_exception=false)
_cds_post(url, body) =
    JSON.parse(String(HTTP.post(url, [_cds_headers(); "Content-Type" => "application/json"], JSON.json(body)).body))

_cds_dataset_id(::Type{<:ERA5{ECMWF,CDS}}) = "reanalysis-era5-single-levels"
_cds_dataset_id(::Type{<:ERA5{ECMWF,CDS,Land}}) = "reanalysis-era5-land"

_cds_variable(::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol) = get(ERA5_CDS_NAMES, layer, string(layer))
_cds_variable(::Type{<:ERA5{ECMWF,CDS,Land}}, layer::Symbol) = get(ERA5_LAND_CDS_NAMES, layer, string(layer))

# ERA5-Land has only one product_type and omits it.
_cds_extra_inputs(::Type{<:ERA5{ECMWF,CDS}}) = Dict{String,Any}("product_type" => "reanalysis")
_cds_extra_inputs(::Type{<:ERA5{ECMWF,CDS,Land}}) = Dict{String,Any}()

# N/W/S/E.
function _cds_area(extent::Extents.Extent)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    [ymax, xmin, ymin, xmax]
end

# Builds the `{"inputs": {...}}` body for one layer and calendar month, all hours of all days.
function _cds_request_body(T::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol, date::TimeType, extent::Extents.Extent)
    days = [lpad(d, 2, '0') for d in 1:daysinmonth(date)]
    times = [lpad(h, 2, '0') * ":00" for h in 0:23]
    inputs = Dict(
        "variable" => [_cds_variable(T, layer)],
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

# Submits a job, waits for it, and downloads the result to `path`.
function _cds_retrieve(T::Type{<:ERA5{ECMWF,CDS}}, layer::Symbol, date::TimeType, extent::Extents.Extent, path)
    job_id = _cds_submit(T, _cds_request_body(T, layer, date, extent))
    @info "Submitted CDS job $job_id for $(_cds_dataset_id(T)) $layer $(Dates.format(date, "yyyy-mm"))"
    try
        _cds_poll(job_id)
    catch
        # CDS keeps a job queued after Julia stops waiting for it, where it still counts towards the user's limit on queued requests
        _cds_delete("$CDS_API_URL/jobs/$job_id")
        rethrow()
    end
    results = _cds_get("$CDS_API_URL/jobs/$job_id/results")
    _maybe_download(URI(results["asset"]["value"]["href"]), path; update=true)
end

function _cds_submit(T::Type{<:ERA5{ECMWF,CDS}}, body::Dict)
    url = "$CDS_API_URL/processes/$(_cds_dataset_id(T))/execution"
    response = _cds_post(url, body)
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
        response = _cds_get(url)
        status = get(response, "status") do
            error("CDS job $job_id status response missing \"status\". Response keys: $(collect(keys(response)))")
        end
        status == "successful" && return nothing
        if status in CDS_FAILED_STATUSES
            # The results of a failed job are an error response holding the reason
            reason = get(_cds_get("$url/results"; status_exception=false), "traceback", "no reason given")
            error("CDS job $job_id ended with status \"$status\": $reason")
        end
        status in CDS_PENDING_STATUSES ||
            error("CDS job $job_id returned an unrecognized status \"$status\"")
        waited = (time() - start) / 60
        if status != last_status || time() - last_report >= report_seconds
            @info "CDS job $job_id: $(status == "accepted" ? "queued" : status), waited $(round(Int, waited)) min"
            last_status, last_report = status, time()
        end
        waited >= max_wait_minutes && error(
            "CDS job $job_id still \"$status\" after $(round(Int, waited)) min, so it is being cancelled. " *
            "Set ENV[\"RASTERDATASOURCES_CDS_MAX_WAIT_MINUTES\"] to wait longer.")
        sleep(sleep_seconds)
        sleep_seconds = min(sleep_seconds * 1.5, max_sleep)
    end
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
_cds_cells_per_degree(::Type{<:ERA5{ECMWF,CDS}}) = 4
_cds_cells_per_degree(::Type{<:ERA5{ECMWF,CDS,Land}}) = 10

# Expand `extent` outward to the grid, so the file name matches the returned data.
function _cds_snap(T::Type{<:ERA5{ECMWF,CDS}}, extent::Extents.Extent)
    _validate_cds_extent(extent)
    n = _cds_cells_per_degree(T)
    xmin, xmax = extent.X
    ymin, ymax = extent.Y
    Extents.Extent(X=(floor(Int, xmin * n) / n, ceil(Int, xmax * n) / n),
        Y=(floor(Int, ymin * n) / n, ceil(Int, ymax * n) / n))
end
