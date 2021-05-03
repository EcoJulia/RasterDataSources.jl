struct AWAP <: RasterDataSource end

layers(::Type{AWAP}) = (:solar, :rainfall, :vprpress09, :vprpress15, :tmin, :tmax)

@doc """
AWAP <: RasterDataSource

Daily weather data from the Australian Water Availability Project, developed by CSIRO.

See: [www.csiro.au/awap](http://www.csiro.au/awap/)

The available layers are: `$(layers(AWAP))`.
""" AWAP

const AWAP_PATHSEGMENTS = (
    solar = ("solar", "solarave", "daily"),
    rainfall = ("rainfall", "totals", "daily"),
    vprpress09 = ("vprp", "vprph09", "daily"),
    vprpress15 = ("vprp", "vprph15", "daily"),
    tmin = ("temperature", "minave", "daily"),
    tmax = ("temperature", "maxave", "daily"),
)
# Add ndvi monthly?  ndvi, ndviave, month

"""
    getraster(source::Type{AWAP}, [layer::Union{Tuple,Symbol}]; date::Union{DateTime,Tuple,AbstractVector})
    getraster(T::Type{AWAP}, layer::Symbol, date::Union{DateTime,Tuple,AbstractVector})

Download data from the [`AWAP`](@ref) weather dataset, from
[www.csiro.au/awap](http://www.csiro.au/awap/).

# Arguments
- `layer` `Symbol` or `Tuple` of `Symbol` for `layer`s in `$(layers(AWAP))`. Without a 
    `layer` argument, all layers will be downloaded, and a tuple of paths returned.

# Keywords
- `date`: a `DateTime`, `AbstractVector` of `DateTime` or a `Tuple` of start and end dates.
    For multiple dates, multiple filenames will be returned. AWAP is available with a daily
    timestep.

# Example
Download rainfall for the first month of 2001:

```julia
julia> getraster(AWAP, :rainfall; date=Date(2001, 1, 1):Day(1):Date(2001, 1, 31))

31-element Vector{String}:
 "/your/path/AWAP/rainfall/totals/20010101.grid"
 "/your/path/AWAP/rainfall/totals/20010102.grid"
 ...
 "/your/path/AWAP/rainfall/totals/20010131.grid"
```

Returns the filepath/s of the downloaded or pre-existing files.
"""
getraster(T::Type{AWAP}, layer::Symbol; date) = getraster(T, layer, date)
function getraster(T::Type{AWAP}, layer::Symbol, dates::Tuple)
    getraster(T, layer, _date_sequence(dates, Day(1)))
end
function getraster(T::Type{AWAP}, layer::Symbol, date::Dates.TimeType)
    _check_layer(T, layer)
    mkpath(_rasterpath(T, layer))
    raster_path = rasterpath(T, layer; date=date)
    if !isfile(raster_path)
        zip_path = zippath(T, layer; date=date)
        _maybe_download(zipurl(T, layer; date=date), zip_path)
        run(`uncompress $zip_path -f`)
    end
    return raster_path
end
function getraster(T::Type{AWAP}, layer::Symbol, dates::AbstractArray)
    getraster.(T, layer, dates)
end

rasterpath(T::Type{AWAP}) = joinpath(rasterpath(), "AWAP")
rasterpath(T::Type{AWAP}, layer; date::Dates.AbstractTime) =
    joinpath(_rasterpath(T, layer), rastername(T, layer; date))
_rasterpath(T::Type{AWAP}, layer) = joinpath(rasterpath(T), AWAP_PATHSEGMENTS[layer][1:2]...)
rastername(T::Type{AWAP}, layer; date::Dates.AbstractTime) =
    joinpath(_date2string(T, date) * ".grid")

function zipurl(T::Type{AWAP}, layer; date)
    s = AWAP_PATHSEGMENTS[layer]
    d = _date2string(T, date)
    # The actual zip name has the date twice, which is weird.
    # So we getraster in to a different name as there no output
    # name flages for `uncompress`. It's ancient.
    uri = URI(scheme="http", host="www.bom.gov.au", path="/web03/ncc/www/awap")
    joinpath(uri, s..., "grid/0.05/history/nat/$d$d.grid.Z")
end
zipname(T::Type{AWAP}, layer; date) = _date2string(T, date) * ".grid.Z"
zippath(T::Type{AWAP}, layer; date) =
    joinpath(_rasterpath(T, layer), zipname(T, layer; date))


_dateformat(::Type{AWAP}) = DateFormat("yyyymmdd")
