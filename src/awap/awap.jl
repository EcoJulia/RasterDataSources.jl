
# Types

struct AWAP <: SDMDataSource end

struct Temperature{X} end
struct VapourPressure{X} end
struct Solar{X} end
struct Rainfall{X} end

struct H09 end
struct H15 end
struct MinAve end
struct MaxAve end

const AWAP_LAYERS = (Solar, Rainfall, VapourPressure{H09}, VapourPressure{H15}, Temperature{MinAve})
const AWAP_DATEFORMAT = DateFormat("yyyymmdd")



# Interface methods

download_raster(T::Type{AWAP}, layers::Tuple; kwargs...) =
    # What to return here? A NamedTuple of Vectors of paths?
    (map(l -> download_raster(T, l; kwargs...), layers); nothing)
download_raster(::Type{AWAP}; dates, kwargs...) =
    download_raster(AWAP, AWAP_LAYERS; dates, kwargs...)
download_raster(T::Type{AWAP}, t; kwargs...) =
    download_raster(T, typeof(t); kwargs...)
function download_raster(T::Type{AWAP}, layer::Type; dates)
    dates = _date_sequence(dates, Day(1))
    mkpath(rasterpath(T, layer))
    for d in dates
        raster_path = rasterpath(T, layer, d)
        println(raster_path)
        if !isfile(raster_path)
            zip_path = zippath(T, layer, d)
            println(zip_path)
            _maybe_download(zipurl(T, layer, d), zip_path)
            run(`uncompress $zip_path -f`)
        end
    end
    # What to return here? A vector of paths?
    nothing
end

rasterpath(T::Type{AWAP}) = joinpath(rasterpath(), "AWAP")
rasterpath(T::Type{AWAP}, layer) = joinpath(rasterpath(T), _pathsegments(layer)[1:2]...)
rasterpath(T::Type{AWAP}, layer, date::Dates.AbstractTime) =
    joinpath(rasterpath(T, layer), rastername(T, layer, date))

rastername(T::Type{AWAP}, layer, date::Dates.AbstractTime) =
    joinpath(_date2string(T, date) * ".grid")

function zipurl(T::Type{AWAP}, layer, date)
    s = _pathsegments(layer)
    d = _date2string(T, date)
    # The actual zip name has the date twice, which is weird.
    # So we download in to a different name as there no output
    # name flages for `uncompress`. It's ancient.
    joinpath("http://www.bom.gov.au/web03/ncc/www/awap", s..., "grid/0.05/history/nat/$d$d.grid.Z")
end

zipname(T::Type{AWAP}, layer, date) = _date2string(T, date) * ".grid.Z"

zippath(T::Type{AWAP}, layer, date) = joinpath(rasterpath(T, layer), zipname(T, layer, date))


# Utilitiy methods

_dateformat(::Type{AWAP}) = DateFormat("yyyymmdd")

_pathsegments(::Type{<:Solar}) = "solar", "solarave", "daily"
_pathsegments(::Type{<:Rainfall}) = "rainfall", "totals", "daily"
_pathsegments(::Type{VapourPressure{H09}}) = "vprp", "vprph09", "daily"
_pathsegments(::Type{VapourPressure{H15}}) = "vprp", "vprph15", "daily"
_pathsegments(::Type{Temperature{MinAve}}) = "temperature", "minave", "daily"
_pathsegments(::Type{Temperature{MaxAve}}) = "temperature", "maxave", "daily"

#=
Add ndvi monthly?
ndvi,ndviave,month
=#

